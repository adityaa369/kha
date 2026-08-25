import os

file_path = 'lib/features/chit_funds/presentation/pages/chit_live_auction_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

import_stmt = "import '../../../../core/config/env_config.dart';\n"
if "env_config.dart" not in content:
    content = import_stmt + content

content = content.replace("'https://khataa-backend.onrender.com'", "EnvConfig.apiUrl")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Removed hardcoded URL from chit_live_auction_page.dart")
