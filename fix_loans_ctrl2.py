import re

with open('server/controllers/loans.js', 'r', encoding='utf-8') as f:
    content = f.read()

impl = '''
// @desc    Get portfolio summary for insights
// @route   GET /api/loans/portfolio-summary
// @access  Private
exports.getPortfolioSummary = async (req, res) => {
    try {
        const userId = req.user.id;
        
        const loans = await Loan.find({ 'lender.id': userId });
        
        let loanCount = loans.length;
        let activeLoanCount = 0;
        let totalLentPaise = 0;
        let totalCollectedPaise = 0;
        let outstandingPaise = 0;
        
        for (const loan of loans) {
            if (loan.status === 'active' || loan.status === 'completed' || loan.status === 'defaulted' || loan.status === 'closed') {
                if (loan.status === 'active') {
                    activeLoanCount++;
                }
                
                const principal = loan.amountPaise || (loan.amount * 100) || 0;
                totalLentPaise += principal;
                
                const paid = loan.paidAmountPaise || (loan.paidAmount * 100) || 0;
                totalCollectedPaise += paid;
                
                let out = loan.principalOutstandingPaise;
                if (out === undefined || out === null) {
                    out = principal - paid;
                }
                outstandingPaise += Math.max(0, out);
            }
        }
        
        res.status(200).json({
            success: true,
            loanCount,
            activeLoanCount,
            totalLentPaise,
            totalCollectedPaise,
            outstandingPaise
        });
    } catch (err) {
        console.error('[Loans] getPortfolioSummary Error:', err.message);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};
'''

content = re.sub(r'// @desc    Get portfolio summary.*?};', impl, content, flags=re.DOTALL)

with open('server/controllers/loans.js', 'w', encoding='utf-8') as f:
    f.write(content)
