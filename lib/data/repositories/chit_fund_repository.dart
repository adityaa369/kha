import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/utils/secure_storage.dart';
import '../models/chit_fund_model.dart';
import '../models/chit_invite_model.dart';

class ChitFundRepository {
  final ApiClient _apiClient = ApiClient();

  // Create a new chit group
  Future<ChitFundModel> createChitFund({
    required String name,
    required double totalValue,
    required int totalMonths,
  }) async {
    final response = await _apiClient.post(
      '/chitfunds',
      data: {
        'name': name,
        'totalValue': totalValue,
        'totalMonths': totalMonths,
        'monthlySubscription': totalValue / totalMonths,
      },
    );
    final data = response.data;
    if (data is Map && data['chit'] != null) {
      return ChitFundModel.fromJson(data['chit']);
    }
    throw Exception('Failed to create chit: Invalid response');
  }

  // Get chits currently managed/owned
  Future<List<ChitFundModel>> getVacantChits() async {
    final response = await _apiClient.get('/chitfunds/managed');
    final data = response.data;
    final List list = (data is Map && data['chits'] is List) ? data['chits'] : [];
    return list.map((e) => ChitFundModel.fromJson(e)).toList();
  }

  Future<List<ChitFundModel>?> getCachedVacantChits() async {
    return null;
  }

  // Send invite
  Future<bool> sendInvite(String chitId, String receiverPhone) async {
    await _apiClient.post(
      '/chitfunds/$chitId/invite',
      data: {'receiverPhone': receiverPhone},
    );
    return true;
  }

  // Get pending invites for user
  Future<List<ChitInviteModel>> getMyInvites() async {
    final response = await _apiClient.get('/chitfunds/invites');
    final data = response.data;
    final List list = (data is Map && data['invites'] is List) ? data['invites'] : [];
    return list.map((e) => ChitInviteModel.fromJson(e)).toList();
  }

  Future<List<ChitInviteModel>?> getCachedMyInvites() async {
    return null;
  }

  // Get active subscriptions / joined chits
  Future<List<Map<String, dynamic>>> getMyChits() async {
    final response = await _apiClient.get('/chitfunds/joined');
    final data = response.data;
    final List list = (data is Map && data['chits'] is List) ? data['chits'] : [];
    return List<Map<String, dynamic>>.from(list);
  }

  Future<List<Map<String, dynamic>>?> getCachedMyChits() async {
    return null;
  }

  // Respond to invite
  Future<bool> respondToInvite(String inviteId, String status) async {
    if (status == 'accepted') {
      await _apiClient.post('/chitfunds/invites/$inviteId/accept', data: {});
    }
    return true;
  }

  // Declare Winner
  Future<Map<String, dynamic>> declareWinner({
    required String chitId,
    required String winnerUserId,
    required double winningDiscount,
  }) async {
    final response = await _apiClient.post(
      '/chitfunds/$chitId/declare-winner',
      data: {'winnerUserId': winnerUserId, 'winningDiscount': winningDiscount},
    );
    final data = response.data;
    return (data is Map) ? Map<String, dynamic>.from(data) : {};
  }

  // Start Chit
  Future<bool> startChitFund(String chitId) async {
    await _apiClient.post('/chitfunds/$chitId/start', data: {});
    return true;
  }

  // Submit Bid
  Future<bool> submitBid(String chitId, double discountAmount) async {
    await _apiClient.post(
      '/chitfunds/$chitId/bid',
      data: {'discountAmount': discountAmount},
    );
    return true;
  }

  // Get Bids
  Future<List<Map<String, dynamic>>> getBids(String chitId) async {
    final response = await _apiClient.get('/chitfunds/$chitId/bids');
    final data = response.data;
    final List list = (data is Map && data['bids'] is List) ? data['bids'] : [];
    return List<Map<String, dynamic>>.from(list);
  }
}
