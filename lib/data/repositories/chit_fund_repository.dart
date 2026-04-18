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
  }) async {
    final response = await _apiClient.post(
      '/chits/create',
      data: {
        'name': name,
        'totalValue': totalValue,
        'totalMonths': totalMonths,
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

  // Get Admin Dashboard (Members & Auctions)
  Future<Map<String, dynamic>> getAdminDashboard(String chitId) async {
    final response = await _apiClient.get('/chits/$chitId/admin-dashboard');
    return response.data;
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
    return response.data;
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
    final List data = response.data['bids'] ?? [];
    return List<Map<String, dynamic>>.from(data);
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
