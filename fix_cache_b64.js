const fs = require('fs');
let content = fs.readFileSync('server/middleware/cache.js', 'utf-8');
content = content.replace(/const cacheKey = .*/g, 'const cacheKey = `${keyPrefix}_${userId}`;');
content = content.replace(/given_loans_.*/g, '`given_loans_${userId}`,');
content = content.replace(/taken_loans_.*/g, '`taken_loans_${userId}`');
content = content.replace(/\[rides\] Invalidated cache for user.*/g, '`[Redis] Invalidated cache for user ${userId}`);');
fs.writeFileSync('server/middleware/cache.js', content, 'utf-8');