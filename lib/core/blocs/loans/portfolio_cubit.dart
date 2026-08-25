import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/portfolio_summary_model.dart';
import '../../../data/repositories/loan_repository.dart';
import '../../../core/error/failures.dart';

abstract class PortfolioState extends Equatable {
  const PortfolioState();
  @override
  List<Object?> get props => [];
}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final PortfolioSummaryModel summary;
  const PortfolioLoaded(this.summary);
  @override
  List<Object?> get props => [summary];
}

class PortfolioError extends PortfolioState {
  final String message;
  const PortfolioError(this.message);
  @override
  List<Object?> get props => [message];
}

class PortfolioCubit extends Cubit<PortfolioState> {
  final LoanRepository _repository;

  PortfolioCubit(this._repository) : super(PortfolioInitial());

  Future<void> fetchPortfolioSummary() async {
    emit(PortfolioLoading());
    try {
      final summary = await _repository.getPortfolioSummary();
      emit(PortfolioLoaded(summary));
    } on Failure catch (f) {
      emit(PortfolioError(f.message));
    } catch (e) {
      emit(PortfolioError('Failed to load portfolio: $e'));
    }
  }
}
