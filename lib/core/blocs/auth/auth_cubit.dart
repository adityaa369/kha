import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';
import '../../network/api_client.dart';
import '../../utils/secure_storage.dart';
import '../../../config/constants.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiClient _api;

  AuthCubit({ApiClient? api}) 
      : _api = api ?? ApiClient(),
        super(AuthInitial());
  UserModel? _currentUser;
  // Removed _reqId as we don't use SDK anymore

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

  // Send OTP via Backend (Bypassing SDK)
  Future<void> sendOtp(String phone) async {
    emit(AuthLoading());
    try {
      final response = await _api.post('/auth/send-otp', data: {
        'phone': phone,
      });

      if (response.data['success'] == true) {
        emit(OtpSent(phone: phone));
      } else {
        emit(AuthError(response.data['message'] ?? 'Failed to send OTP'));
      }
    } catch (e) {
      emit(AuthError('Failed to send OTP: $e'));
    }
  }

  // Verify OTP via Backend
  Future<void> verifyOtp(String phone, String otp) async {
    emit(AuthLoading());
    try {
      final response = await _api.post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
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
        emit(AuthError(response.data['message'] ?? 'Invalid OTP'));
      }
    } catch (e) {
      emit(AuthError('Verification failed: $e'));
    }
  }

  // Send OTP for registration completion (Second OTP)
  Future<void> sendRegistrationOtp() async {
    if (_currentUser == null) {
      emit(const AuthError('User data missing for registration OTP'));
      return;
    }
    
    emit(AuthLoading());
    try {
      final phone = _currentUser!.phone;
      final response = await _api.post('/auth/send-otp', data: {
        'phone': phone,
      });
      
      if (response.data['success'] == true) {
        emit(RegistrationOtpSent(phone: phone));
      } else {
        emit(AuthError(response.data['message'] ?? 'Failed to send secondary OTP'));
      }
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
        emit(PersonalDetailsSaved(user: _currentUser!));
      } else {
        emit(AuthError(response.data['message'] ?? 'Failed to save details'));
      }
    } catch (e) {
      emit(AuthError('Failed to save details: $e'));
    }
  }

  // Verify secondary OTP for registration completion
  Future<void> verifyRegistrationOtp(String otp) async {
    emit(AuthLoading());
    try {
      final phone = _currentUser!.phone;
      final response = await _api.post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });

      if (response.data['success'] == true) {
        emit(RegistrationOtpVerified(phone: phone));
      } else {
        emit(AuthError(response.data['message'] ?? 'Invalid secondary OTP'));
      }
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
