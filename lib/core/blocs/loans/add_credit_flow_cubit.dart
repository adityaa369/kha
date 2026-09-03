import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../error/failures.dart';

abstract class AddCreditFlowState extends Equatable {
  const AddCreditFlowState();
  @override
  List<Object?> get props => [];
}

class AddCreditIdle extends AddCreditFlowState {}

class AddCreditCreatingIntent extends AddCreditFlowState {}

class AddCreditAwaitingConsent extends AddCreditFlowState {
  final String intentId;
  final double amountRupees;
  const AddCreditAwaitingConsent(this.intentId, this.amountRupees);

  @override
  List<Object?> get props => [intentId, amountRupees];
}

class AddCreditAuthorizing extends AddCreditFlowState {
  final String intentId;
  final double amountRupees;
  const AddCreditAuthorizing(this.intentId, this.amountRupees);
  
  @override
  List<Object?> get props => [intentId, amountRupees];
}

class AddCreditCommitting extends AddCreditFlowState {
  final String intentId;
  final double amountRupees;
  const AddCreditCommitting(this.intentId, this.amountRupees);
  
  @override
  List<Object?> get props => [intentId, amountRupees];
}

class AddCreditSuccess extends AddCreditFlowState {}

class AddCreditRejectedState extends AddCreditFlowState {
  final Failure failure;
  const AddCreditRejectedState(this.failure);

  @override
  List<Object?> get props => [failure];
}

class AddCreditFlowCubit extends Cubit<AddCreditFlowState> {
  final LoanRepository _repository;
  final String _loanId;

  AddCreditFlowCubit({
    required LoanRepository repository,
    required String loanId,
    String? initialIntentId,
    double? initialAmountRupees,
  }) : _repository = repository,
       _loanId = loanId,
       super(initialIntentId != null && initialAmountRupees != null 
         ? AddCreditAwaitingConsent(initialIntentId, initialAmountRupees) 
         : AddCreditIdle());

  void reset() => emit(AddCreditIdle());

// 4F-4G: Fetch Intent for Deep Linking
  Future<void> loadIntent(String intentId) async {
    emit(AddCreditCreatingIntent()); // Reusing loading state
    try {
      final intent = await _repository.getIntent(intentId);
      
      if (intent.action != 'ADD_CREDIT') {
        emit(const AddCreditRejectedState(BusinessLogicFailure('INVALID_INTENT_TYPE')));
        return;
      }
      
      if (intent.status == 'CONSUMED' || intent.status == 'COMMITTED') {
        emit(const AddCreditRejectedState(IntentConsumedFailure()));
      } else if (intent.status == 'EXPIRED') {
        emit(const AddCreditRejectedState(BusinessLogicFailure('INTENT_EXPIRED')));
      } else if (intent.status == 'REJECTED') {
        emit(const AddCreditRejectedState(BusinessLogicFailure('INTENT_REJECTED')));
      } else if (intent.status == 'PENDING') {
        final amountRupees = (intent.payload['amountPaise'] ?? 0) / 100.0;
        emit(AddCreditAwaitingConsent(intentId, amountRupees));
      } else {
        emit(const AddCreditRejectedState(ServerFailure('Unknown intent status')));
      }
    } on DioException catch (e) {
      emit(AddCreditRejectedState(_mapDioErrorToFailure(e)));
    } on Failure catch (f) {
      emit(AddCreditRejectedState(f));
    } catch (e) {
      emit(AddCreditRejectedState(ServerFailure(e.toString())));
    }
  }

  // Lender Action: Create Intent
  Future<void> createIntent(double amountRupees) async {
    if (state is! AddCreditIdle) return;
    
    emit(AddCreditCreatingIntent());
    
    try {
      final intentId = await _repository.createAddCreditIntent(
        loanId: _loanId, 
        amountRupees: amountRupees,
      );
      emit(AddCreditAwaitingConsent(intentId, amountRupees));
    } on DioException catch (e) {
      emit(AddCreditRejectedState(_mapDioErrorToFailure(e)));
    } on Failure catch (f) {
      emit(AddCreditRejectedState(f));
    } catch (e) {
      emit(AddCreditRejectedState(ServerFailure(e.toString())));
    }
  }

  // Borrower Action: Authorize and Commit
  Future<void> approveIntent() async {
    if (state is! AddCreditAwaitingConsent) return;
    
    final currentState = state as AddCreditAwaitingConsent;
    final intentId = currentState.intentId;
    final amountRupees = currentState.amountRupees;
    
    emit(AddCreditAuthorizing(intentId, amountRupees));
    
    try {
      // The idToken is fetched inside the repository during addCredit
      emit(AddCreditCommitting(intentId, amountRupees));
      
      final success = await _repository.commitAddCredit(
        loanId: _loanId, 
        intentId: intentId,
        amountRupees: amountRupees,
      );
      
      if (success) {
        emit(AddCreditSuccess());
      } else {
        emit(const AddCreditRejectedState(ServerFailure('Commit failed')));
      }
    } on TimeoutException {
      // For Add Credit, we do not auto-recreate intent.
      // Reconcile the existing intent.
      await reconcile(intentId, amountRupees);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.sendTimeout) {
        await reconcile(intentId, amountRupees);
      } else {
        emit(AddCreditRejectedState(_mapDioErrorToFailure(e)));
      }
    } on Failure catch (f) {
      emit(AddCreditRejectedState(f));
    } catch (e) {
      emit(AddCreditRejectedState(ServerFailure(e.toString())));
    }
  }

  // Reconcile network unknowns
  Future<void> reconcile(String intentId, double amountRupees) async {
    try {
      final status = await _repository.checkIntentStatus(intentId);
      if (status == 'CONSUMED' || status == 'COMMITTED') {
        emit(AddCreditSuccess());
      } else if (status == 'PENDING') {
        // Safe to retry commit
        emit(AddCreditAwaitingConsent(intentId, amountRupees));
      } else if (status == 'EXPIRED') {
        emit(const AddCreditRejectedState(BusinessLogicFailure('INTENT_EXPIRED')));
      } else if (status == 'REJECTED') {
        emit(const AddCreditRejectedState(BusinessLogicFailure('INTENT_REJECTED')));
      } else {
        emit(const AddCreditRejectedState(ServerFailure('Unknown intent status')));
      }
    } catch (e) {
      // If we can't reconcile, remain in an error state to let user retry reconciliation manually or fail gracefully
      emit(const AddCreditRejectedState(NetworkFailure()));
    }
  }

  // Borrower Action: Reject Intent
  Future<void> rejectIntent() async {
    if (state is! AddCreditAwaitingConsent) return;
    
    final intentId = (state as AddCreditAwaitingConsent).intentId;
    emit(AddCreditCommitting(intentId, 0)); // Rejecting
    
    try {
      // Optional backend reject endpoint, or just drop it. 
      // The rules say "Rejected intent causes zero financial delta"
      // If backend models it:
      await _repository.rejectIntent(intentId);
      emit(AddCreditSuccess()); // Success in rejecting
    } catch (e) {
      // Even if network fails, we don't care, it will expire
      emit(AddCreditSuccess());
    }
  }

  Failure _mapDioErrorToFailure(DioException e) {
    if (e.response?.data is Map && e.response?.data['code'] != null) {
      final code = e.response?.data['code'] as String;
      switch (code) {
        case 'INTENT_EXPIRED': return const BusinessLogicFailure('INTENT_EXPIRED');
        case 'INTENT_CONSUMED': return const IntentConsumedFailure();
        case 'LOAN_FROZEN': return const BusinessLogicFailure('LOAN_FROZEN');
        case 'TERMINAL_STATE': return const BusinessLogicFailure('TERMINAL_STATE');
        case 'UNAUTHORIZED_ACTION': return const BusinessLogicFailure('UNAUTHORIZED_ACTION');
        case 'VALIDATION_ERROR': return const ValidationFailure('VALIDATION_ERROR');
      }
    }
    return const NetworkFailure();
  }
}
