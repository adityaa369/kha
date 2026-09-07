import 'package:equatable/equatable.dart';
import '../../../../data/models/chit_fund_model.dart';
import '../../../../data/models/chit_invite_model.dart';

abstract class ChitFundState extends Equatable {
  const ChitFundState();

  @override
  List<Object?> get props => [];
}

class ChitFundInitial extends ChitFundState {}

class ChitFundLoading extends ChitFundState {}

class ChitFundError extends ChitFundState {
  final String message;
  const ChitFundError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChitFundInvitesLoaded extends ChitFundState {
  final List<ChitFundModel> ownedChits;
  final List<ChitInviteModel> pendingInvites;
  final List<Map<String, dynamic>> mySubscriptions;

  const ChitFundInvitesLoaded({
    required this.ownedChits,
    required this.pendingInvites,
    required this.mySubscriptions,
  });

  @override
  List<Object?> get props => [ownedChits, pendingInvites, mySubscriptions];
}

class ChitFundActionSuccess extends ChitFundState {
  final String message;
  const ChitFundActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ChitAdminDashboardLoaded extends ChitFundState {
  final Map<String, dynamic> dashboardData;

  const ChitAdminDashboardLoaded(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

class ChitMemberDetailLoaded extends ChitFundState {
  final Map<String, dynamic> memberData; // subscription info
  final List<Map<String, dynamic>> auctionHistory;
  final List<Map<String, dynamic>> paymentHistory;
  final Map<String, dynamic> chitInfo; // group name, totalValue, etc.

  const ChitMemberDetailLoaded({
    required this.memberData,
    required this.auctionHistory,
    required this.paymentHistory,
    required this.chitInfo,
  });

  @override
  List<Object?> get props => [
    memberData,
    auctionHistory,
    paymentHistory,
    chitInfo,
  ];
}
