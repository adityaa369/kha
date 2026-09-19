with open('server/routes/auth.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("router.get('/firebase-custom-token', protect, authController.getFirebaseCustomToken);", "router.get('/firebase-custom-token', protect, authController.getFirebaseCustomToken);\nrouter.post('/sync-firebase', protect, authController.syncFirebaseState);")

with open('server/routes/auth.js', 'w', encoding='utf-8') as f:
    f.write(content)
