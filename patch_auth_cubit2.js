const fs = require("fs");
let code = fs.readFileSync("lib/core/blocs/auth/auth_cubit.dart", "utf8");

let startSetup = code.indexOf("Future<void> setupMpin");
let endSetup = code.indexOf("Future<void> changeMpin");
let startChange = endSetup;
let endChange = code.indexOf("Future<void> loginWithMpin");

let newSetup = `Future<void> setupMpin(String mpin) async {
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
  }

  `;

let newChange = `Future<void> changeMpin(String mpin) async {
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
  }

  `;

code = code.substring(0, startSetup) + newSetup + newChange + code.substring(endChange);
fs.writeFileSync("lib/core/blocs/auth/auth_cubit.dart", code);

