with open('server/routes/auth.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("router.get('/me', protect, authController.getMe);", "router.get('/me', protect, authController.getMe);\nrouter.get('/firebase-custom-token', protect, authController.getFirebaseCustomToken);")

with open('server/routes/auth.js', 'w', encoding='utf-8') as f:
    f.write(content)
