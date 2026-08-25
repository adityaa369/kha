import os

file_path = 'lib/main_production.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'https://api.khataa.in'", "'https://khataa-backend.onrender.com'")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Reverted production URL to Render free tier")
