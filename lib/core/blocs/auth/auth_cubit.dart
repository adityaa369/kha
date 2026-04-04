import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';
import '../../network/api_client.dart';
import '../../utils/secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiClient _api;

  AuthCubit({ApiClient? api}) 
      : _api = api ?? ApiClient(),
        super(AuthInitial());
  UserModel? _currentUser;
  String? _verificationId;

  UserModel? get currentUser => _currentUser;

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final token = await SecureStorage.getToken();
      final userDataJson = await SecureStorage.getUserData();

      if (token != null && userDataJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userDataJson));
        
        // INSTANTLY emit authenticated state using local cache!
        _emitAuthenticatedState();
        
        // Silently sync with backend to ensure token validity
        _api.get('/auth/me').then((response) async {
          if (response.data['success'] == true) {
            _currentUser = UserModel.fromJson(response.data['user']);
            await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
            _emitAuthenticatedState(); // Refresh UI with latest data
          } else {
            await logout();
          }
        }).catchError((_) {
            // Ignore network timeouts silently during optimistic boot
        });
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  void _emitAuthenticatedState() async {
    if (_currentUser == null) {
      emit(Unauthenticated());
      return;
    }
    
    // Sync FCM Token quietly in the background
    try {
      final fcmToken = await NotificationService.getToken();
      if (fcmToken != null) {
        await _api.post('/users/fcm-token', data: {'fcmToken': fcmToken});
      }
    } catch (_) {}
    
    if (_currentUser!.isKycComplete && _currentUser!.firstName.isNotEmpty) {
      emit(AuthenticatedFull(user: _currentUser!));
    } else {
      emit(AuthenticatedUnverified(user: _currentUser!));
    }
  }

  Future<void> sendOtp(String phone) async {
    emit(AuthLoading());
    try {
      String formattedPhone = phone.trim();
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('91')) {
          formattedPhone = '+$formattedPhone';
        } else {
          formattedPhone = '+91$formattedPhone';
        }
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          emit(AuthError(e.message ?? 'Firebase Verification failed'));
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
      emit(AuthError('Failed to initiate Firebase OTP: $e'));
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    emit(AuthLoading());
    try {
      if (_verificationId == null) {
        emit(const AuthError('Verification session expired. Please request OTP again.'));
        return;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        emit(const AuthError('Failed to get Firebase ID Token'));
        return;
      }

      final response = await _api.post('/auth/verify-otp', data: {
        'idToken': idToken,
        'phone': phone,
      });

      if (response.data['success'] == true) {
        final token = response.data['token'];
        final userJson = response.data['user'];

        await SecureStorage.saveToken(token);
        _currentUser = UserModel.fromJson(userJson);
        await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));

        _emitAuthenticatedState();
      } else {
        emit(AuthError(response.data['message'] ?? 'Invalid backend response'));
      }
    } catch (e) {
      emit(AuthError('Verification failed: $e'));
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
      final response = await _api.post('/auth/register', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
      });

      if (response.data['success'] == true) {
        _currentUser = UserModel.fromJson(response.data['user']);
        await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
        emit(PersonalDetailsSaved(user: _currentUser!));
      } else {
        emit(AuthError(response.data['message'] ?? 'Failed to save details'));
      }
    } catch (e) {
      emit(AuthError('Failed to save details: $e'));
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
      final response = await _api.post('/auth/register', data: {
        'pan': pan,
        'aadhar': aadhar,
        'dob': dob,
        'gender': gender,
      });

      if (response.data['success'] == true) {
        _currentUser = UserModel.fromJson(response.data['user']);
        await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
        emit(PanDetailsSaved(user: _currentUser!));
      } else {
        emit(AuthError(response.data['message'] ?? 'Failed to save PAN details'));
      }
    } catch (e) {
      emit(AuthError('Failed to save PAN details: $e'));
    }
  }

  Future<void> completeRegistration() async {
    emit(AuthLoading());
    try {
      if (_currentUser == null) {
        emit(const AuthError('User data not found'));
        return;
      }

      final response = await _api.get('/auth/me');

      if (response.data['success'] == true) {
        _currentUser = UserModel.fromJson(response.data['user']);
        await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
        _emitAuthenticatedState();
      } else {
        emit(AuthError(response.data['message'] ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError('Registration failed: $e'));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await SecureStorage.clearAll();
      _currentUser = null;
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed: $e'));
    }
  }

  Future<void> processCreditScore() async {
    await Future.delayed(const Duration(seconds: 2));
    emit(const CreditScoreProcessed());
  }
}
