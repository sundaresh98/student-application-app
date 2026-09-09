import os
import csv
import io
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, Response, redirect, render_template, request, session, url_for

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "development-key-change-me")
DATABASE_PATH = Path(__file__).with_name("student_applications.db")

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


def get_applications():
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        return connection.execute(
            """
            SELECT id, name, email, phone, course, application_date, status
            FROM student_applications
            ORDER BY id DESC
            """
        ).fetchall()


def admin_is_authenticated():
    return session.get("admin_authenticated") is True


init_db()


@app.route("/")
def start_application():
    session.clear()
    return redirect(url_for("application_form", step=1))


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
    return render_template("admin_applications.html", applications=get_applications())


@app.route("/admin/logout")
def admin_logout():
    session.pop("admin_authenticated", None)
    return redirect(url_for("admin_login"))


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
