interface User {
    id: string;
    username: string;
    email: string;
    password: string;
}

interface Exam {
    id: string;
    title: string;
    description: string;
    questions: Question[];
}

interface Question {
    id: string;
    text: string;
    options: string[];
    correctAnswer: string;
}

interface Result {
    userId: string;
    examId: string;
    score: number;
    dateTaken: Date;
}

export type { User, Exam, Question, Result };