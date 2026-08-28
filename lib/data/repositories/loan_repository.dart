import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/loan_model.dart';
import '../models/portfolio_summary_model.dart';
import '../models/repayment_timeline_model.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/error/failures.dart';
import '../../core/utils/secure_storage.dart';
import 'base_repository.dart';

class LoanRepository extends BaseRepository {
  final ApiClient _api;

  LoanRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<RepaymentTimelineModel> getRepaymentTimeline(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.get('/loans/$loanId/repayment-timeline');
      if (response.data['success'] == true) {
        return RepaymentTimelineModel.fromJson(response.data);
      }
      throw ServerFailure('Failed to load repayment timeline');
    });
  }

  Future<PortfolioSummaryModel> getPortfolioSummary() async {
    return await handleApiCall(() async {
      final response = await _api.get('/loans/portfolio-summary');
      if (response.data['success'] == true && response.data['data'] != null) {
        return PortfolioSummaryModel.fromJson(response.data['data']);
      }
      throw ServerFailure('Failed to load portfolio summary');
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

  Future<bool> verifyLenderOtp(
    String loanId,
    String otp,
    String verificationId,
  ) async {
    return await handleApiCall(() async {
      final response = await _api.post(
        '/loans/$loanId/verify-lender-otp',
        data: {'otp': otp, 'verificationId': verificationId},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to verify OTP');
    });
  }

  Future<bool> closeLoan(
    String loanId,
    String otp,
    String verificationId,
  ) async {
    return await handleApiCall(() async {
      final response = await _api.post(
        '/loans/$loanId/close',
        data: {'otp': otp, 'verificationId': verificationId},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to close loan');
    });
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

  Future<bool> recordPayment(String loanId, int amount, String otp, String verificationId) async {
    return await handleApiCall(() async {
      final response = await _api.post(
        '/loans/$loanId/record-payment',
        data: {'amount': amount, 'otp': otp, 'verificationId': verificationId},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to record payment');
    });
  }

  Future<bool> recordInterest(String loanId, int amount, String otp, String verificationId) async {
    return await handleApiCall(() async {
      final response = await _api.post(
        '/loans/$loanId/record-interest',
        data: {'amount': amount, 'otp': otp, 'verificationId': verificationId},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to record interest payment');
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

  Future<bool> addCredit(String loanId, int amountPaise) async {
    return await handleApiCall(() async {
      final response = await _api.post(
        '/loans/$loanId/add-credit',
        data: {'amount': amountPaise},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
      final errMsg = (data is Map) ? data['message']?.toString() : null;
      throw ServerFailure(errMsg ?? 'Failed to add credit');
    });
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
}





