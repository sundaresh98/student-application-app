import { google } from 'googleapis';
import { OAuth2Client } from 'google-auth-library';
import { ApplicationData } from '../../types/application';

const SCOPES = ['https://www.googleapis.com/auth/spreadsheets'];
const SHEET_ID = process.env.SHEET_ID; // Your Google Sheet ID
const CLIENT_EMAIL = process.env.CLIENT_EMAIL; // Your service account email
const PRIVATE_KEY = process.env.PRIVATE_KEY?.replace(/\\n/g, '\n'); // Your service account private key

const auth = new OAuth2Client(CLIENT_EMAIL, PRIVATE_KEY, SCOPES);

export const appendDataToSheet = async (data: ApplicationData) => {
    const sheets = google.sheets({ version: 'v4', auth });
    
    const values = [
        [data.name, data.email, data.phone, data.course], // Adjust based on your ApplicationData structure
    ];

    const resource = {
        values,
    };

    try {
        await sheets.spreadsheets.values.append({
            spreadsheetId: SHEET_ID,
            range: 'Sheet1!A:D', // Adjust the range based on your sheet structure
            valueInputOption: 'RAW',
            resource,
        });
    } catch (error) {
        console.error('Error appending data to Google Sheets:', error);
        throw new Error('Failed to append data to Google Sheets');
    }
};

export const getDataFromSheet = async () => {
    const sheets = google.sheets({ version: 'v4', auth });

    try {
        const response = await sheets.spreadsheets.values.get({
            spreadsheetId: SHEET_ID,
            range: 'Sheet1!A:D', // Adjust the range based on your sheet structure
        });
        return response.data.values;
    } catch (error) {
        console.error('Error retrieving data from Google Sheets:', error);
        throw new Error('Failed to retrieve data from Google Sheets');
    }
};