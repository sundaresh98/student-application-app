import React from 'react';
import ReactDOM from 'react-dom';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import HomePage from './pages/HomePage';
import ExamPage from './pages/ExamPage';
import ResultsPage from './pages/ResultsPage';

const App = () => {
    return (
        <Router>
            <Switch>
                <Route path="/" exact component={HomePage} />
                <Route path="/exam" component={ExamPage} />
                <Route path="/results" component={ResultsPage} />
            </Switch>
        </Router>
    );
};

ReactDOM.render(<App />, document.getElementById('root'));