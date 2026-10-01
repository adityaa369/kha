import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String verificationId;
  final int? resendToken;
  const PaymentAwaitingOTP(this.intentId, this.amountPaise, this.verificationId, [this.resendToken]);

  @override
  List<Object?> get props => [intentId, amountPaise, verificationId, resendToken];
}

class PaymentCommitting extends PaymentFlowState {
  final String intentId;
  final int amountPaise;
  const PaymentCommitting(this.intentId, this.amountPaise);

  @override
  List<Object?> get props => [intentId, amountPaise];
}

class PaymentSuccess extends PaymentFlowState {
  final bool isCompleted;
  const PaymentSuccess(this.isCompleted);

  @override
  List<Object?> get props => [isCompleted];
}

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
       super(PaymentIdle());

  void reset() => emit(PaymentIdle());

  Future<void> createIntent(int amountPaise) async {
    if (state is! PaymentIdle) return;

    emit(PaymentCreatingIntent());

    try {
      final res = await _repository.createPaymentIntent(
        loanId: _loanId,
        amountPaise: amountPaise,
      );
      final intentId = res['intentId']!;
      String borrowerPhone = res['borrowerPhone']!;
      
      // Ensure +91 prefix for Indian numbers if missing
      if (!borrowerPhone.startsWith('+')) {
        borrowerPhone = '+91$borrowerPhone';
      }

      // Initialize secondary Firebase App
      FirebaseApp paymentApp;
      try {
        paymentApp = Firebase.app('paymentAuthApp');
      } catch (e) {
        paymentApp = await Firebase.initializeApp(
          name: 'paymentAuthApp',
          options: Firebase.app().options,
        );
      }
      final paymentAuth = FirebaseAuth.instanceFor(app: paymentApp);

      final completer = Completer<Map<String, dynamic>>();

      await paymentAuth.verifyPhoneNumber(
        phoneNumber: borrowerPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // If auto-retrieval completes it without prompt
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(ServerFailure(e.message ?? 'Phone verification failed'));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete({'verId': verificationId, 'token': resendToken});
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            completer.complete({'verId': verificationId, 'token': null});
          }
        },
      );

      final result = await completer.future;
      emit(PaymentAwaitingOTP(intentId, amountPaise, result['verId'], result['token']));
    } on DioException catch (e) {
      emit(PaymentRejected(_mapDioErrorToFailure(e)));
    } on Failure catch (f) {
      emit(PaymentRejected(f));
    } catch (e) {
      emit(PaymentRejected(ServerFailure(e.toString())));
    }
  }

  Future<void> commitPayment(String otp) async {
    if (state is! PaymentAwaitingOTP) return;

    final currentState = state as PaymentAwaitingOTP;
    final intentId = currentState.intentId;
    final amountPaise = currentState.amountPaise;
    final verificationId = currentState.verificationId;

    emit(PaymentCommitting(intentId, amountPaise));

    try {
      FirebaseApp paymentApp = Firebase.app('paymentAuthApp');
      FirebaseAuth paymentAuth = FirebaseAuth.instanceFor(app: paymentApp);

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final credentialResult = await paymentAuth.signInWithCredential(credential);
      final firebaseIdToken = await credentialResult.user!.getIdToken(true);

      // Clean up temporary session
      await paymentAuth.signOut();

      final updatedLoan = await _repository.commitPayment(
        loanId: _loanId,
        intentId: intentId,
        firebaseIdToken: firebaseIdToken!,
      );

      emit(PaymentSuccess(updatedLoan.status == 'completed' || updatedLoan.status == 'closed'));
    } on FirebaseAuthException catch (e) {
      emit(PaymentRejected(BusinessLogicFailure(e.message ?? 'Invalid OTP')));
      emit(PaymentAwaitingOTP(intentId, amountPaise, verificationId, currentState.resendToken));
    } on DioException catch (e) {
      emit(PaymentRejected(_mapDioErrorToFailure(e)));
    } on Failure catch (f) {
      emit(PaymentRejected(f));
    } catch (e) {
      emit(PaymentRejected(ServerFailure(e.toString())));
    }
  }

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
