with open('server/controllers/loans.js', 'r', encoding='utf-8') as f:
    content = f.read()

old_func = '''exports.getLoanById = async (req, res) => {
    try {
        const loan = await Loan.findById(req.params.id)
            .populate('lender', 'firstName lastName phone')
            .populate('borrower', 'firstName lastName phone');
        if (!loan) return res.status(404).json({ success: false, message: 'Loan not found' });
        if (loan.lender.id !== req.user.id && loan.borrower.id !== req.user.id) return res.status(403).json({ success: false, message: 'Not authorized' });
        res.status(200).json({ success: true, loan });
    } catch (err) {
        console.error('[Loans] getLoanById Error:', err.message);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};'''

new_func = '''exports.getLoanById = async (req, res) => {
    try {
        const loan = await Loan.findById(req.params.id)
            .populate('lender', 'firstName lastName phone')
            .populate('borrower', 'firstName lastName phone');
        if (!loan) return res.status(404).json({ success: false, message: 'Loan not found' });
        
        const isLender = loan.lender && (loan.lender.id === req.user.id || loan.lender === req.user.id);
        const isBorrower = (loan.borrower && (loan.borrower.id === req.user.id || loan.borrower === req.user.id)) || 
                           (loan.borrowerPhone === req.user.phone.toString().replace(/^\+?91/, ''));
                           
        if (!isLender && !isBorrower) {
            return res.status(403).json({ success: false, message: 'Not authorized to view this loan' });
        }

        res.status(200).json({ success: true, loan });
    } catch (err) {
        console.error('[Loans] getLoanById Error:', err.message);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};'''

content = content.replace(old_func, new_func)

with open('server/controllers/loans.js', 'w', encoding='utf-8') as f:
    f.write(content)
