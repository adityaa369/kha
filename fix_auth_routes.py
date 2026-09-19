with open('server/routes/auth.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("syncFirebaseState\n} = require('../controllers/auth');", "syncFirebaseState,\n    getFirebaseCustomToken\n} = require('../controllers/auth');")
content = content.replace("router.post('/sync-firebase', protect, syncFirebaseState);", "router.post('/sync-firebase', protect, syncFirebaseState);\nrouter.get('/firebase-custom-token', protect, getFirebaseCustomToken);")

with open('server/routes/auth.js', 'w', encoding='utf-8') as f:
    f.write(content)
