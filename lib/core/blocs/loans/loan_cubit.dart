import 'package:flutter_bloc/flutter_bloc.dart';
import 'loan_state.dart';
import '../../../../data/models/loan_model.dart';
import '../../network/api_client.dart';

class LoanCubit extends Cubit<LoanState> {
  LoanCubit() : super(LoanInitial());

  final _api = ApiClient();

  Future<void> fetchLoans(String userId) async {
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

  Future<void> createLoan(Map<String, dynamic> loanData, String lenderId) async {
    emit(LoanLoading());
    try {
      final response = await _api.post('/loans', data: loanData);

      if (response.data['success'] == true) {
        final newLoan = LoanModel.fromJson(response.data['loan']);
        emit(LoanCreated(newLoan));
        
        // Refresh the lists
        await fetchLoans(lenderId);
      } else {
        emit(LoanError(response.data['message'] ?? 'Failed to create loan'));
      }
    } catch (e) {
      emit(LoanError('Failed to create loan: $e'));
    }
  }

  // Verify loan via OTP (Borrower)
  Future<void> verifyLoan(String loanId, String otp, String userId) async {
    emit(LoanLoading());
    try {
      final response = await _api.post('/loans/$loanId/verify', data: {'otp': otp});

      if (response.data['success'] == true) {
        // Refresh the lists
        await fetchLoans(userId);
      } else {
        emit(LoanError(response.data['message'] ?? 'Failed to verify loan'));
      }
    } catch (e) {
      emit(LoanError('Failed to verify loan: $e'));
    }
  }

  // Update payment progress (Lender)
  Future<void> updateProgress(String loanId, double progress, String userId) async {
    try {
      final response = await _api.patch('/loans/$loanId/progress', data: {'progress': progress});
      
      if (response.data['success'] == true) {
        await fetchLoans(userId);
      } else {
        emit(LoanError(response.data['message'] ?? 'Failed to update progress'));
      }
    } catch (e) {
      emit(LoanError('Failed to update progress: $e'));
    }
  }
}
