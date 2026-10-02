import os

files_to_instrument = [
    ('lib/main.dart', 'void main() async {', 'void main() async {\n  log(\'[APP] bootstrap\');'),
    ('lib/config/routes.dart', 'redirect: (context, state) {\n      final authState = context.read<AuthCubit>().state;', 'redirect: (context, state) {\n      final authState = context.read<AuthCubit>().state;\n      log(\'[ROUTER] redirect eval for: ${state.uri.path}, state: ${authState.runtimeType}\');'),
    ('lib/config/routes.dart', 'return \'${AppConstants.splash}?redirect_to=${Uri.encodeComponent(state.uri.toString())}\';', 'log(\'[ROUTER] redirecting to splash because AuthInitial\');\n          return \'${AppConstants.splash}?redirect_to=${Uri.encodeComponent(state.uri.toString())}\';'),
    ('lib/core/blocs/auth/auth_cubit.dart', 'Future<void> checkAuthStatus() async {\n    emit(AuthInitial());', 'Future<void> checkAuthStatus() async {\n    log(\'[AUTH] checkAuthStatus called\');\n    emit(AuthInitial());'),
    ('lib/features/profile/presentation/pages/profile_page.dart', 'Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    log(\'[PROFILE] open / build\');'),
    ('lib/features/profile/presentation/pages/profile_page.dart', 'Future<void> _pickAndUploadImage(BuildContext context, ImageSource source) async {', 'Future<void> _pickAndUploadImage(BuildContext context, ImageSource source) async {\n    log(\'[PROFILE] update start\');'),
    ('lib/core/services/biometric_auth_service.dart', 'static Future<bool> authenticate() async {', 'static Future<bool> authenticate() async {\n    log(\'[AUTH] biometric_gate\');')
]

for fpath, old, new_text in files_to_instrument:
    if os.path.exists(fpath):
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
        if old in content:
            content = content.replace(old, new_text)
            
            if 'dart:developer' not in content:
                content = "import 'dart:developer';\n" + content
                
            with open(fpath, 'w', encoding='utf-8') as f:
                f.write(content)
