const fs = require('fs');

let content = fs.readFileSync('server/controllers/loans.js', 'utf8');

content = content.replace(/sendPushNotification\(\s*(borrower|lender|user)\.fcmToken,\s*([^,]+),\s*([\s\S]+?),\s*(\{[\s\S]+?\})\s*\)/g, (match, p1, p2, p3, p4) => {
    return `Notification.create({ userId: ${p1}._id, title: ${p2}, body: ${p3}, data: ${p4} }).catch(err => console.log('Notification DB Error', err));\n            ` + match;
});

content = content.replace(/sendPushNotification\(\s*(borrower|lender|user)\.fcmToken,\s*([^,]+),\s*([^,]+?)\s*\)/g, (match, p1, p2, p3) => {
    if (match.includes("Notification.create")) return match; // avoid double replace
    return `Notification.create({ userId: ${p1}._id, title: ${p2}, body: ${p3} }).catch(err => console.log('Notification DB Error', err));\n            ` + match;
});

if(!content.includes("const Notification = require('../models/Notification');")) {
    content = "const Notification = require('../models/Notification');\n" + content;
}

fs.writeFileSync('server/controllers/loans.js', content);
console.log('Done rewriting loans.js!');
