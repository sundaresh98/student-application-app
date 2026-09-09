import os
import csv
import io
import sqlite3
import uuid
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, Response, abort, redirect, render_template, request, send_file, session, url_for
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "development-key-change-me")
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024
DATABASE_PATH = Path(__file__).with_name("student_applications.db")
UPLOADS_PATH = Path(__file__).with_name("uploads")
UPLOADS_PATH.mkdir(exist_ok=True)

STEPS = {
    1: {"title": "Personal information", "fields": ["name"]},
    2: {"title": "Contact information", "fields": ["email", "phone"]},
    3: {"title": "Education details", "fields": ["course"]},
    4: {"title": "Review and submit", "fields": []},
}

FIELD_LABELS = {
    "name": "Full name",
    "email": "Email address",
    "phone": "Phone number",
    "course": "Course",
}

APPLICATION_STATUSES = ("submitted", "reviewed", "accepted", "rejected")


def init_db():
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS student_applications (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL,
                phone TEXT NOT NULL,
                course TEXT NOT NULL,
                application_date TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'submitted'
            )
            """
        )
        connection.executescript(
            """
            CREATE TABLE IF NOT EXISTS forms (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                slug TEXT NOT NULL UNIQUE,
                published INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                logo_path TEXT NOT NULL DEFAULT ''
            );
            CREATE TABLE IF NOT EXISTS form_questions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                form_id INTEGER NOT NULL,
                label TEXT NOT NULL,
                question_type TEXT NOT NULL,
                options TEXT NOT NULL DEFAULT '',
                required INTEGER NOT NULL DEFAULT 0,
                position INTEGER NOT NULL,
                FOREIGN KEY (form_id) REFERENCES forms(id)
            );
            CREATE TABLE IF NOT EXISTS form_responses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                form_id INTEGER NOT NULL,
                submitted_at TEXT NOT NULL,
                FOREIGN KEY (form_id) REFERENCES forms(id)
            );
            CREATE TABLE IF NOT EXISTS form_answers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                response_id INTEGER NOT NULL,
                question_id INTEGER NOT NULL,
                answer_text TEXT NOT NULL DEFAULT '',
                file_name TEXT NOT NULL DEFAULT '',
                file_path TEXT NOT NULL DEFAULT '',
                FOREIGN KEY (response_id) REFERENCES form_responses(id),
                FOREIGN KEY (question_id) REFERENCES form_questions(id)
            );
            """
        )
        columns = [row[1] for row in connection.execute("PRAGMA table_info(forms)").fetchall()]
        if "logo_path" not in columns:
            connection.execute("ALTER TABLE forms ADD COLUMN logo_path TEXT NOT NULL DEFAULT ''")


def save_application(form_data):
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute(
            """
            INSERT INTO student_applications
                (name, email, phone, course, application_date)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                form_data["name"],
                form_data["email"],
                form_data["phone"],
                form_data["course"],
                datetime.now(timezone.utc).isoformat(),
            ),
        )


def get_applications(search="", status=""):
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        query = """
            SELECT id, name, email, phone, course, application_date, status
            FROM student_applications
            WHERE 1 = 1
        """
        parameters = []
        if search:
            query += " AND (name LIKE ? OR email LIKE ? OR course LIKE ?)"
            search_term = f"%{search}%"
            parameters.extend([search_term, search_term, search_term])
        if status in APPLICATION_STATUSES:
            query += " AND status = ?"
            parameters.append(status)
        query += " ORDER BY id DESC"
        return connection.execute(query, parameters).fetchall()


def get_status_counts():
    with sqlite3.connect(DATABASE_PATH) as connection:
        counts = {status: 0 for status in APPLICATION_STATUSES}
        rows = connection.execute(
            "SELECT status, COUNT(*) FROM student_applications GROUP BY status"
        ).fetchall()
        for status, count in rows:
            if status in counts:
                counts[status] = count
        return counts


def update_application_status(application_id, status):
    if status not in APPLICATION_STATUSES:
        return
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute(
            "UPDATE student_applications SET status = ? WHERE id = ?",
            (status, application_id),
        )


def admin_is_authenticated():
    return session.get("admin_authenticated") is True


QUESTION_TYPES = ("short_answer", "long_answer", "single_choice", "multiple_choice", "file_upload")


def slugify(value):
    slug = "-".join(value.lower().split())
    return "".join(character for character in slug if character.isalnum() or character == "-")


def get_forms():
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        return connection.execute(
            "SELECT id, title, description, slug, published, created_at FROM forms ORDER BY id DESC"
        ).fetchall()


def get_form(form_id, published_only=False):
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        form_query = "SELECT * FROM forms WHERE id = ?"
        parameters = [form_id]
        if published_only:
            form_query += " AND published = 1"
        form = connection.execute(form_query, parameters).fetchone()
        if not form:
            return None, []
        questions = connection.execute(
            "SELECT * FROM form_questions WHERE form_id = ? ORDER BY position, id", (form_id,)
        ).fetchall()
        return form, questions


def create_form(title, description, question_data, logo_path=""):
    slug = slugify(title) or f"form-{uuid.uuid4().hex[:8]}"
    with sqlite3.connect(DATABASE_PATH) as connection:
        existing = connection.execute("SELECT 1 FROM forms WHERE slug = ?", (slug,)).fetchone()
        if existing:
            slug = f"{slug}-{uuid.uuid4().hex[:6]}"
        cursor = connection.execute(
            "INSERT INTO forms (title, description, slug, created_at, logo_path) VALUES (?, ?, ?, ?, ?)",
            (title, description, slug, datetime.now(timezone.utc).isoformat(), logo_path),
        )
        form_id = cursor.lastrowid
        for position, question in enumerate(question_data):
            connection.execute(
                """INSERT INTO form_questions
                (form_id, label, question_type, options, required, position)
                VALUES (?, ?, ?, ?, ?, ?)""",
                (form_id, question["label"], question["type"], question["options"], question["required"], position),
            )
        return form_id


def read_question_data(form_request):
    questions = []
    index = 0
    while True:
        label = form_request.form.get(f"question_label_{index}", "").strip()
        if not label:
            break
        question_type = form_request.form.get(f"question_type_{index}", "short_answer")
        options = form_request.form.get(f"question_options_{index}", "").strip()
        questions.append({
            "label": label,
            "type": question_type,
            "options": options,
            "required": 1 if form_request.form.get(f"question_required_{index}") == "1" else 0,
        })
        index += 1
    return questions


def validate_question_data(questions):
    errors = []
    for index, question in enumerate(questions):
        if question["type"] not in QUESTION_TYPES:
            errors.append(f"Question {index + 1} has an invalid response type.")
        if question["type"] in ("single_choice", "multiple_choice") and not question["options"]:
            errors.append(f"Question {index + 1} needs options separated by commas.")
    if not questions:
        errors.append("Add at least one question.")
    return errors


def replace_questions(form_id, questions):
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute("DELETE FROM form_questions WHERE form_id = ?", (form_id,))
        for position, question in enumerate(questions):
            connection.execute(
                """INSERT INTO form_questions
                (form_id, label, question_type, options, required, position)
                VALUES (?, ?, ?, ?, ?, ?)""",
                (form_id, question["label"], question["type"], question["options"], question["required"], position),
            )


init_db()


@app.route("/")
def start_application():
    session.clear()
    return redirect(url_for("application_form", step=1))


@app.route("/favicon.ico")
def favicon():
    return Response(status=204)


@app.route("/application/<int:step>", methods=["GET", "POST"])
def application_form(step):
    if step not in STEPS:
        return redirect(url_for("application_form", step=1))

    errors = []
    submitted = False
    form_data = session.get("application_data", {})

    if request.method == "POST":
        action = request.form.get("action", "next")

        if action == "back":
            return redirect(url_for("application_form", step=max(1, step - 1)))

        updated_data = form_data.copy()
        for field in STEPS[step]["fields"]:
            updated_data[field] = request.form.get(field, "").strip()

        for field in STEPS[step]["fields"]:
            if not updated_data[field]:
                errors.append(f"{FIELD_LABELS[field]} is required.")
        if step == 2 and updated_data.get("email") and "@" not in updated_data["email"]:
            errors.append("A valid email address is required.")

        if not errors:
            session["application_data"] = updated_data
            if step == 4:
                save_application(updated_data)
                submitted = True
                session.clear()
            else:
                return redirect(url_for("application_form", step=step + 1))

    return render_template(
        "application_form.html",
        errors=errors,
        submitted=submitted,
        form_data=form_data,
        current_step=step,
        total_steps=len(STEPS),
        step_title=STEPS[step]["title"],
    )


@app.route("/admin/login", methods=["GET", "POST"])
def admin_login():
    error = None
    if request.method == "POST":
        username = os.environ.get("ADMIN_USERNAME")
        password = os.environ.get("ADMIN_PASSWORD")
        if not username or not password:
            error = "Admin credentials are not configured on the server."
        elif request.form.get("username") == username and request.form.get("password") == password:
            session["admin_authenticated"] = True
            return redirect(url_for("admin_applications"))
        else:
            error = "Incorrect username or password."

    return render_template("admin_login.html", error=error)


@app.route("/admin/applications")
def admin_applications():
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))
    search = request.args.get("search", "").strip()
    status = request.args.get("status", "")
    return render_template(
        "admin_applications.html",
        applications=get_applications(search, status),
        counts=get_status_counts(),
        search=search,
        selected_status=status,
        statuses=APPLICATION_STATUSES,
    )


@app.route("/admin/applications/<int:application_id>/status", methods=["POST"])
def admin_update_status(application_id):
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))
    update_application_status(application_id, request.form.get("status", ""))
    return redirect(url_for("admin_applications"))


@app.route("/admin/logout")
def admin_logout():
    session.pop("admin_authenticated", None)
    return redirect(url_for("admin_login"))


@app.route("/admin/forms")
def admin_forms():
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))
    return render_template("admin_forms.html", forms=get_forms())


@app.route("/admin/forms/new", methods=["GET", "POST"])
def admin_new_form():
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))

    errors = []
    if request.method == "POST":
        title = request.form.get("title", "").strip()
        description = request.form.get("description", "").strip()
        logo = request.files.get("logo")
        questions = read_question_data(request)

        if not title:
            errors.append("Form title is required.")
        errors.extend(validate_question_data(questions))

        logo_path = ""
        if logo and logo.filename:
            logo_name = secure_filename(logo.filename)
            if Path(logo_name).suffix.lower() not in (".jpg", ".jpeg", ".png", ".gif", ".webp"):
                errors.append("Logo must be a JPG, PNG, GIF, or WebP image.")
            else:
                logo_directory = UPLOADS_PATH / "logos"
                logo_directory.mkdir(exist_ok=True)
                logo_path = str(logo_directory / f"{uuid.uuid4().hex}{Path(logo_name).suffix.lower()}")
                logo.save(logo_path)

        if not errors:
            form_id = create_form(title, description, questions, logo_path)
            return redirect(url_for("admin_forms"))

    return render_template("admin_form_builder.html", errors=errors, question_types=QUESTION_TYPES, form=None, questions=[])


@app.route("/admin/forms/<int:form_id>/edit", methods=["GET", "POST"])
def admin_edit_form(form_id):
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))
    form, existing_questions = get_form(form_id)
    if not form:
        abort(404)

    errors = []
    if request.method == "POST":
        title = request.form.get("title", "").strip()
        description = request.form.get("description", "").strip()
        questions = read_question_data(request)
        if not title:
            errors.append("Form title is required.")
        errors.extend(validate_question_data(questions))
        if not errors:
            with sqlite3.connect(DATABASE_PATH) as connection:
                connection.execute("UPDATE forms SET title = ?, description = ? WHERE id = ?", (title, description, form_id))
            replace_questions(form_id, questions)
            return redirect(url_for("admin_forms"))

    return render_template(
        "admin_form_builder.html",
        errors=errors,
        question_types=QUESTION_TYPES,
        form=form,
        questions=existing_questions,
    )


@app.route("/forms/<int:form_id>/logo")
def form_logo(form_id):
    form, _ = get_form(form_id, published_only=True)
    if not form or not form["logo_path"]:
        abort(404)
    logo_path = Path(form["logo_path"])
    if not logo_path.is_file() or UPLOADS_PATH not in logo_path.parents:
        abort(404)
    return Response(logo_path.read_bytes(), mimetype=f"image/{logo_path.suffix.lower().lstrip('.')}")


@app.route("/admin/forms/<int:form_id>/publish", methods=["POST"])
def admin_publish_form(form_id):
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute("UPDATE forms SET published = 1 - published WHERE id = ?", (form_id,))
    return redirect(url_for("admin_forms"))


@app.route("/admin/forms/<int:form_id>/responses")
def admin_form_responses(form_id):
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))
    form, questions = get_form(form_id)
    if not form:
        abort(404)
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        responses = connection.execute(
            "SELECT * FROM form_responses WHERE form_id = ? ORDER BY id DESC", (form_id,)
        ).fetchall()
        answers = {}
        for response in responses:
            answers[response["id"]] = connection.execute(
                "SELECT * FROM form_answers WHERE response_id = ? ORDER BY question_id", (response["id"],)
            ).fetchall()
    return render_template("admin_form_responses.html", form=form, questions=questions, responses=responses, answers=answers)


@app.route("/forms/<slug>", methods=["GET", "POST"])
def public_form(slug):
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        form = connection.execute("SELECT * FROM forms WHERE slug = ? AND published = 1", (slug,)).fetchone()
        if not form:
            abort(404)
        questions = connection.execute(
            "SELECT * FROM form_questions WHERE form_id = ? ORDER BY position, id", (form["id"],)
        ).fetchall()

        errors = []
        if request.method == "POST":
            collected = []
            upload_metadata = {}
            for question in questions:
                field_name = f"question_{question['id']}"
                upload = request.files.get(field_name)
                answer = request.form.getlist(field_name) if question["question_type"] == "multiple_choice" else request.form.get(field_name, "").strip()
                if question["required"] and not answer and not upload:
                    errors.append(f"{question['label']} is required.")
                if question["question_type"] in ("single_choice", "multiple_choice"):
                    choices = [choice.strip() for choice in question["options"].split(",") if choice.strip()]
                    values = answer if isinstance(answer, list) else [answer]
                    if any(value not in choices for value in values if value):
                        errors.append(f"Choose a valid option for {question['label']}.")
                if question["question_type"] == "file_upload" and upload and upload.filename:
                    safe_name = secure_filename(upload.filename)
                    extension = Path(safe_name).suffix.lower()
                    if extension not in (".jpg", ".jpeg", ".png", ".gif", ".pdf"):
                        errors.append(f"{question['label']} accepts only images or PDF files.")
                    else:
                        upload_metadata[question["id"]] = (safe_name, extension)
                collected.append((question, answer, upload))

            if not errors:
                response_cursor = connection.execute(
                    "INSERT INTO form_responses (form_id, submitted_at) VALUES (?, ?)",
                    (form["id"], datetime.now(timezone.utc).isoformat()),
                )
                for question, answer, upload in collected:
                    answer_text = ", ".join(answer) if isinstance(answer, list) else answer
                    file_name = ""
                    file_path = ""
                    if question["id"] in upload_metadata:
                        safe_name, extension = upload_metadata[question["id"]]
                        file_name = safe_name
                        target_directory = UPLOADS_PATH / str(form["id"])
                        target_directory.mkdir(exist_ok=True)
                        file_path = str(target_directory / f"{uuid.uuid4().hex}{extension}")
                        upload.save(file_path)
                    connection.execute(
                        """INSERT INTO form_answers
                        (response_id, question_id, answer_text, file_name, file_path)
                        VALUES (?, ?, ?, ?, ?)""",
                        (response_cursor.lastrowid, question["id"], answer_text, file_name, file_path),
                    )
                if not errors:
                    return render_template("public_form.html", form=form, questions=questions, submitted=True, errors=[])

        return render_template("public_form.html", form=form, questions=questions, submitted=False, errors=errors)


@app.route("/f/<slug>", methods=["GET", "POST"])
def short_public_form(slug):
    return public_form(slug)


@app.route("/admin/forms/<int:form_id>/responses.csv")
def admin_form_responses_csv(form_id):
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))
    form, questions = get_form(form_id)
    if not form:
        abort(404)

    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        responses = connection.execute(
            "SELECT * FROM form_responses WHERE form_id = ? ORDER BY id DESC", (form_id,)
        ).fetchall()

        output = io.StringIO()
        writer = csv.writer(output)

        def csv_value(value):
            value = str(value or "")
            if value.startswith(("=", "+", "-", "@")):
                return "'" + value
            return value

        writer.writerow(["Response ID", "Submitted"] + [question["label"] for question in questions])
        for response in responses:
            answer_rows = connection.execute(
                "SELECT question_id, answer_text, file_name FROM form_answers WHERE response_id = ?",
                (response["id"],),
            ).fetchall()
            answer_map = {
                answer["question_id"]: answer["file_name"] or answer["answer_text"]
                for answer in answer_rows
            }
            writer.writerow(
                [response["id"], response["submitted_at"]]
                + [csv_value(answer_map.get(question["id"], "")) for question in questions]
            )

    filename = f"{form['slug']}-responses.csv"
    return Response(
        output.getvalue(),
        mimetype="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@app.route("/admin/form-files/<int:answer_id>")
def admin_form_file(answer_id):
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        answer = connection.execute(
            "SELECT file_name, file_path FROM form_answers WHERE id = ? AND file_path != ''",
            (answer_id,),
        ).fetchone()
    if not answer:
        abort(404)
    file_path = Path(answer["file_path"])
    if not file_path.is_file() or UPLOADS_PATH not in file_path.parents:
        abort(404)
    return send_file(file_path, as_attachment=True, download_name=answer["file_name"])


@app.route("/admin/applications.csv")
def admin_applications_csv():
    if not admin_is_authenticated():
        return redirect(url_for("admin_login"))

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "Name", "Email", "Phone", "Course", "Application date", "Status"])
    for application in get_applications():
        writer.writerow(tuple(application))

    return Response(
        output.getvalue(),
        mimetype="text/csv",
        headers={"Content-Disposition": "attachment; filename=student-applications.csv"},
    )


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 5000)),
        debug=os.environ.get("FLASK_DEBUG", "0") == "1",
    )
