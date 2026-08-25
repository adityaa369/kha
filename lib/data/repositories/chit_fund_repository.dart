import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/secure_storage.dart';
import '../models/chit_fund_model.dart';
import '../models/chit_invite_model.dart';

class ChitFundRepository {
  final ApiClient _apiClient = ApiClient();

  // ─── Create ─────────────────────────────────────────────────────────────────

  Future<ChitFundModel> createChitFund({
    required String name,
    required double totalValue,
    required int totalMonths,
    double commissionPercent = 5.0,
    String branchName = 'KPHB-CAO',
  }) async {
    final response = await _apiClient.post(
      '/chitfunds',
      data: {
        'name': name,
        'totalValue': totalValue,
        'totalMonths': totalMonths,
        'monthlySubscription': totalValue / totalMonths,
        'commissionPercentage': commissionPercent,
        'branchName': branchName,
      },
    );
    final data = response.data;
    if (data is Map && data['chit'] != null) {
      return ChitFundModel.fromJson(data['chit']);
    }
    throw Exception('Failed to create chit: Invalid response');
  }

  // ─── Fetch Managed / Owned ───────────────────────────────────────────────────

  Future<List<ChitFundModel>> getVacantChits() async {
    final response = await _apiClient.get('/chitfunds/managed');
    final data = response.data;
    final List list = (data is Map && data['chits'] is List) ? data['chits'] : [];
    final result = list.map((e) => ChitFundModel.fromJson(e)).toList();
    // Cache to secure storage
    await SecureStorage.saveCachedVacantChits(jsonEncode(list));
    return result;
  }

  Future<List<ChitFundModel>?> getCachedVacantChits() async {
    try {
      final cached = await SecureStorage.getCachedVacantChits();
      if (cached == null) return null;
      final List list = await compute((String s) => jsonDecode(s) as List, cached);
      return list.map((e) => ChitFundModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // ─── Invite ──────────────────────────────────────────────────────────────────

  Future<bool> sendInvite(String chitId, String receiverPhone) async {
    await _apiClient.post(
      '/chitfunds/$chitId/invite',
      data: {'receiverPhone': receiverPhone},
    );
    return true;
  }

  Future<List<ChitInviteModel>> getMyInvites() async {
    final response = await _apiClient.get('/chitfunds/invites');
    final data = response.data;
    final List list = (data is Map && data['invites'] is List) ? data['invites'] : [];
    final result = list.map((e) => ChitInviteModel.fromJson(e)).toList();
    await SecureStorage.saveCachedMyInvites(jsonEncode(list));
    return result;
  }

  Future<List<ChitInviteModel>?> getCachedMyInvites() async {
    try {
      final cached = await SecureStorage.getCachedMyInvites();
      if (cached == null) return null;
      final List list = await compute((String s) => jsonDecode(s) as List, cached);
      return list.map((e) => ChitInviteModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // ─── Joined Chits ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyChits() async {
    final response = await _apiClient.get('/chitfunds/joined');
    final data = response.data;
    final List list = (data is Map && data['chits'] is List) ? data['chits'] : [];
    final result = List<Map<String, dynamic>>.from(list);
    await SecureStorage.saveCachedMyChits(jsonEncode(result));
    return result;
  }

  Future<List<Map<String, dynamic>>?> getCachedMyChits() async {
    try {
      final cached = await SecureStorage.getCachedMyChits();
      if (cached == null) return null;
      final List list = await compute((String s) => jsonDecode(s) as List, cached);
      return List<Map<String, dynamic>>.from(list);
    } catch (_) {
      return null;
    }
  }

  // ─── Invite Response ─────────────────────────────────────────────────────────

  Future<bool> respondToInvite(String inviteId, String status) async {
    if (status == 'accepted') {
      await _apiClient.post('/chitfunds/invites/$inviteId/accept', data: {});
    } else {
      await _apiClient.post('/chitfunds/invites/$inviteId/decline', data: {});
    }
    return true;
  }

  // ─── Admin Dashboard ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminDashboard(String chitId) async {
    final response = await _apiClient.get('/chitfunds/$chitId');
    final data = response.data;
    return (data is Map) ? Map<String, dynamic>.from(data) : {};
  }

  // ─── Member Detail (member's own view) ───────────────────────────────────────

  Future<Map<String, dynamic>> getMemberDetail(String chitId) async {
    final response = await _apiClient.get('/chitfunds/$chitId/member-detail');
    final data = response.data;
    return (data is Map) ? Map<String, dynamic>.from(data) : {};
  }

  // ─── Chit Lifecycle ──────────────────────────────────────────────────────────

  Future<bool> startChitFund(String chitId) async {
    await _apiClient.post('/chitfunds/$chitId/start', data: {});
    return true;
  }

  Future<bool> deleteChitFund(String chitId) async {
    await _apiClient.delete('/chitfunds/$chitId');
    return true;
  }

  // ─── Auction ─────────────────────────────────────────────────────────────────

  /// Opens the auction for a specific month — sends FCM to all members
  Future<bool> openAuctionMonth(
    String chitId,
    int monthNumber,
    double baseAmount,
  ) async {
    await _apiClient.post(
      '/chitfunds/$chitId/open-auction-month',
      data: {
        'monthNumber': monthNumber,
        'baseAmount': baseAmount,
      },
    );
    return true;
  }

  Future<bool> submitBid(String chitId, double discountAmount) async {
    await _apiClient.post(
      '/chitfunds/$chitId/bid',
      data: {'discountAmount': discountAmount},
    );
    return true;
  }

  Future<List<Map<String, dynamic>>> getBids(String chitId) async {
    final response = await _apiClient.get('/chitfunds/$chitId/bids');
    final data = response.data;
    final List list = (data is Map && data['bids'] is List) ? data['bids'] : [];
    return List<Map<String, dynamic>>.from(list);
  }

  Future<List<Map<String, dynamic>>> getAuctionBids(
    String chitId,
    int monthNumber,
  ) async {
    return getBids(chitId);
  }

  Future<Map<String, dynamic>> finalizeAuction({
    required String chitId,
    required String winnerUserId,
    required double bidDiscount,
  }) async {
    final response = await _apiClient.post(
      '/chitfunds/$chitId/declare-winner',
      data: {'winnerUserId': winnerUserId, 'winningDiscount': bidDiscount},
    );
    final data = response.data;
    return (data is Map) ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> declareWinner({
    required String chitId,
    required String winnerUserId,
    required double winningDiscount,
  }) async {
    return finalizeAuction(
      chitId: chitId,
      winnerUserId: winnerUserId,
      bidDiscount: winningDiscount,
    );
  }

  // ─── Payment Verification (Owner marks payment) ───────────────────────────────

  Future<bool> verifyMonthPayment(
    String chitId,
    int monthNumber,
    String subscriberId,
    bool isPaid,
  ) async {
    await _apiClient.post(
      '/chitfunds/$chitId/verify-payment',
      data: {
        'monthNumber': monthNumber,
        'subscriberId': subscriberId,
        'isPaid': isPaid,
      },
    );
    return true;
  }
}

