part of 'admin_cubit.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminStatsLoaded extends AdminState {
  final AdminStats stats;
  const AdminStatsLoaded({required this.stats});
  @override
  List<Object?> get props => [stats];
}

class AdminUsersLoaded extends AdminState {
  final List<Map<String, dynamic>> users;
  final int total;
  final int page;
  final int pages;
  const AdminUsersLoaded({
    required this.users,
    required this.total,
    required this.page,
    required this.pages,
  });
  @override
  List<Object?> get props => [users, total, page];
}

class AdminLoansLoaded extends AdminState {
  final List<Map<String, dynamic>> loans;
  final int total;
  const AdminLoansLoaded({required this.loans, required this.total});
  @override
  List<Object?> get props => [loans, total];
}

class AdminChitsLoaded extends AdminState {
  final List<Map<String, dynamic>> chits;
  final int total;
  const AdminChitsLoaded({required this.chits, required this.total});
  @override
  List<Object?> get props => [chits, total];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminActionSuccess extends AdminState {
  final String message;
  const AdminActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
