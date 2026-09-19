with open('server/routes/loans.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("recordInterest\n} = require('../controllers/loans');", "recordInterest,\n    getPortfolioSummary\n} = require('../controllers/loans');")

with open('server/routes/loans.js', 'w', encoding='utf-8') as f:
    f.write(content)
