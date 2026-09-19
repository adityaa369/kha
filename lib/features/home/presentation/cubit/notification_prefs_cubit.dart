import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/notification_preferences.dart';

// ── State ────────────────────────────────────────────────────
abstract class NotificationPrefsState extends Equatable {
  const NotificationPrefsState();
  @override
  List<Object?> get props => [];
}

class NotificationPrefsInitial extends NotificationPrefsState {}
class NotificationPrefsLoading extends NotificationPrefsState {}

class NotificationPrefsLoaded extends NotificationPrefsState {
  final NotificationPreferences prefs;
  final bool isSaving;
  final String? saveError;

  const NotificationPrefsLoaded({
    required this.prefs,
    this.isSaving = false,
    this.saveError,
  });

  NotificationPrefsLoaded copyWith({
    NotificationPreferences? prefs,
    bool? isSaving,
    String? saveError,
  }) {
    return NotificationPrefsLoaded(
      prefs: prefs ?? this.prefs,
      isSaving: isSaving ?? this.isSaving,
      saveError: saveError,
    );
  }

  @override
  List<Object?> get props => [prefs, isSaving, saveError];
}

class NotificationPrefsError extends NotificationPrefsState {
  final String message;
  const NotificationPrefsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ────────────────────────────────────────────────────
class NotificationPrefsCubit extends Cubit<NotificationPrefsState> {
  final ApiClient _api;

  NotificationPrefsCubit(this._api) : super(NotificationPrefsInitial());

  Future<void> load() async {
    emit(NotificationPrefsLoading());
    try {
      final res = await _api.get('/users/notification-preferences');
      final prefs = NotificationPreferences.fromJson(
          Map<String, dynamic>.from(res.data?['preferences'] ?? {}));
      emit(NotificationPrefsLoaded(prefs: prefs));
    } catch (e) {
      emit(NotificationPrefsError('Failed to load preferences: $e'));
    }
  }

  Future<void> update(NotificationPreferences updated) async {
    final current = state;
    if (current is! NotificationPrefsLoaded) return;

    // Optimistic update
    emit(current.copyWith(prefs: updated, isSaving: true));

    try {
      await _api.put('/users/notification-preferences', data: updated.toJson());
      emit(NotificationPrefsLoaded(prefs: updated));
    } catch (e) {
      // Revert
      emit(current.copyWith(
        isSaving: false,
        saveError: 'Failed to save. Please try again.',
      ));
    }
  }
}
