const express = require('express');
const CreditScore = require('../models/CreditScore');
const { protect } = require('../middleware/auth');

const router = express.Router();

// @desc    Get current user credit score
// @route   GET /api/credit-score
// @access  Private
router.get('/', protect, async (req, res) => {
    try {
        let score = await CreditScore.findOne({ user: req.user.id });

        if (!score) {
            score = await CreditScore.create({ user: req.user.id });
        }

        res.status(200).json({
            success: true,
            score
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
});

module.exports = router;
