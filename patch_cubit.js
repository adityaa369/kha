const fs = require('fs'); 
let txt = fs.readFileSync('lib/core/blocs/auth/auth_cubit.dart', 'utf8'); 
const lastIdx = txt.lastIndexOf('}'); 
if (lastIdx > -1) { 
  txt = txt.substring(0, lastIdx) + 
  Future<void> setupMpin(String mpin) async {
    emit(AuthLoading());
    try {
      final response = await _api.post('/auth/mpin/setup', data: {'mpin': mpin});
      if (response.data['success'] == true) {
        emit(Authenticated(_currentUser!)); 
      } else {
        emit(const AuthError('Failed to setup MPIN'));
        emit(Authenticated(_currentUser!));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Authenticated(_currentUser!));
    }
  }

  Future<void> loginWithMpin(String phone, String mpin) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit(AuthLoading());
    try {
      final response = await _api.post('/auth/mpin/verify', data: {
        'phone': phone,
        'mpin': mpin,
      });

      if (response.data['success'] == true && response.data['customToken'] != null) {
        final customToken = response.data['customToken'];
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
            final idToken = await user.getIdToken();
            if (idToken != null) {
                await SecureStorage.saveToken(idToken);
            }
        }
        
        final userResult = await _api.get('/auth/me');
        if (userResult.data['success']) {
          _currentUser = UserModel.fromJson(userResult.data['user']);
          emit(Authenticated(_currentUser!));
        }
      } else {
        emit(const AuthError('Invalid MPIN'));
      }
    } on DioException catch (e) {
      String msg = 'Failed to login with MPIN';
      if (e.response?.statusCode == 429) {
          msg = e.response?.data['message'] ?? 'Too many attempts. Account locked.';
      } else if (e.response?.statusCode == 401) {
          msg = e.response?.data['message'] ?? 'Invalid MPIN.';
      }
      emit(AuthError(msg));
    } catch (e) {
      emit(AuthError(e.toString()));
    } finally {
      _isSubmitting = false;
    }
  }
}
; 
  fs.writeFileSync('lib/core/blocs/auth/auth_cubit.dart', txt, 'utf8'); 
}