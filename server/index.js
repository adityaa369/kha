const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/db');

// Load env vars
dotenv.config();

// Connect to database
connectDB();

const app = express();

// Body parser
app.use(express.json());

// Enable CORS
app.use(cors());

// Logging
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
}

// Route files
const auth = require('./routes/auth');
const users = require('./routes/users');
const loans = require('./routes/loans');
const creditScore = require('./routes/creditScore');

// Mount routers
app.use('/api/auth', auth);
app.use('/api/users', users);
app.use('/api/loans', loans);
app.use('/api/credit-score', creditScore);

const PORT = process.env.PORT || 5000;

const server = app.listen(PORT, () => {
    console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
    console.log(`Error: ${err.message}`);
    // Close server & exit process
    server.close(() => process.exit(1));
});
