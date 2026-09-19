with open('server/models/Notification.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("type: mongoose.Schema.Types.ObjectId,", "type: String,")

with open('server/models/Notification.js', 'w', encoding='utf-8') as f:
    f.write(content)
