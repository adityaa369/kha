import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/models/interest_schedule_model.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../error/failures.dart';

abstract class InterestScheduleState extends Equatable {
  const InterestScheduleState();
  
  @override
  List<Object?> get props => [];
}

class InterestScheduleInitial extends InterestScheduleState {}

class InterestScheduleLoading extends InterestScheduleState {
  final InterestScheduleModel? lastKnownData;
  const InterestScheduleLoading({this.lastKnownData});
  
  @override
  List<Object?> get props => [lastKnownData];
}

class InterestScheduleLoaded extends InterestScheduleState {
  final InterestScheduleModel schedule;
  const InterestScheduleLoaded(this.schedule);
  
  @override
  List<Object?> get props => [schedule];
}

class InterestScheduleError extends InterestScheduleState {
  final Failure failure;
  final InterestScheduleModel? lastKnownData;
  const InterestScheduleError(this.failure, {this.lastKnownData});
  
  @override
  List<Object?> get props => [failure, lastKnownData];
}

class InterestScheduleCubit extends Cubit<InterestScheduleState> {
  final LoanRepository _repository;

  InterestScheduleCubit({required LoanRepository repository})
      : _repository = repository,
        super(InterestScheduleInitial());

  Future<void> fetchSchedule(String loanId) async {
    InterestScheduleModel? lastData;
    if (state is InterestScheduleLoaded) {
      lastData = (state as InterestScheduleLoaded).schedule;
    } else if (state is InterestScheduleLoading) {
      lastData = (state as InterestScheduleLoading).lastKnownData;
    } else if (state is InterestScheduleError) {
      lastData = (state as InterestScheduleError).lastKnownData;
    }

    emit(InterestScheduleLoading(lastKnownData: lastData));
    
    try {
      final schedule = await _repository.getInterestSchedule(loanId);
      emit(InterestScheduleLoaded(schedule));
    } catch (e) {
      Failure failure;
      if (e is Failure) {
        failure = e;
      } else {
        failure = const NetworkFailure();
      }
      emit(InterestScheduleError(failure, lastKnownData: lastData));
    }
  }
}
