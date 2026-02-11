import 'package:equatable/equatable.dart';

abstract class CreditScoreState extends Equatable {
  const CreditScoreState();

  @override
  List<Object?> get props => [];
}

class CreditScoreInitial extends CreditScoreState {}

class CreditScoreLoading extends CreditScoreState {}

class CreditScoreLoaded extends CreditScoreState {
  final int cibilScore;
  final int experianScore;
  final String status;

  const CreditScoreLoaded({
    required this.cibilScore,
    required this.experianScore,
    required this.status,
  });

  @override
  List<Object?> get props => [cibilScore, experianScore, status];
}

class CreditScoreError extends CreditScoreState {
  final String message;

  const CreditScoreError(this.message);

  @override
  List<Object?> get props => [message];
}