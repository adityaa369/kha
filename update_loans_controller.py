import os

path = 'server/controllers/loans.js'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

target = """        const loans = await Loan.find({ lender: req.user.id });
        const loansMapped = [];
        for (const loan of loans) {
            loansMapped.push(loan.toObject ? loan.toObject() : loan);
        }"""

replacement = """        const loans = await Loan.find({ lender: req.user.id });
        const loansMapped = [];
        const User = require('../models/User'); // Import User model
        for (const loan of loans) {
            const loanObj = loan.toObject ? loan.toObject() : loan;
            
            // Dynamically fetch borrower name if registered
            if (loanObj.borrower) {
                const borrowerUser = await User.findOne({ id: loanObj.borrower });
                if (borrowerUser) {
                    const realName = f"{borrowerUser.firstName || ''} {borrowerUser.lastName || ''}".trim();
                    if (realName) {
                        loanObj.borrowerName = realName;
                    }
                }
            }
            
            loansMapped.push(loanObj);
        }"""
# Fix the JS string interpolation template literal in Python string:
replacement = replacement.replace('f"{borrowerUser.firstName || \'\'} {borrowerUser.lastName || \'\'}"', '`${borrowerUser.firstName || \'\'} ${borrowerUser.lastName || \'\'}`')


c = c.replace(target, replacement)
with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print("Updated successfully!")
