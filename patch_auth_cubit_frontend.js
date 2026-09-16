const fs = require("fs");
let code = fs.readFileSync("lib/core/blocs/auth/auth_cubit.dart", "utf8");

let startSend = code.indexOf("Future<void> sendVerificationEmail() async {");
let endSend = code.indexOf("Future<void> logout() async {");

let newMethods = `Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      if (_currentUser?.email != null) {
        if (user.email != _currentUser!.email) {
          await user.verifyBeforeUpdateEmail(_currentUser!.email!);
          return;
        }
      }
      await user.sendEmailVerification();
    } catch (e) {
      throw Exception("Failed to send verification email: \${e.toString()}");
    }
  }

  Future<void> syncFirebaseState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await user.reload();
      final idToken = await user.getIdToken(true); // force refresh
      
      final response = await _api.post('/auth/sync-firebase', data: {
        'idToken': idToken
      });
      
      if (response.data['success'] == true && response.data['user'] != null) {
        _currentUser = UserModel.fromJson(response.data['user']);
        await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
        _emitAuthoritativeState();
      }
    } catch (e) {
      print("Firebase sync error: $e");
    }
  }

  `;

code = code.substring(0, startSend) + newMethods + code.substring(endSend);
fs.writeFileSync("lib/core/blocs/auth/auth_cubit.dart", code);

