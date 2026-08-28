import 'package:flutter_bloc/flutter_bloc.dart';
import 'loan_state.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../error/failures.dart';

class LoanCubit extends Cubit<LoanState> {
  final LoanRepository _repository;

  LoanCubit({LoanRepository? repository})
    : _repository = repository ?? LoanRepository(),
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

    // 1. Load from local cache instantly if state is not already loaded
    if (state is! LoansLoaded) {
      try {
        final cachedLoans = await _repository.getCachedLoans();
        if (cachedLoans != null && state is! LoansLoaded) {
          emit(
            LoansLoaded(
              myLoans: cachedLoans['myLoans']!,
              givenLoans: cachedLoans['givenLoans']!,
            ),
          );
        } else if (state is! LoansLoaded) {
          emit(LoanLoading());
        }
      } catch (_) {
        if (state is! LoansLoaded) {
          emit(LoanLoading());
        }
      }
    }

    // 2. Fetch from server in the background
    try {
      final loans = await _repository.fetchLoans();
      emit(
        LoansLoaded(
          myLoans: loans['myLoans']!,
          givenLoans: loans['givenLoans']!,
        ),
      );
    } on Failure catch (f) {
      // Only emit error if we don't have loaded data to show
      if (state is! LoansLoaded) {
        emit(LoanError(f.message));
      }
    } catch (e) {
      if (state is! LoansLoaded) {
        emit(LoanError('Failed to fetch loans: $e'));
      }
    }
  }

  Future<Map<String, dynamic>?> createLoan(
    Map<String, dynamic> loanData,
  ) async {
    emit(LoanLoading());
    try {
      final newLoan = await _repository.createLoan(loanData);
      emit(LoanCreated(newLoan));

      // Refresh the lists
      await fetchLoans();
      return {'id': newLoan.id};
    } on Failure catch (f) {
      emit(LoanError(f.message));
      return null;
    } catch (e) {
      emit(LoanError('Failed to create loan: $e'));
      return null;
    }
  }

  // Verify/Approve loan agreement without OTP
  Future<bool> verifyLoan(String loanId) async {
    emit(LoanLoading());
    try {
      final success = await _repository.verifyLoan(loanId);
      if (success) {
        emit(const LoanVerificationSuccess());
        await fetchLoans();
      }
      return success;
    } on Failure catch (f) {
      emit(LoanError(f.message));
      return false;
    } catch (e) {
      emit(LoanError('Failed to verify loan: $e'));
      return false;
    }
  }

  // Verify Lender OTP
  
  Future<bool> deleteLoan(String loanId) async {
    try {
      await _repository.deleteLoan(loanId);
      
      if (state is LoansLoaded) {
        final current = state as LoansLoaded;
        final myLoans = current.myLoans.where((l) => l.id != loanId).toList();
        final givenLoans = current.givenLoans.where((l) => l.id != loanId).toList();
        emit(LoansLoaded(
          myLoans: myLoans,
          givenLoans: givenLoans,
        ));
      } else {
        fetchLoans(); // Refresh if we were in some other state
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyLenderOtp(
    String loanId,
    String otp,
    String verificationId,
  ) async {
    emit(LoanLoading());
    try {
      final success = await _repository.verifyLenderOtp(
        loanId,
        otp,
        verificationId,
      );
      if (success) {
        await fetchLoans();
      }
      return success;
    } on Failure catch (f) {
      emit(LoanError(f.message));
      return false;
    } catch (e) {
      emit(LoanError('Failed to verify OTP: $e'));
      return false;
    }
  }

  // Request Closure OTP
  Future<bool> requestClosureOtp(String loanId) async {
    try {
      return await _repository.requestClosureOtp(loanId);
    } on Failure catch (f) {
      emit(LoanError(f.message));
      return false;
    } catch (e) {
      emit(LoanError('Failed to request closure OTP: $e'));
      return false;
    }
  }

  // Close Loan
  Future<bool> closeLoan(
    String loanId,
    String otp,
    String verificationId,
  ) async {
    try {
      final success = await _repository.closeLoan(loanId, otp, verificationId);
      if (success) {
        await fetchLoans();
      }
      return success;
    } on Failure catch (f) {
      emit(LoanError(f.message));
      return false;
    } catch (e) {
      emit(LoanError('Failed to close loan: $e'));
      return false;
    }
  }

  Future<void> sendPaymentNudge(String loanId) async {
    try {
      // Don't emit loading state to avoid rebuilding the whole page
      await _repository.sendPaymentNudge(loanId);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> recordPayment(String loanId, int amount, String otp, String verificationId) async {
      try {
        final success = await _repository.recordPayment(loanId, amount, otp, verificationId);
        if (success) await fetchLoans();
        return success;
      } on Failure catch (f) {
        emit(LoanError(f.message));
        rethrow;
      } catch (e) {
        emit(LoanError('Failed to record payment: $e'));
        throw ServerFailure(e.toString());
      }
    }

  Future<bool> recordInterest(String loanId, int amount, String otp, String verificationId) async {
    try {
      final success = await _repository.recordInterest(loanId, amount, otp, verificationId);
      if (success) await fetchLoans();
      return success;
    } on Failure catch (f) {
      emit(LoanError(f.message));
      return false;
    } catch (e) {
      emit(LoanError('Failed to record interest payment: $e'));
      return false;
    }
  }

  Future<bool> toggleMonthStatus(String loanId, int monthIndex, String status) async {
    try {
      final success = await _repository.toggleMonthStatus(loanId, monthIndex, status);
      if (success) await fetchLoans();
      return success;
    } on Failure catch (f) {
      emit(LoanError(f.message));
      return false;
    } catch (e) {
      emit(LoanError('Failed to toggle month status: $e'));
      return false;
    }
  }

  Future<bool> addCredit(String loanId, int amountPaise) async {
      try {
        final success = await _repository.addCredit(loanId, amountPaise);
        if (success) await fetchLoans();
        return success;
      } on Failure catch (f) {
        emit(LoanError(f.message));
        rethrow;
      } catch (e) {
        emit(LoanError('Failed to add credit: $e'));
        throw ServerFailure(e.toString());
      }
    }

  // Resend Loan OTP
  Future<bool> resendOtp(String loanId) async {
    try {
      return await _repository.resendOtp(loanId);
    } catch (e) {
      return false;
    }
  }

  // Update payment progress (Lender)
  Future<void> updateProgress(String loanId, double progress) async {
    try {
      await _repository.updateProgress(loanId, progress);
      await fetchLoans();
    } on Failure catch (f) {
      emit(LoanError(f.message));
    } catch (e) {
      emit(LoanError('Failed to update progress: $e'));
    }
  }

  // Check if borrower exists
  Future<Map<String, dynamic>?> checkBorrower(String phone) async {
    try {
      final user = await _repository.checkBorrower(phone);
      if (user != null) {
        return user.toJson();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Upload document
  Future<String> uploadDocument(
    String fileName,
    String fileType,
    List<int> fileBytes,
  ) async {
    try {
      return await _repository.uploadDocument(fileName, fileType, fileBytes);
    } on Failure catch (f) {
      emit(LoanError(f.message));
      rethrow;
    } catch (e) {
      emit(LoanError('Failed to upload document: $e'));
      rethrow;
    }
  }
}



