import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/chit_fund_model.dart';
import '../models/chit_invite_model.dart';

class ChitFundRepository {
  final ApiClient _apiClient = ApiClient();

  // Create a new chit group
  Future<ChitFundModel> createChitFund({
    required String name,
    required double totalValue,
    required int totalMonths,
    required double organizerFeePercent,
  }) async {
    final response = await _apiClient.post(
      '/chits/create',
      data: {
        'name': name,
        'totalValue': totalValue,
        'totalMonths': totalMonths,
        'organizerFeePercent': organizerFeePercent,
      },
    );
    return ChitFundModel.fromJson(response.data['chit']);
  }

  // Get chits currently owned/forming
  Future<List<ChitFundModel>> getVacantChits() async {
    final response = await _apiClient.get('/chits/vacant');
    final List data = response.data['chits'] ?? [];
    return data.map((e) => ChitFundModel.fromJson(e)).toList();
  }

  // Send invite
  Future<bool> sendInvite(String chitId, String receiverPhone) async {
    await _apiClient.post(
      '/chits/$chitId/invite',
      data: {'receiverPhone': receiverPhone},
    );
    return true;
  }

  // Get pending invites for user
  Future<List<ChitInviteModel>> getMyInvites() async {
    final response = await _apiClient.get('/chits/invites');
    final List data = response.data['data'] ?? [];
    return data.map((e) => ChitInviteModel.fromJson(e)).toList();
  }

  // Get active subscriptions
  Future<List<Map<String, dynamic>>> getMyChits() async {
    final response = await _apiClient.get('/chits/my');
    final List data = response.data['myChits'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  // Respond to invite
  Future<bool> respondToInvite(String inviteId, String status) async {
    await _apiClient.post(
      '/chits/invites/$inviteId/respond',
      data: {'status': status},
    );
    return true;
  }
}
