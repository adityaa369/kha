
const fs = require('fs');
let txt = fs.readFileSync('server/controllers/loans.js', 'utf8');

const regex = /exports\.getPortfolioSummary = async \(req, res\) => \{[\s\S]*?res\.status\(200\)\.json\(\{[\s\S]*?\}\);\n    \} catch \(err\) \{/;

const replacement = \exports.getPortfolioSummary = async (req, res) => {
    try {
        const userId = req.user.id;
        const Loan = require('../models/Loan');
        
        const lentLoans = await Loan.find({ lender: userId });
        
        let lenderStats = {
            loanCount: lentLoans.length,
            activeLoanCount: 0,
            closedLoanCount: 0,
            defaultedLoanCount: 0,
            totalLentPaise: 0,
            totalCollectedPaise: 0,
            outstandingPaise: 0,
            collectionRatePct: 0,
            monthlyCollections: []
        };
        
        let monthlyMap = {};
        
        for (const loan of lentLoans) {
            if (loan.status === 'active') lenderStats.activeLoanCount++;
            if (loan.status === 'completed' || loan.status === 'closed') lenderStats.closedLoanCount++;
            if (loan.status === 'defaulted') lenderStats.defaultedLoanCount++;
            
            if (loan.status === 'active' || loan.status === 'completed' || loan.status === 'defaulted' || loan.status === 'closed') {
                const principal = loan.amountPaise || (loan.amount * 100) || 0;
                lenderStats.totalLentPaise += principal;
                
                const paid = loan.paidAmountPaise || (loan.paidAmount * 100) || 0;
                lenderStats.totalCollectedPaise += paid;
                
                let out = loan.principalOutstandingPaise;
                if (out === undefined || out === null) {
                    out = principal - paid;
                }
                lenderStats.outstandingPaise += Math.max(0, out);
                
                if (loan.transactions && loan.transactions.length > 0) {
                    loan.transactions.forEach(tx => {
                        if (tx.type === 'payment' || tx.type === 'interest_payment') {
                            const date = new Date(tx.date || tx.createdAt || new Date());
                            const monthStr = date.toLocaleString('en-US', { month: 'short' });
                            const amt = tx.amountPaise || (tx.amount * 100) || 0;
                            if (!monthlyMap[monthStr]) monthlyMap[monthStr] = 0;
                            monthlyMap[monthStr] += amt;
                        }
                    });
                }
            }
        }
        
        if (lenderStats.totalLentPaise > 0) {
            lenderStats.collectionRatePct = Math.round((lenderStats.totalCollectedPaise / lenderStats.totalLentPaise) * 100);
        }
        
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        for (const m of months) {
            lenderStats.monthlyCollections.push({ month: m, amountPaise: monthlyMap[m] || 0 });
        }
        
        const borrowedLoans = await Loan.find({ borrower: userId });
        
        let borrowerStats = {
            loanCount: borrowedLoans.length,
            activeLoanCount: 0,
            closedLoanCount: 0,
            totalBorrowedPaise: 0,
            totalRepaidPaise: 0,
            outstandingPaise: 0,
            repaymentRatePct: 0
        };
        
        for (const loan of borrowedLoans) {
            if (loan.status === 'active') borrowerStats.activeLoanCount++;
            if (loan.status === 'completed' || loan.status === 'closed') borrowerStats.closedLoanCount++;
            
            if (loan.status === 'active' || loan.status === 'completed' || loan.status === 'defaulted' || loan.status === 'closed') {
                const principal = loan.amountPaise || (loan.amount * 100) || 0;
                borrowerStats.totalBorrowedPaise += principal;
                
                const paid = loan.paidAmountPaise || (loan.paidAmount * 100) || 0;
                borrowerStats.totalRepaidPaise += paid;
                
                let out = loan.principalOutstandingPaise;
                if (out === undefined || out === null) {
                    out = principal - paid;
                }
                borrowerStats.outstandingPaise += Math.max(0, out);
            }
        }
        
        if (borrowerStats.totalBorrowedPaise > 0) {
            borrowerStats.repaymentRatePct = Math.round((borrowerStats.totalRepaidPaise / borrowerStats.totalBorrowedPaise) * 100);
        }
        
        res.status(200).json({
            success: true,
            loanCount: lenderStats.loanCount + borrowerStats.loanCount,
            activeLoanCount: lenderStats.activeLoanCount + borrowerStats.activeLoanCount,
            totalLentPaise: lenderStats.totalLentPaise,
            totalCollectedPaise: lenderStats.totalCollectedPaise,
            outstandingPaise: lenderStats.outstandingPaise + borrowerStats.outstandingPaise,
            lenderStats,
            borrowerStats
        });
    } catch (err) {
\;

txt = txt.replace(regex, replacement);
fs.writeFileSync('server/controllers/loans.js', txt);

