const fs = require('fs');
let content = fs.readFileSync('server/controllers/loans.js', 'utf8');

const oldLogic = `        let intent = await TransactionIntent.findOne({ intentId });
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
        }`;

const newLogic = `        // Atomic upsert to prevent race conditions
        let intent = await TransactionIntent.findOneAndUpdate(
            { intentId },
            {
                $setOnInsert: {
                    intentId,
                    loanId: loan._id,
                    action: 'CLOSE_LOAN',
                    userId: req.user.id,
                    status: 'PENDING'
                }
            },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );

        if (intent.status === 'COMMITTED') {
            return res.status(200).json({ success: true, message: 'Loan successfully closed (idempotent).', loan });
        } else if (intent.status === 'REJECTED') {
            return res.status(400).json({ success: false, message: 'Transaction intent was previously rejected' });
        }`;

content = content.replace(oldLogic, newLogic);
fs.writeFileSync('server/controllers/loans.js', content);
console.log('Successfully updated closeLoan idempotency in loans.js');
