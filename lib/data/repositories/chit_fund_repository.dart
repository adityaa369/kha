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
      '/chits/create',
      data: {
        'name': name,
        'totalValue': totalValue,
        'totalMonths': totalMonths,
      },
    );
    final data = response.data;
    if (data is Map && data['chit'] != null) {
      return ChitFundModel.fromJson(data['chit']);
    }
    throw Exception('Failed to create chit: Invalid response');
  }

  // Get chits currently owned/forming
  Future<List<ChitFundModel>> getVacantChits() async {
    final response = await _apiClient.get('/chits/vacant');
    final data = response.data;
    final List list = (data is Map && data['chits'] is List) ? data['chits'] : [];
    try {
      await SecureStorage.saveCachedVacantChits(jsonEncode(list));
    } catch (_) {}
    return list.map((e) => ChitFundModel.fromJson(e)).toList();
  }

  Future<List<ChitFundModel>?> getCachedVacantChits() async {
    try {
      final cachedJsonStr = await SecureStorage.getCachedVacantChits();
      if (cachedJsonStr != null) {
        final List list = jsonDecode(cachedJsonStr);
        return list.map((e) => ChitFundModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return null;
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
    final data = response.data;
    final List list = (data is Map && data['data'] is List) ? data['data'] : [];
    try {
      await SecureStorage.saveCachedMyInvites(jsonEncode(list));
    } catch (_) {}
    return list.map((e) => ChitInviteModel.fromJson(e)).toList();
  }

  Future<List<ChitInviteModel>?> getCachedMyInvites() async {
    try {
      final cachedJsonStr = await SecureStorage.getCachedMyInvites();
      if (cachedJsonStr != null) {
        final List list = jsonDecode(cachedJsonStr);
        return list.map((e) => ChitInviteModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  // Get active subscriptions
  Future<List<Map<String, dynamic>>> getMyChits() async {
    final response = await _apiClient.get('/chits/my');
    final data = response.data;
    final List list = (data is Map && data['myChits'] is List) ? data['myChits'] : [];
    try {
      await SecureStorage.saveCachedMyChits(jsonEncode(list));
    } catch (_) {}
    return List<Map<String, dynamic>>.from(list);
  }

  Future<List<Map<String, dynamic>>?> getCachedMyChits() async {
    try {
      final cachedJsonStr = await SecureStorage.getCachedMyChits();
      if (cachedJsonStr != null) {
        final List list = jsonDecode(cachedJsonStr);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}
    return null;
  }

  // Respond to invite
  Future<bool> respondToInvite(String inviteId, String status) async {
    await _apiClient.post(
      '/chits/invites/$inviteId/respond',
      data: {'status': status},
    );
    return true;
  }

  // Get Admin Dashboard (Members & Auctions)
  Future<Map<String, dynamic>> getAdminDashboard(String chitId) async {
    final response = await _apiClient.get('/chits/$chitId/admin-dashboard');
    final data = response.data;
    return (data is Map) ? Map<String, dynamic>.from(data) : {};
  }

  // Delete Chit Fund
  Future<bool> deleteChitFund(String chitId) async {
    await _apiClient.delete('/chits/$chitId');
    return true;
  }

  // Finalize Manual Auction
  Future<Map<String, dynamic>> finalizeAuction({
    required String chitId,
    required String winnerUserId,
    required double bidDiscount,
  }) async {
    final response = await _apiClient.post(
      '/chits/$chitId/finalize-auction',
      data: {
        'winnerUserId': winnerUserId,
        'bidDiscount': bidDiscount,
      },
    );
    final data = response.data;
    return (data is Map) ? Map<String, dynamic>.from(data) : {};
  }

  // Open Auction for a month
  Future<bool> openAuctionMonth(String chitId, int monthNumber, double baseAmount) async {
    await _apiClient.post(
      '/chits/$chitId/auction/open',
      data: {
        'monthNumber': monthNumber,
        'baseAmount': baseAmount,
      },
    );
    return true;
  }

  // Submit Bid
  Future<bool> submitBid(String chitId, double bidDiscount) async {
    await _apiClient.post(
      '/chits/$chitId/auction/bid',
      data: {
        'bidDiscount': bidDiscount,
      },
    );
    return true;
  }

  // Get Bids for Month
  Future<List<Map<String, dynamic>>> getAuctionBids(String chitId, int monthNumber) async {
    final response = await _apiClient.get('/chits/$chitId/auction/$monthNumber/bids');
    final data = response.data;
    final List list = (data is Map && data['bids'] is List) ? data['bids'] : [];
    return List<Map<String, dynamic>>.from(list);
  }

  // Verify Month Payment
  Future<bool> verifyMonthPayment(String chitId, int monthNumber, String subscriberId, bool isPaid) async {
    await _apiClient.post(
      '/chits/$chitId/auction/$monthNumber/verify-payment',
      data: {
        'subscriberId': subscriberId,
        'isPaid': isPaid,
      },
    );
    return true;
  }
}
