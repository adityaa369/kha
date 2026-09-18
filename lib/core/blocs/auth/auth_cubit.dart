import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/painting.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../../data/models/user_model.dart';
import '../../network/api_client.dart';
import '../../utils/secure_storage.dart';
import '../../error/failures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../../../firebase_options.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../config/routes.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiClient _api;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  AuthCubit({ApiClient? api}) : _api = api ?? ApiClient(), super(AuthInitial()) {
    ApiClient.onUnauthorized = _forceLogout;
    ApiClient.onTokenExpired = _forceLogout;
    _initDeepLinkListener();
  }

  String? _lastProcessedLink;

  void _initDeepLinkListener() async {
    // 1 Handle cold-start links
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      // Ignore
    }

    // 2 Handle warm-start links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.toString() == _lastProcessedLink) return; // Prevent duplicate processing
    _lastProcessedLink = uri.toString();

    // Forensic logging (safe)
    print('[FORENSIC] Deep Link Received: full=$uri');

    if (uri.host != 'khaata-42b18.firebaseapp.com') {
      return; // Ignore unrelated domains
    }

    String? mode = uri.queryParameters['mode'];
    String? oobCode = uri.queryParameters['oobCode'];
    
    // Strict unwrapping for Firebase Hosting App Links
    if (mode == null || oobCode == null) {
      final nestedStr = uri.queryParameters['link'] ?? uri.queryParameters['continueUrl'];
      if (nestedStr != null) {
        final nestedUri = Uri.tryParse(nestedStr);
        if (nestedUri != null && nestedUri.host == 'khaata-42b18.firebaseapp.com') {
          mode = nestedUri.queryParameters['mode'];
          oobCode = nestedUri.queryParameters['oobCode'];
          print('[FORENSIC] Unwrapped nested link. mode=$mode hasOobCode=${oobCode != null}');
        }
      }
    }

    print('[FORENSIC] Final Parsed Payload: mode=$mode hasOobCode=${oobCode != null}');

    if ((mode == 'verifyAndChangeEmail' || mode == 'verifyEmail') && oobCode != null) {
      print('[FORENSIC] Starting action code application...');
      bool codeAppliedSuccessfully = false;
      bool wasAlreadyVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

      try {
        print('[FORENSIC] Calling checkActionCode...');
        await FirebaseAuth.instance.checkActionCode(oobCode);
        print('[FORENSIC] checkActionCode success.');
        
        print('[FORENSIC] Calling applyActionCode...');
        await FirebaseAuth.instance.applyActionCode(oobCode);
        print('[FORENSIC] applyActionCode success.');
        codeAppliedSuccessfully = true;
      } catch (e) {
        print('[FORENSIC] Action code failed/already consumed: $e');
      }
      
      // SECURITY REQUIREMENT Independently verify state rather than inferring from success/failure
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Wait briefly for Firebase backend to propagate the action code before reloading
        await Future.delayed(const Duration(seconds: 1));
        await user.reload();
        
        final freshUser = FirebaseAuth.instance.currentUser;
        if (freshUser?.emailVerified == true) {
          if (wasAlreadyVerified && !codeAppliedSuccessfully) {
            print('[FORENSIC] Firebase confirms email is ALREADY verified. (Silent to prevent hot-restart spam)');
            _emitAuthoritativeState();
            return;
          } else {
            print('[FORENSIC] Firebase confirms email is verified. Syncing with backend...');
            try {
              await syncFirebaseState(); // Forces refresh syncs to backend, updates AuthCubit state
              print('[FORENSIC] syncFirebaseState completed.');
              
              _showVerificationDialog(
                title: 'Email Verified',
                message: 'Your email has been successfully verified.\nYour account is now verified and ready to use.',
                isSuccess: true,
              );
            } catch (e) {
              print('[FORENSIC] syncFirebaseState failed: $e');
              _emitAuthoritativeState();
              _showVerificationDialog(
                title: 'Verification Failed',
                message: 'We couldn\'t complete email verification backend sync. Please try again.',
                isSuccess: false,
              );
            }
          }
        } else {
          print('[FORENSIC] Firebase confirms email is NOT verified.');
          _emitAuthoritativeState();
          if (!codeAppliedSuccessfully) {
            _showVerificationDialog(
              title: 'Verification Failed',
              message: 'This verification link is expired or invalid.\nPlease request a new verification email.',
              isSuccess: false,
            );
          } else {
             _showVerificationDialog(
              title: 'Verification Failed',
              message: 'We couldn\'t complete email verification. Please try again.',
              isSuccess: false,
            );
          }
        }
      }
    }
  }

  void _showVerificationDialog({required String title, required String message, required bool isSuccess}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = rootNavigatorKey.currentContext;
      if (context == null) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: Text(message, style: const TextStyle(fontSize: 16)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.green : Colors.orange,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(isSuccess ? "Continue" : "Close", style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      );
    });
  }

  @override
  Future<void> close() {
    _linkSubscription?.cancel();
    return super.close();
  }

  UserModel? _currentUser;
  bool isPasswordResetFlow = false;
  String? _verificationId;

  UserModel? get currentUser => _currentUser;

  Future<void> checkAuthStatus() async {
    emit(AuthInitial()); // Explicit Bootstrapping
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        emit(Unauthenticated());
        return;
      }

      // Autosync if Firebase thinks we are verified but Khatha doesn't know yet
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        try {
          await fbUser.reload();
          if (fbUser.emailVerified) {
            await syncFirebaseState();
          }
        } catch (e) {
          print('Firebase reload/sync failed during boot: $e');
        }
      }

      // Wait for authoritative backend validation
      try {
        final response = await _api.get('/auth/me');
        final data = response.data;
        if (data is Map && data['success'] == true) {
          _currentUser = UserModel.fromJson(data['user']);
          await SecureStorage.saveUserData(
            jsonEncode(_currentUser!.toFullJson()),
          );
          _emitAuthoritativeState();
        } else {
          await _forceLogout();
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          // Token revoked or user banned
          await _forceLogout();
        } else {
          // Network timeout or 5xx App is offline but has a cached token.
          // Fall back to local data so app isnt bricked offline, but mark explicitly as AuthOffline.
          final userDataJson = await SecureStorage.getUserData();
          if (userDataJson != null) {
            _currentUser = UserModel.fromJson(jsonDecode(userDataJson));
            emit(AuthOffline(user: _currentUser!));
          } else {
            await _forceLogout();
          }
        }
      } catch (e) {
        print("Unknown error in checkAuthStatus: $e");
        final userDataJson = await SecureStorage.getUserData();
        if (userDataJson != null) {
          _currentUser = UserModel.fromJson(jsonDecode(userDataJson));
          emit(AuthOffline(user: _currentUser!));
        } else {
          emit(Unauthenticated());
        }
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _forceLogout() async {
    await SecureStorage.clearAuthData();
    // 4F4F: Wipe document-related temporary state / memory cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Firebase signout error: $e");
    }
    _currentUser = null;
    emit(Unauthenticated());
  }

  void _emitAuthoritativeState() async {
    if (_currentUser == null) {
      emit(Unauthenticated());
      return;
    }

    if (isPasswordResetFlow) {
      emit(PasswordResetRequired(user: _currentUser));
      return;
    }

    // Sync FCM Token quietly in the background without blocking route
    try {
      final fcmToken = await NotificationService.getToken();
      // Phase 4E Backend expects token in body, maps to req.user.id implicitly
      if (fcmToken != null) {
        await _api.post('/users/fcm-token', data: {'fcmToken': fcmToken});
      }
    } catch (_) {}

    final user = _currentUser!;
    emit(Authenticated(user: user));
  }

  //  
  // Workflow Methods (Note: They now trigger transient UI states
  // but eventually reconverge to _emitAuthoritativeState)
  //  
  
  bool _isSubmitting = false;

  Future<void> sendOtp(String phone) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit(AuthLoading());
    try {
      String formattedPhone = phone.trim();
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = formattedPhone.startsWith('91')
            ? '+$formattedPhone'
            : '+91$formattedPhone';
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          _isSubmitting = false;
          emit(AuthError(e.message ?? 'Firebase Verification failed'));
          checkAuthStatus(); // Revert back to proper baseline on error
        },
        codeSent: (String verificationId, int? resendToken) {
          _isSubmitting = false;
          _verificationId = verificationId;
          emit(OtpSent(phone: phone));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _isSubmitting = false;
      emit(AuthError('Failed to send OTP: $e'));
      checkAuthStatus();
    }
  }

  Future<void> verifyOtp(String phone, String otp, {Map<String, dynamic>? registrationDetails}) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit(OtpVerifying());
    try {
      if (_verificationId == null) throw Exception('Verification ID missing');

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final idToken = await userCredential.user?.getIdToken(true);

      if (idToken == null)
        throw Exception('Failed to retrieve Firebase ID Token');
        
      _verificationId = null; // Singleuse! Clear it to prevent accidental reuse on resend.

      // Send ID Token to backend (Phase 4E Contract)
      final response = await _api.post(
        '/auth/verify-otp',
        data: {
          'idToken': idToken, 
          'phone': phone,
          'registrationDetails': registrationDetails
        },
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final token = data['token'];
        await SecureStorage.saveToken(token);

        try {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          await firebaseUser?.reload();
        } catch (e) {
          print('FIREBASE_PROFILE_SYNC: reload failed: $e');
        }

        _currentUser = UserModel.fromJson(data['user']);
        await SecureStorage.saveUserData(
          jsonEncode(_currentUser!.toFullJson()),
        );

        if (isPasswordResetFlow) {
          isPasswordResetFlow = false;
          emit(PasswordResetRequired(user: _currentUser));
        } else {
          _emitAuthoritativeState();
        }
      } else {
        emit(
          AuthError(
            (data is Map)
                ? (data['message'] ?? 'Invalid response')
                : 'Invalid response',
          ),
        );
        emit(Unauthenticated());
      }
    } on DioException catch (e) {
      emit(
        AuthError(
          e.error is Failure
              ? (e.error as Failure).message
              : 'Verification failed',
        ),
      );
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Verification failed: $e'));
      emit(Unauthenticated());
    } finally {
      _isSubmitting = false;
    }
  }

  Future<void> savePersonalDetails({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    emit(AuthLoading());
    try {
      final response = await _api.put(
        '/users/profile',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
        },
      );
      _handleProfileUpdateResponse(response);
    } catch (e) {
      _handleProfileUpdateError(e);
    }
  }

  Future<void> savePanDetails({
    required String pan,
    required String aadhar,
    required String dob,
    required String gender,
  }) async {
    emit(AuthLoading());
    try {
      final response = await _api.put(
        '/users/profile',
        data: {'pan': pan, 'aadhar': aadhar, 'dob': dob, 'gender': gender},
      );
      _handleProfileUpdateResponse(response);
    } catch (e) {
      _handleProfileUpdateError(e);
    }
  }

  Future<void> completeRegistration() async {
    emit(AuthLoading());
    try {
      final response = await _api.get('/auth/me');
      _handleProfileUpdateResponse(response);
    } catch (e) {
      _handleProfileUpdateError(e);
    }
  }

  void _handleProfileUpdateResponse(Response response) async {
    final data = response.data;
    if (data is Map && data['success'] == true) {
      _currentUser = UserModel.fromJson(data['user']);
      await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
      _emitAuthoritativeState(); // Progress user cleanly through standard funnel
    } else {
      emit(
        AuthError(
          (data is Map)
              ? (data['message'] ?? 'Update failed')
              : 'Update failed',
        ),
      );
      _emitAuthoritativeState(); // Fallback to whatever true state they have
    }
  }

  void _handleProfileUpdateError(dynamic e) {
    emit(
      AuthError(
        e is DioException && e.error is Failure
            ? (e.error as Failure).message
            : e.toString(),
      ),
    );
    if (_currentUser != null) {
      _emitAuthoritativeState();
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> loginWithPassword(String phone, String password) async {
    emit(AuthLoading());
    try {
      final response = await _api.post(
        '/auth/login-password',
        data: {'phone': phone, 'password': password},
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        await SecureStorage.saveToken(data['token']);
        _currentUser = UserModel.fromJson(data['user']);
        await SecureStorage.saveUserData(
          jsonEncode(_currentUser!.toFullJson()),
        );
        _emitAuthoritativeState();
      } else {
        emit(
          AuthError(
            (data is Map)
                ? (data['message'] ?? 'Invalid response')
                : 'Invalid response',
          ),
        );
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(
        AuthError(
          e is DioException && e.error is Failure
              ? (e.error as Failure).message
              : e.toString(),
        ),
      );
      emit(Unauthenticated());
    }
  }

  Future<void> resetPassword(String newPassword) async {
    emit(AuthLoading());
    try {
      final response = await _api.post(
        '/auth/reset-password',
        data: {'password': newPassword},
      );
      if (response.data is Map && response.data['success'] == true) {
        _emitAuthoritativeState();
      } else {
        emit(
          AuthError(response.data?['message'] ?? 'Failed to reset password'),
        );
        _emitAuthoritativeState();
      }
    } catch (e) {
      emit(
        AuthError(
          e is DioException && e.error is Failure
              ? (e.error as Failure).message
              : e.toString(),
        ),
      );
      _emitAuthoritativeState();
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      
      // Bulletproof self-healing: if Firebase session was somehow lost, re-authenticate using Khatha session
      if (user == null) {
        print('VERIFY_EMAIL_FLOW: Firebase user is null. Attempting to self-heal via custom token...');
        try {
          final tokenResponse = await _api.get('/auth/firebase-custom-token');
          if (tokenResponse.data['success'] == true && tokenResponse.data['customToken'] != null) {
            await FirebaseAuth.instance.signInWithCustomToken(tokenResponse.data['customToken']);
            user = FirebaseAuth.instance.currentUser;
            print('VERIFY_EMAIL_FLOW: Self-heal successful. Firebase user restored.');
          }
        } catch (e) {
          print('VERIFY_EMAIL_FLOW: Self-heal failed: $e');
        }
      }
      
      if (user == null) throw Exception("User not authenticated");
      
      print('FIREBASE_PROFILE_SYNC: reload attempted = true');
      try {
        await user.reload();
        print('FIREBASE_PROFILE_SYNC: reload succeeded = true');
      } catch (e) {
        print('FIREBASE_PROFILE_SYNC: reload succeeded = false (error: $e)');
      }

      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) throw Exception("User not authenticated after reload");

      final actionSettings = ActionCodeSettings(
        url: 'https://khaata-42b18.firebaseapp.com/verified',
        handleCodeInApp: true,
        androidPackageName: 'com.vest.khataa',
        androidInstallApp: true,
        androidMinimumVersion: '1',
      );

      print('FIREBASE_PROFILE_SYNC: firebase email present = ${refreshedUser.email != null}');
      print('FIREBASE_PROFILE_SYNC: firebase emailVerified = ${refreshedUser.emailVerified}');
      
      print('VERIFY_EMAIL_FLOW: hasCurrentUserEmail = ${refreshedUser.email != null}');
      print('VERIFY_EMAIL_FLOW: emailVerified = ${refreshedUser.emailVerified}');

      if (refreshedUser.emailVerified) {
        print('VERIFY_EMAIL_FLOW: selectedOperation = already_verified');
        return; // Nothing to do
      }

      if (refreshedUser.email == null) {
        print('VERIFY_EMAIL_FLOW: firebase email missing, requesting backend sync...');
        try {
          final syncResponse = await _api.post('/auth/sync-email-to-firebase');
          print('VERIFY_EMAIL_FLOW: backend sync response = ${syncResponse.data}');
          
          // Reload Firebase user after backend attached the email
          await FirebaseAuth.instance.currentUser?.reload();
          final repairedUser = FirebaseAuth.instance.currentUser;
          
          if (repairedUser?.email == null) {
            print('VERIFY_EMAIL_FLOW: error = email still missing after sync');
            throw Exception("Could not attach email to your account. Please contact support.");
          }
          
          print('VERIFY_EMAIL_FLOW: email repaired, proceeding to send verification');
          // Send verification with the repaired user
          await repairedUser!.sendEmailVerification(actionSettings);
          print('VERIFY_EMAIL_FLOW: sendEmailVerification completed successfully');
          return;
        } catch (syncErr) {
          print('VERIFY_EMAIL_FLOW: backend sync failed: $syncErr');
          throw Exception("Failed to sync email. Please log out, log in with OTP, and try again.");
        }
      }

      print('VERIFY_EMAIL_FLOW: selectedOperation = sendEmailVerification');
      
      try {
        await refreshedUser.sendEmailVerification(actionSettings);
        print('VERIFY_EMAIL_FLOW: sendEmailVerification completed successfully');
      } catch (fbErr) {
        print('VERIFY_EMAIL_FLOW: sendEmailVerification Firebase error: $fbErr');
        throw Exception("Failed to send verification email: $fbErr");
      }
    } catch (e) {
      print('VERIFY_EMAIL_FLOW: Generic error: $e');
      throw Exception("Failed to send verification email: ${e.toString()}");
    }
  }

  Future<void> syncFirebaseState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await user.reload();
      final idToken = await user.getIdToken(true); // force refresh
      
      final response = await _api.post('/auth/sync-firebase', data: {
        'idToken': idToken,
        'emailVerified': user.emailVerified,
        'email': user.email,
      });
      
      if (response.data['success'] == true) {
        // Backend doesn't return the user object in sync-firebase, so fetch it
        final meResponse = await _api.get('/auth/me');
        if (meResponse.data['success'] == true && meResponse.data['user'] != null) {
          _currentUser = UserModel.fromJson(meResponse.data['user']);
          await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
          _emitAuthoritativeState();
        }
      }
    } catch (e) {
      print("Firebase sync error: $e");
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _forceLogout();
    } catch (e) {
      emit(AuthError('Logout failed: $e'));
      await _forceLogout(); // Ensure local state is wiped even on error
    }
  }

  Future<void> processCreditScore() async {
    try {
      final response = await _api.post('/auth/credit-score');
      final data = response.data;
      if (data is Map && data['success'] == true && data['user'] != null) {
        _currentUser = UserModel.fromJson(data['user']);
        await SecureStorage.saveUserData(
          jsonEncode(_currentUser!.toFullJson()),
        );
      }
    } catch (_) {}
    _emitAuthoritativeState();
  }

  void resetToInitial() => checkAuthStatus();

  Future<void> setupMpin(String mpin) async {
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

  Future<void> changeMpin(String mpin) async {
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
          
          try {
            final firebaseUser = FirebaseAuth.instance.currentUser;
            await firebaseUser?.reload();
          } catch (e) {
            print('FIREBASE_PROFILE_SYNC: reload failed: $e');
          }
          
          final token = response.data['token'];
          if (token != null) {
              await SecureStorage.saveToken(token);
          }
        
        final userResult = await _api.get('/auth/me');
        if (userResult.data['success']) {
          _currentUser = UserModel.fromJson(userResult.data['user']);
          emit(Authenticated(user: _currentUser!));
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
        String msg = "Authentication failed";
        if (e is Failure) msg = e.message;
        else if (e is DioException && e.error is Failure) msg = (e.error as Failure).message;
        else msg = e.toString();
        emit(AuthError(msg));
    } finally {
      _isSubmitting = false;
    }
  }
}
