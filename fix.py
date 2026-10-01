import sys
import re

with open('lib/core/blocs/auth/auth_cubit.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''  Future<void> _forceLogout() async {
    // Revoke FCM token first before we lose the session
    try {
      final token = await NotificationService.getToken();
      if (token != null) {
        await _api.delete('/users/fcm-token', data: {'fcmToken': token});
      }
    } catch (e) {
      print("FCM revocation error: ");
    }

    await SecureStorage.clearAuthData();
    // 4F4F: Wipe document-related temporary state / memory cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Firebase signout error: ");
    }
    _currentUser = null;
    emit(Unauthenticated());
  }'''

repl = '''  bool _isLoggingOut = false;

  Future<void> _forceLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      // Revoke FCM token first before we lose the session
      try {
        final token = await NotificationService.getToken();
        if (token != null) {
          await _api.delete('/users/fcm-token', data: {'fcmToken': token});
        }
      } catch (e) {
        print("FCM revocation error: ");
      }

      await SecureStorage.clearAuthData();
      // 4F4F: Wipe document-related temporary state / memory cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        print("Firebase signout error: ");
      }
      _currentUser = null;
      emit(Unauthenticated());
    } finally {
      _isLoggingOut = false;
    }
  }'''

if target in content:
    content = content.replace(target, repl)
    with open('lib/core/blocs/auth/auth_cubit.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print('Replaced successfully')
else:
    print('Target not found')
