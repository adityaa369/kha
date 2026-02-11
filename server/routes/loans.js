const express = require('express');
const {
    createLoan,
    getGivenLoans,
    getTakenLoans,
    verifyLoan,
    updateProgress
} = require('../controllers/loans');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.use(protect); // All loan routes are protected

router.post('/', createLoan);
router.get('/given', getGivenLoans);
router.get('/taken', getTakenLoans);
router.post('/:id/verify', verifyLoan);
router.patch('/:id/progress', updateProgress);

module.exports = router;
