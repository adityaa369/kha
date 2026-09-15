const fs = require('fs');
let content = fs.readFileSync('server/controllers/loans.js', 'utf8');

const replacement = `// @desc    Close loan
// @route   POST /api/loans/:id/close
// @access  Private (Lender)
exports.closeLoan = async (req, res) => {
    try {
        const { intentId } = req.body;
        const Loan = require('../models/Loan');
        const TransactionIntent = require('../models/TransactionIntent');
        const FinancialLedgerService = require('../services/FinancialLedgerService');
        const { cacheInvalidate } = require('../middleware/cache');
        const { invalidateLoanCache } = require('../utils/cacheUtils');

        const loan = await Loan.findById(req.params.id);
        if (!loan) return res.status(404).json({ success: false, message: 'Loan not found' });
        if (loan.lender !== req.user.id) return res.status(403).json({ success: false, message: 'Only lender can close this loan' });
        if (loan.status === 'closed') return res.status(200).json({ success: true, message: 'Loan is already closed', loan });

        if (!intentId) return res.status(400).json({ success: false, message: 'intentId is required' });

        let intent = await TransactionIntent.findOne({ intentId });
        if (!intent) {
            intent = await TransactionIntent.create({
                intentId,
                loanId: loan._id,
                action: 'CLOSE_LOAN',
                userId: req.user.id
            });
        } else if (intent.status === 'COMMITTED') {
            return res.status(200).json({ success: true, message: 'Loan successfully closed.', loan });
        } else if (intent.status === 'REJECTED') {
            return res.status(400).json({ success: false, message: 'Transaction intent was previously rejected' });
        }

        try {
            await FinancialLedgerService.closeLoan(loan, new Date());
        } catch (e) {
            intent.status = 'REJECTED';
            await intent.save();
            return res.status(400).json({ success: false, message: e.message });
        }

        loan.status = 'closed';
        loan.progress = 1.0;
        await loan.save();

        intent.status = 'COMMITTED';
        await intent.save();

        await invalidateLoanCache(loan.lender, loan.borrower);
        await cacheInvalidate(\`loans:given:\${loan.lender}\`, \`loans:taken:\${loan.borrower}\`);

        res.status(200).json({ success: true, message: 'Loan successfully closed.', loan });
    } catch (err) {
        console.error('[Loans] closeLoan Error:', err.message);
        const { sendError } = require('../utils/response');
        sendError(res, err);
    }
};

`;

const startIdx = content.indexOf('// @desc    Close loan & Generate Certificate');
const endMarker = '// @desc    Upload document';
const endIdx = content.indexOf(endMarker);

if (startIdx !== -1 && endIdx !== -1) {
    const newContent = content.substring(0, startIdx) + replacement + content.substring(endIdx);
    fs.writeFileSync('server/controllers/loans.js', newContent);
    console.log('Successfully replaced');
} else {
    console.log('Could not find markers', startIdx, endIdx);
}
