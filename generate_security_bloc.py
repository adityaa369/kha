import os

os.makedirs('lib/data/models', exist_ok=True)
os.makedirs('lib/data/repositories', exist_ok=True)
os.makedirs('lib/core/blocs/security', exist_ok=True)
os.makedirs('lib/features/profile/presentation/pages', exist_ok=True)

# 1. Models
session_model = """class SessionModel {
  final String id;
  final String deviceInfo;
  final DateTime lastUsedAt;
  final DateTime expiresAt;

  SessionModel({
    required this.id,
    required this.deviceInfo,
    required this.lastUsedAt,
    required this.expiresAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['_id'] ?? '',
      deviceInfo: json['deviceInfo'] ?? 'Unknown Device',
      lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt']) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now(),
    );
  }
}
"""
with open('lib/data/models/session_model.dart', 'w', encoding='utf-8') as f: f.write(session_model)

security_event_model = """class SecurityEventModel {
  final String eventType;
  final String result;
  final DateTime createdAt;

  SecurityEventModel({
    required this.eventType,
    required this.result,
    required this.createdAt,
  });

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) {
    return SecurityEventModel(
      eventType: json['eventType'] ?? 'UNKNOWN',
      result: json['result'] ?? 'UNKNOWN',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
"""
with open('lib/data/models/security_event_model.dart', 'w', encoding='utf-8') as f: f.write(security_event_model)

# 2. Repository
repository = """import '../../core/network/api_client.dart';
import '../models/session_model.dart';
import '../models/security_event_model.dart';

class SecurityRepository {
  final ApiClient _apiClient;

  SecurityRepository(this._apiClient);

  Future<List<SessionModel>> getSessions() async {
    final response = await _apiClient.get('/auth/sessions');
    if (response.data['success'] == true) {
      final List data = response.data['sessions'] ?? [];
      return data.map((json) => SessionModel.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch sessions');
  }

  Future<List<SecurityEventModel>> getSecurityEvents() async {
    final response = await _apiClient.get('/auth/security-events');
    if (response.data['success'] == true) {
      final List data = response.data['events'] ?? [];
      return data.map((json) => SecurityEventModel.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch events');
  }

  Future<void> revokeSession(String sessionId) async {
    final response = await _apiClient.delete('/auth/sessions/$sessionId');
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to revoke session');
    }
  }

  Future<void> revokeOtherSessions(String currentRefreshToken) async {
    final response = await _apiClient.post(
      '/auth/sessions/revoke-others',
      data: {'refreshToken': currentRefreshToken},
    );
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to revoke other sessions');
    }
  }
}
"""
with open('lib/data/repositories/security_repository.dart', 'w', encoding='utf-8') as f: f.write(repository)

# 3. Cubit
cubit = """import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/session_model.dart';
import '../../../data/models/security_event_model.dart';
import '../../../data/repositories/security_repository.dart';
import '../../services/secure_storage_service.dart';

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
  final SecureStorageService _storage;

  SecurityCubit(this._repository, this._storage) : super(SecurityState());

  Future<void> loadSecurityData() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final sessions = await _repository.getSessions();
      final events = await _repository.getSecurityEvents();
      emit(state.copyWith(isLoading: false, sessions: sessions, events: events));
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
      final rt = await _storage.getRefreshToken();
      if (rt == null) throw Exception('No current session context found.');
      
      await _repository.revokeOtherSessions(rt);
      await loadSecurityData(); // Refresh list
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
"""
with open('lib/core/blocs/security/security_cubit.dart', 'w', encoding='utf-8') as f: f.write(cubit)
print("Created models, repo, and cubit!")
