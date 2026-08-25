import os

file_path = 'lib/config/routes.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

imports = """import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/profile/presentation/pages/security_hub_page.dart';
import '../core/blocs/security/security_cubit.dart';
import '../data/repositories/security_repository.dart';
import '../core/network/api_client.dart';
import '../core/services/secure_storage_service.dart';
"""

content = content.replace("import '../features/admin/presentation/pages/admin_dashboard_page.dart';", imports)

route = """    GoRoute(
      path: '/profile/security',
      builder: (context, state) => BlocProvider(
        create: (ctx) => SecurityCubit(SecurityRepository(ctx.read<ApiClient>()), ctx.read<SecureStorageService>()),
        child: const SecurityHubPage(),
      ),
    ),
    GoRoute(
      path: '/admin',"""

content = content.replace("    GoRoute(\n      path: '/admin',", route)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Injected security route")
