import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/repayment_timeline_model.dart';
import '../../../data/repositories/loan_repository.dart';
import '../../../core/error/failures.dart';

abstract class RepaymentTimelineState extends Equatable {
  const RepaymentTimelineState();
  @override
  List<Object?> get props => [];
}

class RepaymentTimelineInitial extends RepaymentTimelineState {}

class RepaymentTimelineLoading extends RepaymentTimelineState {}

class RepaymentTimelineLoaded extends RepaymentTimelineState {
  final RepaymentTimelineModel timelineModel;
  const RepaymentTimelineLoaded(this.timelineModel);
  @override
  List<Object?> get props => [timelineModel];
}

class RepaymentTimelineError extends RepaymentTimelineState {
  final String message;
  const RepaymentTimelineError(this.message);
  @override
  List<Object?> get props => [message];
}

class RepaymentTimelineCubit extends Cubit<RepaymentTimelineState> {
  final LoanRepository _repository;

  RepaymentTimelineCubit(this._repository) : super(RepaymentTimelineInitial());

  Future<void> fetchTimeline(String loanId) async {
    emit(RepaymentTimelineLoading());
    try {
      final model = await _repository.getRepaymentTimeline(loanId);
      emit(RepaymentTimelineLoaded(model));
    } on Failure catch (f) {
      emit(RepaymentTimelineError(f.message));
    } catch (e) {
      emit(RepaymentTimelineError('Failed to load timeline: $e'));
    }
  }
}
