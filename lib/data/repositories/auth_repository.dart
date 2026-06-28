import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/error/failures.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  final ApiClient _api;

  AuthRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<UserModel> getProfile() async {
    return await handleApiCall(() async {
      final response = await _api.get('/users/profile');
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['user']);
      }
      throw const AuthFailure('Profile fetch failed');
    });
  }

  Future<Map<String, dynamic>> verifyOtp(String idToken, String phone) async {
    return await handleApiCall(() async {
      final response = await _api.post(
        '/auth/verify-otp',
        data: {'idToken': idToken, 'phone': phone},
      );
      if (response.data['success'] == true) {
        return {
          'token': response.data['token'],
          'isNewUser': response.data['isNewUser'] ?? false,
          'user': UserModel.fromJson(response.data['user']),
        };
      }
      throw AuthFailure(response.data['message'] ?? 'Invalid backend response');
    });
  }

  Future<UserModel> registerDetails(Map<String, dynamic> data) async {
    return await handleApiCall(() async {
      final response = await _api.post('/auth/register', data: data);
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['user']);
      }
      throw ServerFailure(response.data['message'] ?? 'Registration failed');
    });
  }
}
