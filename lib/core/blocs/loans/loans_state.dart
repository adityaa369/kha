part of 'loans_cubit.dart';

abstract class LoansState extends Equatable {
  const LoansState();

  @override
  List<Object?> get props => [];
}

class LoansInitial extends LoansState {}

class LoansLoading extends LoansState {}

class LoansLoaded extends LoansState {
  final List<LoanModel> loans;
  const LoansLoaded({required this.loans});

  @override
  List<Object?> get props => [loans];
}

class LoanCreating extends LoansState {}

class LoanCreated extends LoansState {}

class LoansError extends LoansState {
  final String message;
  const LoansError(this.message);

  @override
  List<Object?> get props => [message];
}