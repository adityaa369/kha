import re

with open('server/controllers/loans.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("await Loan.find({ 'lender.id': userId });", "await Loan.find({ lender: userId });")

with open('server/controllers/loans.js', 'w', encoding='utf-8') as f:
    f.write(content)
