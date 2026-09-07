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

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiClient _api;

  AuthCubit({ApiClient? api}) : _api = api ?? ApiClient(), super(AuthInitial());
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

      // DO NOT emit authenticated state optimistically here anymore!
      // Wait for authoritative backend validation.
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
          // Network timeout or 5xx: App is offline but has a cached token.
          // Fall back to local data so app isn't bricked offline, but mark explicitly as AuthOffline.
          final userDataJson = await SecureStorage.getUserData();
          if (userDataJson != null) {
            _currentUser = UserModel.fromJson(jsonDecode(userDataJson));
            emit(AuthOffline(user: _currentUser!));
          } else {
            await _forceLogout();
          }
        }
      } catch (e) {
        await _forceLogout();
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _forceLogout() async {
    await SecureStorage.clearAuthData();
    // 4F-4F: Wipe document-related temporary state / memory cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
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
      // Phase 4E: Backend expects token in body, maps to req.user.id implicitly
      if (fcmToken != null) {
        await _api.post('/users/fcm-token', data: {'fcmToken': fcmToken});
      }
    } catch (_) {}

    final user = _currentUser!;

    // Evaluate backend source of truth for routing
    if (!user.isEmailVerified) {
      emit(AuthenticatedEmailUnverified(user: user));
    } else if (!user.isKycComplete || user.firstName.isEmpty) {
      emit(AuthenticatedEmailVerifiedKycIncomplete(user: user));
    } else {
      emit(AuthenticatedKycComplete(user: user));
    }
  }

  // -------------------------------------------------------------
  // Workflow Methods (Note: They now trigger transient UI states
  // but eventually re-converge to _emitAuthoritativeState)
  // -------------------------------------------------------------

  Future<void> sendOtp(String phone) async {
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
          emit(AuthError(e.message ?? 'Firebase Verification failed'));
          checkAuthStatus(); // Revert back to proper baseline on error
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          emit(OtpSent(phone: phone));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      emit(AuthError('Failed to send OTP: $e'));
      checkAuthStatus();
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
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

      // Send ID Token to backend (Phase 4E Contract)
      final response = await _api.post(
        '/auth/verify-otp',
        data: {'idToken': idToken, 'phone': phone},
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final token = data['token'];
        await SecureStorage.saveToken(token);

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
      final response = await _api.post('/auth/send-verification-email');
      if (response.data == null || response.data['success'] != true) {
        throw Exception(response.data?['message'] ?? 'Failed to send email');
      }
    } catch (e) {
      throw Exception(
        e is DioException && e.error is Failure
            ? (e.error as Failure).message
            : 'Failed to send email',
      );
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
}
