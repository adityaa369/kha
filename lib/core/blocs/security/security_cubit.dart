import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
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
      emit(state.copyWith(isLoading: false, error: _extractError(e)));
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      emit(state.copyWith(isLoading: true));
      await _repository.revokeSession(sessionId);
      await loadSecurityData(); // Refresh list
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _extractError(e)));
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
      emit(state.copyWith(isLoading: false, error: _extractError(e)));
    }
  }

  Future<bool> getMpinStatus() async {
    try {
      return await _repository.getMpinStatus();
    } catch (_) {
      return false;
    }
  }

  String _extractError(dynamic e) {
    if (e is String) return e;
    try {
      if (e is DioException) {
        if (e.error != null && e.error.toString().contains('AuthFailure')) {
          return 'Session expired. Please login again.';
        }
        if (e.response?.data != null && e.response?.data is Map && e.response!.data['message'] != null) {
          return e.response!.data['message'];
        }
        return e.message ?? 'Network error';
      }
      return e.toString();
    } catch (_) {
      return 'An unexpected error occurred';
    }
  }
}
