import os

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "final response = await ApiClient().get('/health/live');",
    "final response = await ApiClient().dio.get('https://khataa-backend.onrender.com/health/live');"
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed health check URL in Flutter")
