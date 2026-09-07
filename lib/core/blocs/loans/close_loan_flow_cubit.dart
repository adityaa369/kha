import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../error/failures.dart';

abstract class CloseLoanFlowState extends Equatable {
  const CloseLoanFlowState();
  @override
  List<Object?> get props => [];
}

class CloseLoanIdle extends CloseLoanFlowState {}

class CloseLoanCreatingIntent extends CloseLoanFlowState {}

class CloseLoanAwaitingConsent extends CloseLoanFlowState {
  final String intentId;
  const CloseLoanAwaitingConsent(this.intentId);

  @override
  List<Object?> get props => [intentId];
}

class CloseLoanAuthorizing extends CloseLoanFlowState {
  final String intentId;
  const CloseLoanAuthorizing(this.intentId);

  @override
  List<Object?> get props => [intentId];
}

class CloseLoanCommitting extends CloseLoanFlowState {
  final String intentId;
  const CloseLoanCommitting(this.intentId);

  @override
  List<Object?> get props => [intentId];
}

class CloseLoanSuccess extends CloseLoanFlowState {}

class CloseLoanRejectedState extends CloseLoanFlowState {
  final Failure failure;
  const CloseLoanRejectedState(this.failure);

  @override
  List<Object?> get props => [failure];
}

class CloseLoanFlowCubit extends Cubit<CloseLoanFlowState> {
  final LoanRepository _repository;
  final String _loanId;

  CloseLoanFlowCubit({
    required LoanRepository repository,
    required String loanId,
    String? initialIntentId,
  }) : _repository = repository,
       _loanId = loanId,
       super(
         initialIntentId != null
             ? CloseLoanAwaitingConsent(initialIntentId)
             : CloseLoanIdle(),
       );

  void reset() => emit(CloseLoanIdle());

  // 4F-4G: Fetch Intent for Deep Linking
  Future<void> loadIntent(String intentId) async {
    emit(CloseLoanCreatingIntent()); // Reusing loading state
    try {
      final intent = await _repository.getIntent(intentId);

      if (intent.action != 'CLOSE_LOAN') {
        emit(
          const CloseLoanRejectedState(
            BusinessLogicFailure('INVALID_INTENT_TYPE'),
          ),
        );
        return;
      }

      if (intent.status == 'CONSUMED' || intent.status == 'COMMITTED') {
        emit(const CloseLoanRejectedState(IntentConsumedFailure()));
      } else if (intent.status == 'EXPIRED') {
        emit(
          const CloseLoanRejectedState(BusinessLogicFailure('INTENT_EXPIRED')),
        );
      } else if (intent.status == 'REJECTED') {
        emit(
          const CloseLoanRejectedState(BusinessLogicFailure('INTENT_REJECTED')),
        );
      } else if (intent.status == 'PENDING') {
        emit(CloseLoanAwaitingConsent(intentId));
      } else {
        emit(
          const CloseLoanRejectedState(ServerFailure('Unknown intent status')),
        );
      }
    } on DioException catch (e) {
      emit(CloseLoanRejectedState(_mapDioErrorToFailure(e)));
    } on Failure catch (f) {
      emit(CloseLoanRejectedState(f));
    } catch (e) {
      emit(CloseLoanRejectedState(ServerFailure(e.toString())));
    }
  }

  // Lender Action: Create Intent
  Future<void> createIntent() async {
    if (state is! CloseLoanIdle) return;

    emit(CloseLoanCreatingIntent());

    try {
      final intentId = await _repository.createCloseIntent(loanId: _loanId);
      emit(CloseLoanAwaitingConsent(intentId));
    } on DioException catch (e) {
      emit(CloseLoanRejectedState(_mapDioErrorToFailure(e)));
    } on Failure catch (f) {
      emit(CloseLoanRejectedState(f));
    } catch (e) {
      emit(CloseLoanRejectedState(ServerFailure(e.toString())));
    }
  }

  // Borrower Action: Authorize and Commit
  Future<void> approveIntent() async {
    if (state is! CloseLoanAwaitingConsent) return;

    final intentId = (state as CloseLoanAwaitingConsent).intentId;

    emit(CloseLoanAuthorizing(intentId));

    try {
      emit(CloseLoanCommitting(intentId));

      final success = await _repository.commitClose(
        loanId: _loanId,
        intentId: intentId,
      );

      if (success) {
        emit(CloseLoanSuccess());
      } else {
        emit(const CloseLoanRejectedState(ServerFailure('Commit failed')));
      }
    } on TimeoutException {
      await reconcile(intentId);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        await reconcile(intentId);
      } else {
        emit(CloseLoanRejectedState(_mapDioErrorToFailure(e)));
      }
    } on Failure catch (f) {
      emit(CloseLoanRejectedState(f));
    } catch (e) {
      emit(CloseLoanRejectedState(ServerFailure(e.toString())));
    }
  }

  // Reconcile network unknowns
  Future<void> reconcile(String intentId) async {
    try {
      final status = await _repository.checkIntentStatus(intentId);
      if (status == 'CONSUMED' || status == 'COMMITTED') {
        emit(CloseLoanSuccess());
      } else if (status == 'PENDING') {
        emit(CloseLoanAwaitingConsent(intentId));
      } else if (status == 'EXPIRED') {
        emit(
          const CloseLoanRejectedState(BusinessLogicFailure('INTENT_EXPIRED')),
        );
      } else if (status == 'REJECTED') {
        emit(
          const CloseLoanRejectedState(BusinessLogicFailure('INTENT_REJECTED')),
        );
      } else {
        emit(
          const CloseLoanRejectedState(ServerFailure('Unknown intent status')),
        );
      }
    } catch (e) {
      emit(const CloseLoanRejectedState(NetworkFailure()));
    }
  }

  // Borrower Action: Reject Intent
  Future<void> rejectIntent() async {
    if (state is! CloseLoanAwaitingConsent) return;
    final intentId = (state as CloseLoanAwaitingConsent).intentId;
    emit(CloseLoanCommitting(intentId)); // Re-using for processing state

    try {
      await _repository.rejectIntent(intentId);
      emit(
        CloseLoanSuccess(),
      ); // Successfully rejected (doesn't change loan state)
    } catch (e) {
      emit(CloseLoanSuccess());
    }
  }

  Failure _mapDioErrorToFailure(DioException e) {
    if (e.response?.data is Map && e.response?.data['code'] != null) {
      final code = e.response?.data['code'] as String;
      switch (code) {
        case 'INTENT_EXPIRED':
          return const BusinessLogicFailure('INTENT_EXPIRED');
        case 'INTENT_CONSUMED':
          return const IntentConsumedFailure();
        case 'LOAN_FROZEN':
          return const BusinessLogicFailure('LOAN_FROZEN');
        case 'TERMINAL_STATE':
          return const BusinessLogicFailure('TERMINAL_STATE');
        case 'UNAUTHORIZED_ACTION':
          return const BusinessLogicFailure('UNAUTHORIZED_ACTION');
        case 'AUTH_REQUIRED':
          return const BusinessLogicFailure('AUTH_REQUIRED');
      }
    }
    return const NetworkFailure();
  }
}
