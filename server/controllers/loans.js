const Loan = require('../models/Loan');
const User = require('../models/User');
const CreditScore = require('../models/CreditScore');
const { sendOtp } = require('../utils/otpProvider');

// @desc    Create a new loan
// @route   POST /api/loans
// @access  Private (Lender)
exports.createLoan = async (req, res) => {
    try {
        const {
            borrowerPhone,
            borrowerName,
            borrowerAadhar,
            borrowerAddress,
            amount,
            interestRate,
            durationMonths,
            loanType
        } = req.body;

        // Check if borrower exists in system
        let borrower = await User.findOne({ phone: borrowerPhone });

        // Even if borrower doesn't exist, we create the loan record
        // Borrower will link to it when they register with this phone

        // Generate OTP for loan agreement (sent to borrower)
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        const loan = await Loan.create({
            lender: req.user.id,
            borrower: borrower ? borrower.id : null,
            borrowerName,
            borrowerPhone,
            borrowerAadhar,
            borrowerAddress,
            amount,
            interestRate,
            durationMonths,
            loanType,
            otp,
            status: 'pending_otp'
        });

        // Send OTP to borrower
        await sendOtp(borrowerPhone, otp);

        res.status(201).json({
            success: true,
            loan
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// @desc    Get loans given by current user
// @route   GET /api/loans/given
// @access  Private
exports.getGivenLoans = async (req, res) => {
    try {
        const loans = await Loan.find({ lender: req.user.id });
        res.status(200).json({ success: true, loans });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

// @desc    Get loans taken by current user
// @route   GET /api/loans/taken
// @access  Private
exports.getTakenLoans = async (req, res) => {
    try {
        const loans = await Loan.find({ borrowerPhone: req.user.phone });
        res.status(200).json({ success: true, loans });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

// @desc    Verify loan agreement via OTP
// @route   POST /api/loans/:id/verify
// @access  Private (Borrower)
exports.verifyLoan = async (req, res) => {
    try {
        const { otp } = req.body;
        const loan = await Loan.findById(req.params.id);

        if (!loan) {
            return res.status(404).json({ success: false, message: 'Loan not found' });
        }

        if (loan.otp !== otp) {
            return res.status(400).json({ success: false, message: 'Invalid OTP' });
        }

        loan.status = 'active';
        loan.isOtpVerified = true;
        loan.startDate = Date.now();
        loan.borrower = req.user.id; // Link the borrower ID
        await loan.save();

        res.status(200).json({ success: true, loan });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

// @desc    Update loan repayment progress
// @route   PATCH /api/loans/:id/progress
// @access  Private (Lender)
exports.updateProgress = async (req, res) => {
    try {
        const { progress } = req.body; // 0.0 to 1.0
        const loan = await Loan.findById(req.params.id);

        if (!loan) {
            return res.status(404).json({ success: false, message: 'Loan not found' });
        }

        if (loan.lender !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Only lender can update progress' });
        }

        loan.progress = progress;
        if (progress >= 1.0) {
            loan.status = 'completed';
        }
        await loan.save();

        // Update Credit Score of borrower
        if (loan.borrower) {
            await updateCreditScore(loan.borrower);
        }

        res.status(200).json({ success: true, loan });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

// Helper to update credit score
async function updateCreditScore(userId) {
    const loans = await Loan.find({ borrower: userId, status: { $in: ['active', 'completed'] } });

    if (loans.length === 0) return;

    let scorePoints = 0;
    loans.forEach(loan => {
        if (loan.status === 'completed') {
            scorePoints += 100;
        } else {
            scorePoints += (loan.progress * 50);
        }
    });

    // Simple algorithm: base 300 + points, max 900
    const newScore = Math.min(300 + Math.floor(scorePoints), 900);

    let status = 'Good';
    if (newScore < 500) status = 'Poor';
    else if (newScore < 700) status = 'Fair';
    else if (newScore < 800) status = 'Good';
    else status = 'Excellent';

    await CreditScore.findOneAndUpdate(
        { user: userId },
        {
            cibilScore: newScore,
            experianScore: newScore + 5,
            status,
            lastUpdated: Date.now()
        },
        { upsert: true }
    );
}
