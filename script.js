
const fs = require('fs');
let txt = fs.readFileSync('server/controllers/loans.js', 'utf8');
let rep = fs.readFileSync('replacement.txt', 'utf8');

const regex = /exports\.getPortfolioSummary = async \(req, res\) => \{[\s\S]*?res\.status\(200\)\.json\(\{[\s\S]*?\}\);\n    \} catch \(err\) \{/;

txt = txt.replace(regex, rep);
fs.writeFileSync('server/controllers/loans.js', txt);

