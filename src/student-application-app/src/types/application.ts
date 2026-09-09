export interface StudentApplication {
    id: string;
    name: string;
    email: string;
    phone: string;
    course: string;
    applicationDate: Date;
    status: 'submitted' | 'reviewed' | 'accepted' | 'rejected';
}