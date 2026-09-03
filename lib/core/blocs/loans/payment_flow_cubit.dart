import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../error/failures.dart';

class PaymentAttempt extends Equatable {
  final double amountRupees;
  final String idempotencyKey;

  PaymentAttempt({required this.amountRupees, String? key}) 
    : idempotencyKey = key ?? const Uuid().v4();

  @override
  List<Object?> get props => [amountRupees, idempotencyKey];
}

abstract class PaymentFlowState extends Equatable {
  const PaymentFlowState();
  @override
  List<Object?> get props => [];
}

class PaymentIdle extends PaymentFlowState {
  final PaymentAttempt? failedAttempt;
  const PaymentIdle([this.failedAttempt]);
  
  @override
  List<Object?> get props => [failedAttempt];
}

class PaymentSubmitting extends PaymentFlowState {}

class PaymentSuccess extends PaymentFlowState {}

class PaymentUnknown extends PaymentFlowState {
  final PaymentAttempt attempt;
  const PaymentUnknown(this.attempt);
  
  @override
  List<Object?> get props => [attempt];
}

class PaymentReconciling extends PaymentFlowState {}

class PaymentRejected extends PaymentFlowState {
  final Failure failure;
  const PaymentRejected(this.failure);
  
  @override
  List<Object?> get props => [failure];
}

class PaymentFlowCubit extends Cubit<PaymentFlowState> {
  final LoanRepository _repository;
  final String _loanId;

  PaymentFlowCubit({
    required LoanRepository repository,
    required String loanId,
  }) : _repository = repository,
       _loanId = loanId,
       super(const PaymentIdle());

  void reset() => emit(const PaymentIdle());

  Future<void> submitPayment(double amountRupees) async {
    if (state is PaymentSubmitting || state is PaymentReconciling) return;
    
    PaymentAttempt attempt;
    if (state is PaymentIdle && (state as PaymentIdle).failedAttempt != null && (state as PaymentIdle).failedAttempt!.amountRupees == amountRupees) {
      attempt = (state as PaymentIdle).failedAttempt!;
    } else {
      attempt = PaymentAttempt(amountRupees: amountRupees);
    }
    emit(PaymentSubmitting());
    
    try {
      final success = await _repository.recordPayment(
        _loanId, 
        amountRupees: attempt.amountRupees,
        idempotencyKey: attempt.idempotencyKey,
      );
      
      if (success) {
        emit(PaymentSuccess());
      } else {
        emit(const PaymentRejected(ServerFailure('Payment failed without specific error')));
      }
    } on TimeoutException {
      emit(PaymentUnknown(attempt));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.sendTimeout) {
        emit(PaymentUnknown(attempt));
      } else {
        emit(PaymentRejected(_mapDioErrorToFailure(e)));
      }
    } on Failure catch (f) {
      emit(PaymentRejected(f));
    } catch (e) {
      emit(PaymentRejected(ServerFailure(e.toString())));
    }
  }

  Future<void> reconcile(PaymentAttempt attempt) async {
    emit(PaymentReconciling());
    try {
      final status = await _repository.checkTransactionStatus(attempt.idempotencyKey);
      if (status == 'COMMITTED') {
        emit(PaymentSuccess());
      } else {
        // Safe to retry
        emit(PaymentIdle(attempt)); 
      }
    } catch (e) {
      // If reconciliation fails, stay in unknown to let user retry reconciliation
      emit(PaymentUnknown(attempt));
    }
  }

  Failure _mapDioErrorToFailure(DioException e) {
    if (e.response?.data is Map && e.response?.data['code'] != null) {
      final code = e.response?.data['code'] as String;
      switch (code) {
        case 'RATE_LIMITED': return const RateLimitedFailure();
        case 'INTENT_CONSUMED': return const IntentConsumedFailure();
        case 'OVERPAYMENT_REJECTED': return const BusinessLogicFailure('OVERPAYMENT_REJECTED');
        case 'LOAN_FROZEN': return const BusinessLogicFailure('LOAN_FROZEN');
        case 'VALIDATION_ERROR': return const ValidationFailure('VALIDATION_ERROR');
      }
    }
    return const NetworkFailure();
  }
}
