import os

file_path = 'lib/config/constants.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "static const String _prodUrl = 'https://khataa-backend.onrender.com';",
    "static const String _prodUrl = 'https://api.khataa.in'; // F.7: Bound to Render via CNAME"
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated _prodUrl in Flutter AppConstants")
