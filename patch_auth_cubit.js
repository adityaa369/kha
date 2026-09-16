const fs = require("fs");
let code = fs.readFileSync("lib/core/blocs/auth/auth_cubit.dart", "utf8");

code = code.replace(/Future<void> setupMpin[\s\S]*?emit\(Authenticated\(user: _currentUser!\)\);\n      }\n    }/g, `Future<void> setupMpin(String mpin) async {
    emit(AuthLoading());
    try {
      final response = await _api.post('/auth/mpin/setup', data: {'mpin': mpin});
      if (response.data['success'] == true) {
        emit(Authenticated(user: _currentUser!)); 
      } else {
        emit(AuthError(response.data['message'] ?? 'Failed to setup MPIN'));
      }
    } catch (e) {
      String msg = "Authentication failed";
      if (e is Failure) msg = e.message;
      else if (e is DioException && e.error is Failure) msg = (e.error as Failure).message;
      else if (e is DioException && e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) msg = e.response!.data['message'];
      else msg = e.toString();
      emit(AuthError(msg));
    }
  }`);

code = code.replace(/Future<void> changeMpin[\s\S]*?emit\(Authenticated\(user: _currentUser!\)\);\n      }\n    }/g, `Future<void> changeMpin(String mpin) async {
    emit(AuthLoading());
    try {
      final response = await _api.post('/auth/mpin/change', data: {'mpin': mpin});
      if (response.data['success'] == true) {
        emit(Authenticated(user: _currentUser!)); 
      } else {
        emit(AuthError(response.data['message'] ?? 'Failed to change MPIN'));
      }
    } catch (e) {
      String msg = "Authentication failed";
      if (e is Failure) msg = e.message;
      else if (e is DioException && e.error is Failure) msg = (e.error as Failure).message;
      else if (e is DioException && e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) msg = e.response!.data['message'];
      else msg = e.toString();
      emit(AuthError(msg));
    }
  }`);

fs.writeFileSync("lib/core/blocs/auth/auth_cubit.dart", code);

