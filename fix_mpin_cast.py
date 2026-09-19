with open('server/controllers/auth.js', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix setupMpin
content = content.replace("userId: req.user.id", "userId: req.user._id")

# Fix verifyMpin is already using user._id: MPinCredential.findOne({ userId: user._id })
# But let's double check

with open('server/controllers/auth.js', 'w', encoding='utf-8') as f:
    f.write(content)
