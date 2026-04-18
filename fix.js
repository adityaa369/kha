const fs = require('fs');
let data = fs.readFileSync('../khataa_backend/controllers/chitFunds.js', 'utf8');

// First replace
const old1 = "const status = (i === chit.completedMonths + 1 && chit.status === 'active') ? 'active' : 'pending';";
const new1 = "const status = (i === chit.completedMonths + 1) ? 'active' : 'pending';";
data = data.replace(old1, new1);

// Second replace regex
data = data.replace(
    /chit\.activeAuctionMonth\s*=\s*monthNumber;[\r\n\s]+chit\.activeAuctionBaseAmount\s*=\s*baseAmount;[\r\n\s]+await\s+chit\.save\(\);/,
    `chit.activeAuctionMonth = monthNumber;
        chit.activeAuctionBaseAmount = baseAmount;
        if (chit.status === 'registration') {
            chit.status = 'active';
            chit.startDate = new Date();
        }
        await chit.save();`
);

fs.writeFileSync('../khataa_backend/controllers/chitFunds.js', data);
console.log("Updated chitFunds.js successfully.");
