import os
import re

# Fix main.dart
file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("appRunner: () => runApp(KhaataApp(systemStateCubit: systemStateCubit)));", "appRunner: () => runApp(const KhaataApp()));")

if "BlocProvider.value(value: systemStateCubit)" not in content:
    content = content.replace("providers: [", "providers: [\n        BlocProvider.value(value: systemStateCubit),")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

# Fix loan_repository.dart
repo_path = 'lib/data/repositories/loan_repository.dart'
with open(repo_path, 'r', encoding='utf-8') as f:
    repo = f.read()
repo = repo.replace("final response = await _apiClient.post(", "final response = await ApiClient().post(")
with open(repo_path, 'w', encoding='utf-8') as f:
    f.write(repo)

# Fix profile_page.dart (syntax error)
profile_path = 'lib/features/profile/presentation/pages/profile_page.dart'
with open(profile_path, 'r', encoding='utf-8') as f:
    profile = f.read()
profile = profile.replace("""                          _MenuTile(
                            icon: Icons.security,
                            title: 'Security & Sessions',
                            subtitle: 'Manage your active devices and security logs',
                            onTap: () => context.push('/profile/security'),
                          ),
                          ),
                          Divider""", """                          _MenuTile(
                            icon: Icons.security,
                            title: 'Security & Sessions',
                            subtitle: 'Manage your active devices and security logs',
                            onTap: () => context.push('/profile/security'),
                          ),
                          Divider""")
with open(profile_path, 'w', encoding='utf-8') as f:
    f.write(profile)

print("Fixed main, repo, and profile syntax.")
