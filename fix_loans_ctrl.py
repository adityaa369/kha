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
        
        const loans = await Loan.find({ lender: userId });
        
        let loanCount = loans.length;
        let activeLoanCount = 0;
        let totalLentPaise = 0;
        let totalCollectedPaise = 0;
        let outstandingPaise = 0;
        
        for (const loan of loans) {
            if (loan.status === 'active' || loan.status === 'completed' || loan.status === 'defaulted') {
                if (loan.status === 'active') {
                    activeLoanCount++;
                }
                
                const principal = loan.principalAmount || 0;
                totalLentPaise += principal;
                
                // Estimate collected
                const paid = Math.floor(principal * loan.progress);
                totalCollectedPaise += paid;
                outstandingPaise += (principal - paid);
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

content = content + "\n" + impl

with open('server/controllers/loans.js', 'w', encoding='utf-8') as f:
    f.write(content)
