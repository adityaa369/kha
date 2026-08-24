import 'package:flutter_bloc/flutter_bloc.dart';

enum SystemState {
  normal,
  financialOperationsPaused,
}

class SystemStateCubit extends Cubit<SystemState> {
  SystemStateCubit() : super(SystemState.normal);

  void pauseFinancialOperations() {
    if (state != SystemState.financialOperationsPaused) {
      emit(SystemState.financialOperationsPaused);
    }
  }

  void resumeOperations() {
    if (state != SystemState.normal) {
      emit(SystemState.normal);
    }
  }
}
