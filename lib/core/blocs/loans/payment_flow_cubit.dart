import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../error/failures.dart';

abstract class PaymentFlowState extends Equatable {
  const PaymentFlowState();
  @override
  List<Object?> get props => [];
}

class PaymentIdle extends PaymentFlowState {}

class PaymentCreatingIntent extends PaymentFlowState {}

class PaymentAwaitingOTP extends PaymentFlowState {
  final String intentId;
  final int amountPaise;
  const PaymentAwaitingOTP(this.intentId, this.amountPaise);

  @override
  List<Object?> get props => [intentId, amountPaise];
}

class PaymentCommitting extends PaymentFlowState {
  final String intentId;
  final int amountPaise;
  const PaymentCommitting(this.intentId, this.amountPaise);

  @override
  List<Object?> get props => [intentId, amountPaise];
}

class PaymentSuccess extends PaymentFlowState {}

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
    String? initialIntentId,
    int? initialAmountPaise,
  }) : _repository = repository,
       _loanId = loanId,
       super(
         initialIntentId != null && initialAmountPaise != null
             ? PaymentAwaitingOTP(initialIntentId, initialAmountPaise)
             : PaymentIdle(),
       );

  void reset() => emit(PaymentIdle());

  // 4F4G: Fetch Intent for Deep Linking (if implemented later)
  Future<void> loadIntent(String intentId) async {
    emit(PaymentCreatingIntent());
    try {
      final intent = await _repository.getIntent(intentId);

      if (intent.action != 'PAYMENT') {
        emit(
          const PaymentRejected(BusinessLogicFailure('INVALID_INTENT_TYPE')),
        );
        return;
      }

      if (intent.status == 'CONSUMED' || intent.status == 'COMMITTED') {
        emit(const PaymentRejected(IntentConsumedFailure()));
      } else if (intent.status == 'EXPIRED') {
        emit(const PaymentRejected(BusinessLogicFailure('INTENT_EXPIRED')));
      } else if (intent.status == 'REJECTED') {
        emit(const PaymentRejected(BusinessLogicFailure('INTENT_REJECTED')));
      } else if (intent.status == 'PENDING') {
        final amountPaise = intent.payload['amountPaise'] ?? 0;
        emit(PaymentAwaitingOTP(intentId, amountPaise));
      } else {
        emit(const PaymentRejected(ServerFailure('Unknown intent status')));
      }
    } on DioException catch (e) {
      emit(PaymentRejected(_mapDioErrorToFailure(e)));
    } on Failure catch (f) {
      emit(PaymentRejected(f));
    } catch (e) {
      emit(PaymentRejected(ServerFailure(e.toString())));
    }
  }

  // Phase 1: Lender initiates payment request, server generates OTP and notifies borrower
  Future<void> createIntent(int amountPaise) async {
    if (state is! PaymentIdle) return;

    emit(PaymentCreatingIntent());

    try {
      final intentId = await _repository.createPaymentIntent(
        loanId: _loanId,
        amountPaise: amountPaise,
      );
      emit(PaymentAwaitingOTP(intentId, amountPaise));
    } on DioException catch (e) {
      emit(PaymentRejected(_mapDioErrorToFailure(e)));
    } on Failure catch (f) {
      emit(PaymentRejected(f));
    } catch (e) {
      emit(PaymentRejected(ServerFailure(e.toString())));
    }
  }

  // Phase 2: Borrower provides OTP to authorize and commit the payment
  Future<void> commitPayment(String otp) async {
    if (state is! PaymentAwaitingOTP) return;

    final currentState = state as PaymentAwaitingOTP;
    final intentId = currentState.intentId;
    final amountPaise = currentState.amountPaise;

    emit(PaymentCommitting(intentId, amountPaise));

    try {
      final success = await _repository.commitPayment(
        loanId: _loanId,
        intentId: intentId,
        otp: otp,
      );

      if (success) {
        emit(PaymentSuccess());
      } else {
        emit(const PaymentRejected(ServerFailure('Commit failed')));
      }
    } on DioException catch (e) {
      // Revert to AwaitingOTP so user can try again on validation errors or wrong OTP
      if ((e.response?.statusCode == 400 || e.response?.statusCode == 401) &&
          e.response?.data['code'] == 'OTP_INVALID') {
        final msg = e.response?.data['message'] ?? 'Invalid OTP';
        emit(PaymentRejected(BusinessLogicFailure(msg)));
        emit(PaymentAwaitingOTP(intentId, amountPaise));
        return;
      }
      if (e.response?.statusCode == 429 &&
          e.response?.data['code'] == 'OTP_LOCKED') {
        emit(
          const PaymentRejected(
            BusinessLogicFailure(
              'Too many incorrect attempts. Payment has been cancelled.',
            ),
          ),
        );
        return;
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        await reconcile(intentId, amountPaise);
      } else {
        emit(PaymentRejected(_mapDioErrorToFailure(e)));
      }
    } on Failure catch (f) {
      emit(PaymentRejected(f));
    } catch (e) {
      emit(PaymentRejected(ServerFailure(e.toString())));
    }
  }

  // Reconcile network unknowns
  Future<void> reconcile(String intentId, int amountPaise) async {
    try {
      final status = await _repository.checkIntentStatus(intentId);
      if (status == 'CONSUMED' || status == 'COMMITTED') {
        emit(PaymentSuccess());
      } else if (status == 'PENDING') {
        emit(PaymentAwaitingOTP(intentId, amountPaise));
      } else if (status == 'EXPIRED') {
        emit(const PaymentRejected(BusinessLogicFailure('INTENT_EXPIRED')));
      } else if (status == 'REJECTED') {
        emit(const PaymentRejected(BusinessLogicFailure('INTENT_REJECTED')));
      } else {
        emit(const PaymentRejected(ServerFailure('Unknown intent status')));
      }
    } catch (e) {
      emit(const PaymentRejected(NetworkFailure()));
    }
  }

  // Cancel Intent
  Future<void> rejectIntent() async {
    if (state is! PaymentAwaitingOTP) return;
    final intentId = (state as PaymentAwaitingOTP).intentId;
    emit(PaymentCommitting(intentId, 0));
    try {
      await _repository.rejectIntent(intentId);
      emit(PaymentIdle());
    } catch (e) {
      emit(PaymentIdle());
    }
  }

  Failure _mapDioErrorToFailure(DioException e) {
    if (e.response?.data is Map && e.response?.data['code'] != null) {
      final code = e.response?.data['code'] as String;
      final message = e.response?.data['message'] as String?;
      switch (code) {
        case 'INTENT_EXPIRED':
        case 'OTP_EXPIRED':
          return const BusinessLogicFailure('OTP_EXPIRED');
        case 'INTENT_CONSUMED':
          return const IntentConsumedFailure();
        case 'LOAN_FROZEN':
          return const BusinessLogicFailure('LOAN_FROZEN');
        case 'TERMINAL_STATE':
          return const BusinessLogicFailure('TERMINAL_STATE');
        case 'UNAUTHORIZED_ACTION':
          return const BusinessLogicFailure('UNAUTHORIZED_ACTION');
        case 'VALIDATION_ERROR':
          return const ValidationFailure('VALIDATION_ERROR');
        case 'OVERPAYMENT_REJECTED':
          return BusinessLogicFailure(message ?? 'OVERPAYMENT_REJECTED');
        default:
          return BusinessLogicFailure(message ?? code);
      }
    }
    return const NetworkFailure();
  }
}
