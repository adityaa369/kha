import os

file_path = 'lib/config/constants.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../core/config/env_config.dart';\n", "")
content = content.replace("static String get baseUrl {\n    return '${EnvConfig.apiUrl}/api';\n  }", "static const String _prodUrl = 'https://khataa-backend.onrender.com';\n  static String get baseUrl {\n    return dotenv.env['BASE_URL'] ?? '$_prodUrl/api';\n  }")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Reverted constants.dart")
