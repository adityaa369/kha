import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/admin_stats_model.dart';

part 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final ApiClient _api;
  AdminCubit({ApiClient? api})
    : _api = api ?? ApiClient(),
      super(AdminInitial());

  Future<void> loadStats() async {
    emit(AdminLoading());
    try {
      final response = await _api.get('/admin/stats');
      final stats = AdminStats.fromJson(response.data['stats']);
      emit(AdminStatsLoaded(stats: stats));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> loadUsers({String search = '', int page = 1}) async {
    emit(AdminLoading());
    try {
      final response = await _api.get(
        '/admin/users',
        queryParameters: {'search': search, 'page': page},
      );
      final data = response.data;
      emit(
        AdminUsersLoaded(
          users: List<Map<String, dynamic>>.from(
            (data['users'] ?? []).map((u) => Map<String, dynamic>.from(u)),
          ),
          total: data['total'] ?? 0,
          page: data['page'] ?? 1,
          pages: data['pages'] ?? 1,
        ),
      );
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> loadLoans({String? status, int page = 1}) async {
    emit(AdminLoading());
    try {
      final qp = <String, dynamic>{'page': page};
      if (status != null) qp['status'] = status;
      final response = await _api.get('/admin/loans', queryParameters: qp);
      final data = response.data;
      emit(
        AdminLoansLoaded(
          loans: List<Map<String, dynamic>>.from(
            (data['loans'] ?? []).map((l) => Map<String, dynamic>.from(l)),
          ),
          total: data['total'] ?? 0,
        ),
      );
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> loadChitFunds({int page = 1}) async {
    emit(AdminLoading());
    try {
      final response = await _api.get(
        '/admin/chit-funds',
        queryParameters: {'page': page},
      );
      final data = response.data;
      emit(
        AdminChitsLoaded(
          chits: List<Map<String, dynamic>>.from(
            (data['chits'] ?? []).map((c) => Map<String, dynamic>.from(c)),
          ),
          total: data['total'] ?? 0,
        ),
      );
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> suspendUser(String userId, bool suspend) async {
    try {
      await _api.put(
        '/admin/users/$userId/suspend',
        data: {'suspend': suspend},
      );
      emit(AdminActionSuccess(suspend ? 'User suspended' : 'User unsuspended'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
