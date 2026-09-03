import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/loan_model.dart';
import '../models/interest_schedule_model.dart';
import '../models/portfolio_summary_model.dart';
import '../models/repayment_timeline_model.dart';
import '../models/user_model.dart';
import '../models/intent_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/error/failures.dart';
import '../../core/utils/secure_storage.dart';
import 'base_repository.dart';


class DocumentResponse {
  final String url;
  final String contentType;
  DocumentResponse({required this.url, required this.contentType});
}

class LoanRepository extends BaseRepository {
  final ApiClient _api;

  LoanRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<RepaymentTimelineModel> getRepaymentTimeline(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.get('/loans/$loanId/repayment-timeline');
      if (response.data['success'] == true) {
        return RepaymentTimelineModel.fromJson(response.data);
      }
      throw const ServerFailure('Failed to load repayment timeline');
    });
  }

  Future<PortfolioSummaryModel> getPortfolioSummary() async {
    return await handleApiCall(() async {
      final response = await _api.get('/loans/portfolio-summary');
      if (response.data['success'] == true && response.data['data'] != null) {
        return PortfolioSummaryModel.fromJson(response.data['data']);
      }
      throw const ServerFailure('Failed to load portfolio summary');
    });
  }


  Future<LoanModel> getLoanById(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.get('/loans/$loanId');
      if (response.data != null && response.data['success'] == true) {
        return LoanModel.fromJson(response.data['loan']);
      }
      throw const ServerFailure('Failed to load loan');
    });
  }

  Future<Map<String, List<LoanModel>>> fetchLoans() async {
    return await handleApiCall(() async {
      final takenResponse = await _api.get('/loans/taken');
      final givenResponse = await _api.get('/loans/given');

      final takenData = takenResponse.data;
      final givenData = givenResponse.data;

      final List takenList = (takenData is Map && takenData['loans'] is List)
          ? takenData['loans']
          : [];
      final List givenList = (givenData is Map && givenData['loans'] is List)
          ? givenData['loans']
          : [];

      // Save raw JSON representation to SecureStorage for caching
      try {
        final cacheMap = {'myLoans': takenList, 'givenLoans': givenList};
        await SecureStorage.saveCachedLoans(jsonEncode(cacheMap));
      } catch (e) {
        // Silent failure for caching write
      }

      final myLoans = takenList
          .map((json) => LoanModel.fromJson(json))
          .toList();

      final givenLoans = givenList
          .map((json) => LoanModel.fromJson(json))
          .toList();

      // Real loans are fetched from backend â€” no mock data needed
      return {'myLoans': myLoans, 'givenLoans': givenLoans};
    });
  }

  Future<Map<String, List<LoanModel>>?> getCachedLoans() async {
    try {
      final cachedJsonStr = await SecureStorage.getCachedLoans();
      if (cachedJsonStr != null) {
        final Map<String, dynamic> cachedMap = await compute(
          (String s) => jsonDecode(s) as Map<String, dynamic>, cachedJsonStr);
        final List myLoansJson = cachedMap['myLoans'] ?? [];
        final List givenLoansJson = cachedMap['givenLoans'] ?? [];

        final myLoans = myLoansJson
            .map((json) => LoanModel.fromJson(json))
            .toList();
        final givenLoans = givenLoansJson
            .map((json) => LoanModel.fromJson(json))
            .toList();

        return {'myLoans': myLoans, 'givenLoans': givenLoans};
      }
    } catch (_) {}
    return null;
  }

  Future<LoanModel> createLoan(Map<String, dynamic> loanData) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans', data: loanData);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return LoanModel.fromJson(data['loan']);
      }
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to create loan');
    });
  }

  Future<bool> verifyLoan(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans/$loanId/verify', data: {});
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to verify loan');
    });
  }

    Future<void> deleteLoan(String loanId) async {
    final response = await _api.delete('/loans/$loanId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete loan');
    }
  }

    @visibleForTesting
  Future<String> getValidIdToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const AuthFailure('No Firebase session found');
    final token = await user.getIdToken(forceRefresh);
    if (token == null) throw const AuthFailure('Failed to generate Firebase token');
    return token;
  }

  Future<bool> verifyLenderOtp(String loanId) async {
    return await handleApiCall(() async {
      try {
        final idToken = await getValidIdToken();
        final response = await _api.post(
          '/loans/$loanId/verify-lender-otp',
          data: {'idToken': idToken},
        );
        if (response.data['success'] == true) return true;
        throw ServerFailure(response.data['message']?.toString() ?? 'Failed to verify');
      } on DioException catch (e) {
        if (e.response?.statusCode == 400 && e.response?.data['message'] == 'Invalid idToken') {
          final newToken = await getValidIdToken(forceRefresh: true);
          final retryOpts = e.requestOptions;
          retryOpts.data = {'idToken': newToken};
          final retryResponse = await _api.dio.fetch(retryOpts);
          if (retryResponse.data['success'] == true) return true;
        }
        rethrow;
      }
    });
  }

    // Deprecated direct closeLoan, now uses intent flow via CloseLoanFlowCubit
  Future<bool> closeLoan(String loanId) async {
    throw UnimplementedError("closeLoan must now use the Two-Stage intent flow.");
  }

  Future<bool> requestClosureOtp(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans/$loanId/close-otp', data: {});
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to request closure OTP');
    });
  }

  Future<bool> resendOtp(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans/$loanId/resend-otp');
      final data = response.data;
      return data is Map && data['success'] == true;
    });
  }

  Future<void> sendPaymentNudge(String loanId) async {
    try {
      final response = await ApiClient().post(
        '/loans/$loanId/payment-nudge',
        data: {},
      );
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to send nudge');
      }
    } catch (e) {
      if (e.toString().contains('429') || e.toString().contains('recently')) {
        throw Exception('A payment nudge was already sent recently. Please wait 24 hours.');
      }
      rethrow;
    }
  }

    Future<bool> recordPayment(String loanId, {required double amountRupees, String? idempotencyKey}) async {
    return await handleApiCall(() async {
      try {
        final idToken = await getValidIdToken();
        final options = idempotencyKey != null 
          ? Options(headers: {'x-idempotency-key': idempotencyKey}) 
          : null;
        
        final response = await _api.post(
          '/loans/$loanId/record-payment',
          data: {'amount': amountRupees, 'idToken': idToken},
          options: options,
        );
        if (response.data['success'] == true) return true;
        throw ServerFailure(response.data['message']?.toString() ?? 'Failed to record payment');
      } on DioException catch (e) {
        if (e.response?.statusCode == 400 && e.response?.data['message'] == 'Invalid idToken') {
          final newToken = await getValidIdToken(forceRefresh: true);
          final retryOpts = e.requestOptions;
          retryOpts.data = {'amount': amountRupees, 'idToken': newToken};
          final retryResponse = await _api.dio.fetch(retryOpts);
          if (retryResponse.data['success'] == true) return true;
        }
        rethrow;
      }
    });
  }

    
  Future<bool> toggleMonthStatus(String loanId, int monthIndex, String status) async {
    return await handleApiCall(() async {
      final response = await _api.patch(
        '/loans/$loanId/months/$monthIndex',
        data: {'status': status},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to toggle month status');
    });
  }

    // Deprecated direct addCredit, now uses intent flow
  Future<bool> addCredit(String loanId, {required double amountRupees}) async {
    throw UnimplementedError("addCredit must now use the Two-Stage intent flow.");
  }

  Future<bool> updateProgress(String loanId, double progress) async {
    return await handleApiCall(() async {
      final response = await _api.patch(
        '/loans/$loanId/progress',
        data: {'progress': progress},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to update progress');
    });
  }

  Future<UserModel?> checkBorrower(String phone) async {
    return await handleApiCall(() async {
      final response = await _api.post(
        '/users/check-phone',
        data: {'phone': phone},
      );
      final data = response.data;
      if (data is Map && data['success'] == true && data['exists'] == true) {
        return UserModel.fromJson(data['user']);
      }
      return null;
    });
  }



  Future<InterestScheduleModel> getInterestSchedule(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.get('/loans/$loanId/interest-schedule');
      if (response.statusCode == 200) {
        return InterestScheduleModel.fromJson(response.data);
      }
      throw const ServerFailure('Failed to fetch interest schedule');
    });
  }

Future<DocumentResponse> getSignedDocumentUrl(String documentId) async {
    return await handleApiCall(() async {
      final response = await _api.get('/documents/$documentId');
      if (response.statusCode == 200) {
        return DocumentResponse(
          url: response.data['url'] as String,
          contentType: response.data['contentType'] as String? ?? 'application/octet-stream',
        );
      }
      throw const ServerFailure('Failed to get document URL');
    });
  }

  Future<String> uploadDocument(
    String fileName,
    String fileType,
    List<int> fileBytes,
  ) async {
    return await handleApiCall(() async {
      final base64Data = base64Encode(fileBytes);
      final response = await _api.post(
        '/loans/upload-document',
        data: {
          'fileName': fileName,
          'fileType': fileType,
          'base64Data': base64Data,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return data['url']?.toString() ?? '';
      }
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to upload document');
    });
  }


Future<IntentModel> getIntent(String intentId) async {
    return await handleApiCall(() async {
      final response = await _api.get('/intents/$intentId');
      if (response.data != null && response.data['success'] == true) {
        return IntentModel.fromJson(response.data['intent']);
      }
      throw const ServerFailure('Failed to fetch intent');
    });
  }

  Future<String> createAddCreditIntent({required String loanId, required double amountRupees}) async {
    return await handleApiCall(() async {
      final idToken = await getValidIdToken();
      final response = await _api.post(
        '/intents',
        data: {
          'loanId': loanId,
          'action': 'ADD_CREDIT',
          'amountPaise': (amountRupees * 100).toInt(),
          'idToken': idToken,
        },
      );
      if (response.statusCode == 201) {
        return response.data['intentId'] as String;
      }
      throw const ServerFailure('Failed to create intent');
    });
  }

  Future<bool> commitAddCredit({required String loanId, required String intentId, required double amountRupees}) async {
    return await handleApiCall(() async {
      try {
        final idToken = await getValidIdToken();
        // Uses the same generic ApiClient post with intentId to commit
        final response = await _api.post(
          '/loans/$loanId/add-credit',
          data: {'intentId': intentId, 'amount': amountRupees, 'idToken': idToken},
        );
        return response.statusCode == 200;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 && e.response?.data['code'] == 'INVALID_TOKEN') {
          // Token refresh retry
          final newToken = await getValidIdToken(forceRefresh: true);
          final retryOpts = e.requestOptions;
          retryOpts.data = {'intentId': intentId, 'amount': amountRupees, 'idToken': newToken};
          final retryResponse = await _api.dio.fetch(retryOpts);
          if (retryResponse.data['success'] == true) return true;
        }
        rethrow;
      }
    });
  }


  Future<String> createCloseIntent({required String loanId}) async {
    return await handleApiCall(() async {
      final idToken = await getValidIdToken();
      final response = await _api.post(
        '/intents',
        data: {
          'loanId': loanId,
          'action': 'CLOSE_LOAN',
          'idToken': idToken,
        },
      );
      if (response.statusCode == 201) {
        return response.data['intentId'] as String;
      }
      throw const ServerFailure('Failed to create close intent');
    });
  }

  Future<bool> commitClose({required String loanId, required String intentId}) async {
    return await handleApiCall(() async {
      try {
        final idToken = await getValidIdToken();
        final response = await _api.post(
          '/loans/$loanId/close',
          data: {'intentId': intentId, 'idToken': idToken},
        );
        return response.statusCode == 200;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 && e.response?.data['code'] == 'INVALID_TOKEN') {
          final newToken = await getValidIdToken(forceRefresh: true);
          final retryOpts = e.requestOptions;
          retryOpts.data = {'intentId': intentId, 'idToken': newToken};
          final retryResponse = await _api.dio.fetch(retryOpts);
          if (retryResponse.data['success'] == true) return true;
        }
        rethrow;
      }
    });
  }

  Future<String> checkIntentStatus(String intentId) async {
    return await handleApiCall(() async {
      // Mocked endpoint behavior based on typical Intent status query
      final response = await _api.get('/intents/$intentId/status');
      if (response.statusCode == 200) {
        return response.data['status'] as String;
      }
      throw const ServerFailure('Failed to check intent status');
    });
  }

  Future<void> rejectIntent(String intentId) async {
    await handleApiCall(() async {
      final idToken = await getValidIdToken();
      await _api.post('/intents/$intentId/reject', data: {'idToken': idToken});
    });
  }

  Future<String> checkTransactionStatus(String idempotencyKey) async {
    return await handleApiCall(() async {
      final response = await _api.get('/transactions/status/$idempotencyKey');
      if (response.statusCode == 200) {
        return response.data['status'] as String;
      }
      throw const ServerFailure('Failed to check transaction status');
    });
  }
}