import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import '../../../data/models/user_model.dart';
import '../../network/api_client.dart';
import '../../utils/secure_storage.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    // Initialize MSG91 SDK
    OTPWidget.initializeWidget(
      '36626b70594e353337323033', // widgetId
      '493750T09QOxt0g698cb47bP1', // authToken
    );
  }

  final _api = ApiClient();
  UserModel? _currentUser;
  String? _requestId;

  UserModel? get currentUser => _currentUser;

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final token = await SecureStorage.getToken();
      final userDataJson = await SecureStorage.getUserData();

      if (token != null && userDataJson != null) {
        try {
          final response = await _api.get('/users/profile');
          if (response.data['success'] == true) {
            _currentUser = UserModel.fromJson(response.data['user']);
            await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));
            emit(Authenticated(user: _currentUser!));
          } else {
            await logout();
          }
        } catch (e) {
          if (e.toString().contains('401')) {
            await logout();
          } else {
            _currentUser = UserModel.fromJson(jsonDecode(userDataJson));
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

  // Send OTP via MSG91 SDK
  Future<void> sendOtp(String phone) async {
    emit(AuthLoading());
    try {
      // MSG91 requires country code but without '+'
      final identifier = '91$phone'; 
      final data = {'identifier': identifier};
      
      final response = await OTPWidget.sendOTP(data);
      final responseData = jsonDecode(response.toString());

      if (responseData['type'] == 'success') {
        _requestId = responseData['message']; // MSG91 message field contains reqId usually
        emit(OtpSent(phone: phone));
      } else {
        emit(AuthError(responseData['message'] ?? 'Failed to send OTP'));
      }
    } catch (e) {
      emit(AuthError('Failed to send OTP: $e'));
    }
  }

  // Verify OTP via MSG91 SDK and then verify with Backend
  Future<void> verifyOtp(String phone, String otp) async {
    emit(AuthLoading());
    try {
      if (_requestId == null) {
        emit(const AuthError('Request ID not found. Please resend OTP.'));
        return;
      }

      final data = {
        'reqId': _requestId,
        'otp': otp,
      };

      final response = await OTPWidget.verifyOTP(data);
      final responseData = jsonDecode(response.toString());

      if (responseData['type'] == 'success') {
        // Verification on client successful, now get access token and verify with backend
        final accessToken = responseData['message']; // MSG91 returns access token in message field on success

        final backendResponse = await _api.post('/auth/verify-token', data: {
          'accessToken': accessToken,
        });

        if (backendResponse.data['success'] == true) {
          final token = backendResponse.data['token'];
          final isNewUser = backendResponse.data['isNewUser'] ?? false;
          final userJson = backendResponse.data['user'];

          await SecureStorage.saveToken(token);
          _currentUser = UserModel.fromJson(userJson);
          await SecureStorage.saveUserData(jsonEncode(_currentUser!.toFullJson()));

          if (isNewUser || _currentUser!.firstName.isEmpty) {
            emit(OtpVerified(phone: phone));
          } else {
            emit(Authenticated(user: _currentUser!));
          }
        } else {
          emit(AuthError(backendResponse.data['message'] ?? 'Backend verification failed'));
        }
      } else {
        emit(AuthError(responseData['message'] ?? 'Invalid OTP'));
      }
    } catch (e) {
      emit(AuthError('Verification failed: $e'));
    }
  }

  // Save personal details locally (before registration)
  Future<void> savePersonalDetails({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    emit(AuthLoading());
    try {
      _currentUser = _currentUser?.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
      );
      emit(PersonalDetailsSaved(user: _currentUser!));
    } catch (e) {
      emit(AuthError('Failed to save details: $e'));
    }
  }

  // Save PAN details locally (before registration)
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
      emit(PanDetailsSaved(user: _currentUser!));
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
}
