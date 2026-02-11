import '../models/user_model.dart';
import '../services/api_services.dart';

class AuthRepository {
  Future<void> sendOtp(String phone) async {
    try {
      final response = await ApiService.post('/auth/send-otp', data: {
        'phone': phone,
      });
      if (response.statusCode != 200) {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<String> verifyOtp(String phone, String otp) async {
    try {
      final response = await ApiService.post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });
      if (response.statusCode == 200) {
        return response.data['token'];
      }
      throw Exception('Invalid OTP');
    } catch (e) {
      throw Exception('Verification failed: $e');
    }
  }

  Future<UserModel> registerUser(UserModel user) async {
    try {
      final response = await ApiService.post('/auth/register', data: user.toJson());
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      }
      throw Exception('Registration failed');
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }
}