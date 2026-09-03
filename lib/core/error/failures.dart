import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server failure occurred', String? code]) : super(code: code);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed', String? code]) : super(code: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection', String? code]) : super(code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input data', String? code]) : super(code: code);
}

class RateLimitedFailure extends Failure {
  const RateLimitedFailure([super.message = 'Too many requests. Please try again later.', String? code = 'RATE_LIMITED']) : super(code: code);
}

class IntentConsumedFailure extends Failure {
  const IntentConsumedFailure([super.message = 'This action was already completed.', String? code = 'INTENT_CONSUMED']) : super(code: code);
}

class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure([super.message = 'Operation rejected by business rules', String? code]) : super(code: code);
}
