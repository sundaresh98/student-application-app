# Qualifier Exam Application

This is a web-based application designed to conduct qualifier exams. The application consists of a client-side built with React and a server-side built with Node.js and Express.

## Project Structure

- **src**
  - **client**
    - **components**: Reusable UI components for the client-side application.
    - **pages**: Main pages of the application, including home, exam, and results pages.
    - **app.ts**: Entry point for the client-side application, initializing the React app and setting up routing.
  - **server**
    - **controllers**: Business logic for different routes, such as user authentication and exam management.
    - **routes**: API routes for the server, mapping endpoints to their respective controllers.
    - **models**: Data models defining the structure of the data used in the application.
    - **server.ts**: Entry point for the server-side application, setting up the Express server and middleware, and connecting to the database.
  - **types**
    - **index.ts**: TypeScript interfaces and types used throughout the application.

- **tests**: Contains test files for both the client and server sides.

- **tsconfig.json**: TypeScript configuration file specifying compiler options and files to include.

- **package.json**: npm configuration file listing dependencies, scripts, and metadata.

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd qualifier-exam-app
   ```

3. Install dependencies:
   ```
   npm install
   ```

4. Start the server:
   ```
   npm run start:server
   ```

5. Start the client:
   ```
   npm run start:client
   ```

## Usage

- Access the application in your web browser at `http://localhost:3000`.
- Follow the on-screen instructions to take the qualifier exam.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.