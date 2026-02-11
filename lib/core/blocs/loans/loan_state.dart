import 'package:equatable/equatable.dart';
import '../../../../data/models/loan_model.dart';

abstract class LoanState extends Equatable {
  const LoanState();

  @override
  List<Object?> get props => [];
}

class LoanInitial extends LoanState {}

class LoanLoading extends LoanState {}

class LoansLoaded extends LoanState {
  final List<LoanModel> myLoans;
  final List<LoanModel> givenLoans;

  const LoansLoaded({
    required this.myLoans,
    required this.givenLoans,
  });

  @override
  List<Object?> get props => [myLoans, givenLoans];
}

class LoanError extends LoanState {
  final String message;

  const LoanError(this.message);

  @override
  List<Object?> get props => [message];
}

class LoanCreated extends LoanState {
  final LoanModel loan;

  const LoanCreated(this.loan);

  @override
  List<Object?> get props => [loan];
}
