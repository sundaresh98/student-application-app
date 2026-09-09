# Student Application App

This folder contains the Flask student application form. It validates a student's name, email, phone number, and course, then stores completed applications in a local SQLite database.

## Project Structure

```
student-application-app
├── app.py                 # Flask application and form validation
├── requirements.txt       # Python dependencies
├── student_applications.db # SQLite database created automatically
├── templates
│   └── application_form.html
├── static
│   └── style.css
├── src
│   ├── client
│   │   ├── components      # Reusable UI components (forms, buttons, input fields)
│   │   └── pages           # Main pages (application form page)
│   ├── server
│   │   ├── routes          # API routes for handling requests
│   │   ├── controllers     # Logic for processing requests and responses
│   │   └── services
│   │       └── googleSheetsService.ts # Functions for interacting with Google Sheets API
│   └── types
│       └── application.ts  # TypeScript interfaces for application data
├── package.json            # npm configuration and dependencies
├── tsconfig.json          # TypeScript configuration
├── .env.example            # Template for environment variables
└── README.md               # Project documentation
```

## Flask Setup Instructions

1. **Open this folder:**
   ```
   cd src/student-application-app
   ```

2. **Create and activate a virtual environment:**
   ```
   python -m venv .venv
   .venv\Scripts\activate
   ```

3. **Install Flask:**
   ```
   pip install -r requirements.txt
   ```

4. **Run the form:**
   ```
   python app.py
   ```

5. Open `http://127.0.0.1:5000` in a browser.

## Public Deployment

The repository includes `render.yaml` for deployment on Render. Push the repository to GitHub, create a new Render Blueprint, and select the repository. Render will install the dependencies and start the app with Gunicorn.

The current SQLite database is suitable for local development and a temporary demo. For permanent public data storage, replace it with a hosted PostgreSQL database before collecting real student information, because free web instances may replace local files during redeploys.

## Admin Responses

Open `/admin/login` on the deployed site to view submitted applications and download a CSV file. Configure `ADMIN_USERNAME` and `ADMIN_PASSWORD` in the Render service environment before using the dashboard. These values are intentionally not stored in the repository.

## Usage Guidelines

- Navigate to the application form page to fill out the required information.
- Upon submission, the application is stored in `student_applications.db` and a confirmation is displayed.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.