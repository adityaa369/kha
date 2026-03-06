import 'package:flutter_bloc/flutter_bloc.dart';
import 'loan_state.dart';
import '../../../../data/models/loan_model.dart';
import '../../network/api_client.dart';

class LoanCubit extends Cubit<LoanState> {
  final ApiClient _api;

  LoanCubit({ApiClient? api}) 
      : _api = api ?? ApiClient(),
        super(LoanInitial());
  
  void clear() {
    emit(LoanInitial());
  }

  void resetError() {
    if (state is LoanError) {
      emit(LoanInitial());
    }
  }

  Future<void> fetchLoans() async {
    resetError();
    emit(LoanLoading());
    try {
      // Fetch loans where current user is borrower
      final takenResponse = await _api.get('/loans/taken');

      // Fetch loans where current user is lender
      final givenResponse = await _api.get('/loans/given');

      final myLoans = (takenResponse.data['loans'] as List)
          .map((json) => LoanModel.fromJson(json))
          .toList();

      final givenLoans = (givenResponse.data['loans'] as List)
          .map((json) => LoanModel.fromJson(json))
          .toList();

      emit(LoansLoaded(myLoans: myLoans, givenLoans: givenLoans));
    } catch (e) {
      emit(LoanError('Failed to fetch loans: $e'));
    }
  }

  Future<Map<String, dynamic>?> createLoan(Map<String, dynamic> loanData) async {
    emit(LoanLoading());
    try {
      final response = await _api.post('/loans', data: loanData);

      if (response.data['success'] == true) {
        final newLoan = LoanModel.fromJson(response.data['loan']);
        emit(LoanCreated(newLoan));
        
        // Refresh the lists
        await fetchLoans();
        return {'id': newLoan.id};
      } else {
        emit(LoanError(response.data['message'] ?? 'Failed to create loan'));
        return null;
      }
    } catch (e) {
      emit(LoanError('Failed to create loan: $e'));
      return null;
    }
  }

  // Verify loan via OTP
  Future<bool> verifyLoan(String loanId, String otp) async {
    emit(LoanLoading());
    try {
      final response = await _api.post('/loans/$loanId/verify', data: {'otp': otp});

      if (response.data['success'] == true) {
        // Refresh the lists
        await fetchLoans();
        return true;
      } else {
        emit(LoanError(response.data['message'] ?? 'Failed to verify loan'));
        return false;
      }
    } catch (e) {
      emit(LoanError('Failed to verify loan: $e'));
      return false;
    }
  }

  // Resend Loan OTP
  Future<bool> resendOtp(String loanId) async {
    try {
      final response = await _api.post('/loans/$loanId/resend-otp');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Update payment progress (Lender)
  Future<void> updateProgress(String loanId, double progress) async {
    try {
      final response = await _api.patch('/loans/$loanId/progress', data: {'progress': progress});
      
      if (response.data['success'] == true) {
        await fetchLoans();
      } else {
        emit(LoanError(response.data['message'] ?? 'Failed to update progress'));
      }
    } catch (e) {
      emit(LoanError('Failed to update progress: $e'));
    }
  }

  // Check if borrower exists
  Future<Map<String, dynamic>?> checkBorrower(String phone) async {
    try {
      final response = await _api.post('/users/check-phone', data: {'phone': phone});
      if (response.data['success'] == true && response.data['exists'] == true) {
        return response.data['user'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
