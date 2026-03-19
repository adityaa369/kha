import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';
import '../../network/api_client.dart';
import '../../utils/secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/constants.dart';

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
        // Load cached user immediately
        _currentUser = UserModel.fromJson(jsonDecode(userDataJson));
        
        // Verify with backend
        try {
          final response = await _api.get('/users/profile');
          if (response.data['success'] == true) {
            _currentUser = UserModel.fromJson(response.data['user']);
            await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
            
            if (_currentUser!.firstName.isNotEmpty) {
              emit(Authenticated(user: _currentUser!));
            } else {
              await logout();
            }
          } else {
            // Token invalid or other backend rejection
             await logout();
          }
        } catch (e) {
          // NETWORK ERROR or Server Down
          // Do NOT logout. Allow offline usage with cached data.
          if (_currentUser != null && _currentUser!.firstName.isNotEmpty) {
             emit(Authenticated(user: _currentUser!));
          } else {
             // If we really can't confirm user, maybe stay in Loading or fallback
             // But for now, let's allow it if we have cache.
             emit(Authenticated(user: _currentUser!));
          }
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  // Send OTP via Firebase SDK
  Future<void> sendOtp(String phone) async {
    emit(AuthLoading());
    try {
      // Ensure phone has country code +91
      String formattedPhone = phone;
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('91')) {
          formattedPhone = '+$formattedPhone';
        } else {
          formattedPhone = '+91$formattedPhone';
        }
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
         // Auto-resolution (rarely happens if not Play Integrity verified)
         // We let the user enter OTP manually for consistency
        },
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

  // Verify OTP via Firebase then backend
  Future<void> verifyOtp(String phone, String otp) async {
    emit(AuthLoading());
    try {
      if (_verificationId == null) {
        emit(const AuthError('Verification session expired. Please request OTP again.'));
        return;
      }

      // 1. Verify with Firebase
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

      // 2. Send ID token to our backend
      final response = await _api.post('/auth/verify-otp', data: {
        'idToken': idToken,
        'phone': phone,
      });

      if (response.data['success'] == true) {
        final token = response.data['token'];
        final isNewUser = response.data['isNewUser'] ?? false;
        final userJson = response.data['user'];

        await SecureStorage.saveToken(token);
        _currentUser = UserModel.fromJson(userJson);
        await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));

        if (isNewUser || _currentUser!.firstName.isEmpty) {
          emit(OtpVerified(phone: phone));
        } else {
          emit(Authenticated(user: _currentUser!));
        }
      } else {
        emit(AuthError(response.data['message'] ?? 'Invalid backend response'));
      }
    } catch (e) {
      emit(AuthError('Verification failed: $e'));
    }
  }

  // Send OTP for registration completion using Firebase
  Future<void> sendRegistrationOtp() async {
    if (_currentUser == null) {
      emit(const AuthError('User data missing for registration OTP'));
      return;
    }
    
    emit(AuthLoading());
    try {
      final phone = _currentUser!.phone;
      String formattedPhone = phone;
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
          emit(RegistrationOtpSent(phone: phone));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      emit(AuthError('Failed to send secondary OTP: $e'));
    }
  }
  // Save personal details to backend immediately
  Future<void> savePersonalDetails({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    emit(AuthLoading());
    try {
      // Optimistic update
      _currentUser = _currentUser?.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
      );

      final response = await _api.post('/auth/register', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
      });

      if (response.data['success'] == true) {
        _currentUser = UserModel.fromJson(response.data['user']);
        await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
        emit(Authenticated(user: _currentUser!));
      } else {
        emit(AuthError(response.data['message'] ?? 'Failed to save details'));
      }
    } catch (e) {
      emit(AuthError('Failed to save details: $e'));
    }
  }

  // Verify secondary OTP with Firebase
  Future<void> verifyRegistrationOtp(String otp) async {
    emit(AuthLoading());
    try {
      if (_verificationId == null) {
        emit(const AuthError('Verification session expired. Please request OTP again.'));
        return;
      }
      
      final phone = _currentUser!.phone;

      // Verify with Firebase
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        emit(const AuthError('Failed to verify secondary Firebase Token'));
        return;
      }

      // For registration completion, we're just verifying they own it to save the full profile.
      // So no need to call /auth/verify-otp again if it's already verified with Firebase
      // However, to keep backend state consistent if needed, we proceed.
      // But looking at the backend, `auth/register` doesn't require an OTP inside the payload anymore, it just expects the jwt Authorization header.
      // So Firebase passing = valid secondary OTP.
      
      emit(RegistrationOtpVerified(phone: phone));
    } catch (e) {
      emit(AuthError('Secondary verification failed: $e'));
    }
  }

  // Save PAN details to backend immediately
  Future<void> savePanDetails({
    required String pan,
    required String aadhar,
    required String dob,
    required String gender,
  }) async {
    emit(AuthLoading());
    try {
      _currentUser = _currentUser?.copyWith(
        pan: pan,
        aadhar: aadhar,
        dob: dob,
        gender: gender,
      );

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

  // Complete registration and save to Node.js backend
  Future<void> completeRegistration() async {
    emit(AuthLoading());
    try {
      if (_currentUser == null) {
        emit(const AuthError('User data not found'));
        return;
      }

      final response = await _api.post('/auth/register', data: _currentUser!.toJson());

      if (response.data['success'] == true) {
        _currentUser = UserModel.fromJson(response.data['user']);
        await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
        emit(Authenticated(user: _currentUser!));
      } else {
        emit(AuthError(response.data['message'] ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError('Registration failed: $e'));
    }
  }

  // Logout
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

  // Placeholder for credit score processing (simulated for flow consistency)
  Future<void> processCreditScore() async {
    // In Node.js backend, credit score record is created during auth verification or profile completion
    // We just wait a bit to simulate processing for UI experience
    await Future.delayed(const Duration(seconds: 2));
  }
}
