import os

file_path = 'lib/features/chit_funds/presentation/pages/chit_live_auction_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../../../../core/config/env_config.dart';\n", "")
content = content.replace("EnvConfig.apiUrl", "'https://khataa-backend.onrender.com'")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Reverted chit_live_auction_page.dart")
