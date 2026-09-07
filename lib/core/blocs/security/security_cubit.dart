import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/session_model.dart';
import '../../../data/models/security_event_model.dart';
import '../../../data/repositories/security_repository.dart';
import '../../utils/secure_storage.dart';

class SecurityState {
  final bool isLoading;
  final String? error;
  final List<SessionModel> sessions;
  final List<SecurityEventModel> events;

  SecurityState({
    this.isLoading = false,
    this.error,
    this.sessions = const [],
    this.events = const [],
  });

  SecurityState copyWith({
    bool? isLoading,
    String? error,
    List<SessionModel>? sessions,
    List<SecurityEventModel>? events,
    bool clearError = false,
  }) {
    return SecurityState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      sessions: sessions ?? this.sessions,
      events: events ?? this.events,
    );
  }
}

class SecurityCubit extends Cubit<SecurityState> {
  final SecurityRepository _repository;

  SecurityCubit(this._repository) : super(SecurityState());

  Future<void> loadSecurityData() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final rt = await SecureStorage.getRefreshToken();
      final sessions = await _repository.getSessions(rt);
      final events = await _repository.getSecurityEvents();
      emit(
        state.copyWith(isLoading: false, sessions: sessions, events: events),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      emit(state.copyWith(isLoading: true));
      await _repository.revokeSession(sessionId);
      await loadSecurityData(); // Refresh list
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> revokeOtherSessions() async {
    try {
      emit(state.copyWith(isLoading: true));
      final rt = await SecureStorage.getRefreshToken();
      if (rt == null) throw Exception('No current session context found.');

      await _repository.revokeOtherSessions(rt);
      await loadSecurityData(); // Refresh list
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
