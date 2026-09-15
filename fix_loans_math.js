const fs = require('fs');
let content = fs.readFileSync('server/controllers/loans.js', 'utf8');

// Import parseRupeesToPaise at the top
if (!content.includes("parseRupeesToPaise")) {
    content = content.replace("const Loan = require('../models/Loan');", "const Loan = require('../models/Loan');\nconst { parseRupeesToPaise } = require('../utils/money');");
}

content = content.replace("amountPaise: Math.round(Number(amount) * 100),", "amountPaise: parseRupeesToPaise(amount),");
content = content.replace("await FinancialLedgerService.activateLoan(loan, Math.round(Number(loan.amount) * 100), req.user.id, loan.activatedAt);", "await FinancialLedgerService.activateLoan(loan, parseRupeesToPaise(loan.amount), req.user.id, loan.activatedAt);");

fs.writeFileSync('server/controllers/loans.js', content);
console.log('Successfully updated server/controllers/loans.js');
