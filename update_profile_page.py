import os

file_path = 'lib/features/profile/presentation/pages/profile_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

replacement = """_MenuTile(
                            icon: Icons.person_outline,
                            title: 'Personal Details',
                            subtitle: 'Email, Gender, Pan, DOB, Address',
                            onTap: () => context.push('/profile/edit'),
                          ),
                          _MenuTile(
                            icon: Icons.security,
                            title: 'Security & Sessions',
                            subtitle: 'Manage your active devices and security logs',
                            onTap: () => context.push('/profile/security'),
                          ),"""

import re
content = re.sub(
    r"_MenuTile\(\s*icon:\s*Icons\.person_outline,\s*title:\s*'Personal Details',\s*subtitle:\s*'Email, Gender, Pan, DOB, Address',\s*onTap:\s*\(\)\s*=>[^\)]+\),",
    replacement,
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Injected security menu tile")
