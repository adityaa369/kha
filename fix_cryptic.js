const fs = require('fs');
let txt = fs.readFileSync('lib/features/loans/presentation/pages/create_loan_page.dart', 'utf8');

txt = txt.replace(/Text\('Principal:.*?\$\{amount/g, "Text('Principal: ₹${amount");
txt = txt.replace(/Text\('Total Interest:.*?\$\{totalInterest/g, "Text('Total Interest: ₹${totalInterest");
txt = txt.replace(/Text\('Total Repayment:.*?\$\{amount/g, "Text('Total Repayment: ₹${amount");
txt = txt.replace(/Text\('Total Repayment:.*?\$\{totalRepayment/g, "Text('Total Repayment: ₹${totalRepayment");

fs.writeFileSync('lib/features/loans/presentation/pages/create_loan_page.dart', txt);