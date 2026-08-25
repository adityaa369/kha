import os

file_path = 'lib/config/constants.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

import_statement = "import '../core/config/env_config.dart';\n"
if "env_config.dart" not in content:
    content = import_statement + content

content = content.replace("static const String _prodUrl = 'https://api.khataa.in'; // F.7: Bound to Render via CNAME", "")
content = content.replace("static String get baseUrl {\n    return dotenv.env['BASE_URL'] ?? '$_prodUrl/api';\n  }", "static String get baseUrl {\n    return '${EnvConfig.apiUrl}/api';\n  }")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated constants.dart to use EnvConfig")
