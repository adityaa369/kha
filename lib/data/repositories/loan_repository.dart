import '../models/loan_model.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/error/failures.dart';
import 'base_repository.dart';

class LoanRepository extends BaseRepository {
  final ApiClient _api;

  LoanRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<Map<String, List<LoanModel>>> fetchLoans() async {
    return await handleApiCall(() async {
      final takenResponse = await _api.get('/loans/taken');
      final givenResponse = await _api.get('/loans/given');

      final myLoans = (takenResponse.data['loans'] as List)
          .map((json) => LoanModel.fromJson(json))
          .toList();

      final givenLoans = (givenResponse.data['loans'] as List)
          .map((json) => LoanModel.fromJson(json))
          .toList();

      return {'myLoans': myLoans, 'givenLoans': givenLoans};
    });
  }

  Future<LoanModel> createLoan(Map<String, dynamic> loanData) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans', data: loanData);
      if (response.data['success'] == true) {
        return LoanModel.fromJson(response.data['loan']);
      }
      throw ServerFailure(response.data['message'] ?? 'Failed to create loan');
    });
  }

  Future<bool> verifyLoan(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans/$loanId/verify', data: {});
      if (response.data['success'] == true) return true;
      throw ServerFailure(response.data['message'] ?? 'Failed to verify loan');
    });
  }

  Future<bool> verifyLenderOtp(String loanId, String otp) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans/$loanId/verify-lender-otp', data: {'otp': otp});
      if (response.data['success'] == true) return true;
      throw ServerFailure(response.data['message'] ?? 'Failed to verify OTP');
    });
  }

  Future<bool> closeLoan(String loanId, String otp) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans/$loanId/close', data: {'otp': otp});
      if (response.data['success'] == true) return true;
      throw ServerFailure(response.data['message'] ?? 'Failed to close loan');
    });
  }

  Future<bool> requestClosureOtp(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans/$loanId/close-otp', data: {});
      if (response.data['success'] == true) return true;
      throw ServerFailure(response.data['message'] ?? 'Failed to request closure OTP');
    });
  }

  Future<bool> resendOtp(String loanId) async {
    return await handleApiCall(() async {
      final response = await _api.post('/loans/$loanId/resend-otp');
      return response.data['success'] == true;
    });
  }

  Future<bool> updateProgress(String loanId, double progress) async {
    return await handleApiCall(() async {
      final response = await _api.patch('/loans/$loanId/progress', data: {'progress': progress});
      if (response.data['success'] == true) return true;
      throw ServerFailure(response.data['message'] ?? 'Failed to update progress');
    });
  }

  Future<UserModel?> checkBorrower(String phone) async {
    return await handleApiCall(() async {
      final response = await _api.post('/users/check-phone', data: {'phone': phone});
      if (response.data['success'] == true && response.data['exists'] == true) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    });
  }
}