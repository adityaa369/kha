import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/session_model.dart';
import '../models/security_event_model.dart';

class SecurityRepository {
  final ApiClient _apiClient;

  SecurityRepository(this._apiClient);

  Future<List<SessionModel>> getSessions(String? currentRefreshToken) async {
    final response = await _apiClient.get('/auth/sessions', options: Options(headers: currentRefreshToken != null ? {'x-refresh-token': currentRefreshToken} : {}));
    if (response.data['success'] == true) {
      final List data = response.data['sessions'] ?? [];
      return data.map((json) => SessionModel.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch sessions');
  }

  Future<List<SecurityEventModel>> getSecurityEvents() async {
    final response = await _apiClient.get('/auth/security-events');
    if (response.data['success'] == true) {
      final List data = response.data['events'] ?? [];
      return data.map((json) => SecurityEventModel.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch events');
  }

  Future<void> revokeSession(String sessionId) async {
    final response = await _apiClient.delete('/auth/sessions/$sessionId');
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to revoke session');
    }
  }

  Future<void> revokeOtherSessions(String currentRefreshToken) async {
    final response = await _apiClient.post(
      '/auth/sessions/revoke-others',
      data: {'refreshToken': currentRefreshToken},
    );
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to revoke other sessions');
    }
  }
}
