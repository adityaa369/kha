import 'package:flutter_bloc/flutter_bloc.dart';
import 'chit_fund_state.dart';
import '../../../../data/repositories/chit_fund_repository.dart';

class ChitFundCubit extends Cubit<ChitFundState> {
  final ChitFundRepository _repository;

  ChitFundCubit(this._repository) : super(ChitFundInitial());

  Future<void> loadInvitesAndOwned() async {
    try {
      if (state is! ChitFundInvitesLoaded) {
          emit(ChitFundLoading());
      }
      
      // Fetch both owned forming chits AND pending invites AND active subscriptions
      final ownedChits = await _repository.getVacantChits();
      final pendingInvites = await _repository.getMyInvites();
      final mySubscriptions = await _repository.getMyChits();
      
      emit(ChitFundInvitesLoaded(
        ownedChits: ownedChits,
        pendingInvites: pendingInvites,
        mySubscriptions: mySubscriptions,
      ));
    } catch (e) {
      emit(ChitFundError(e.toString()));
    }
  }

  Future<void> createChitGroup({
    required String name,
    required double totalValue,
    required int totalMonths,
  }) async {
    try {
      emit(ChitFundLoading());
      await _repository.createChitFund(
        name: name,
        totalValue: totalValue,
        totalMonths: totalMonths,
      );
      emit(const ChitFundActionSuccess('Chit Group Created Successfully!'));
      await loadInvitesAndOwned();
    } catch (e) {
      emit(ChitFundError(e.toString()));
      await loadInvitesAndOwned();
    }
  }

  Future<void> sendInvite(String chitId, String phone) async {
    try {
      await _repository.sendInvite(chitId, phone);
      emit(const ChitFundActionSuccess('Invite sent successfully!'));
      await loadInvitesAndOwned();
    } catch (e) {
      emit(ChitFundError(e.toString()));
      await loadInvitesAndOwned();
    }
  }

  Future<void> respondToInvite(String inviteId, String status) async {
    try {
      await _repository.respondToInvite(inviteId, status);
      emit(ChitFundActionSuccess('Invite ${status == 'accepted' ? 'Accepted & Joined' : 'Declined'}!'));
      await loadInvitesAndOwned();
    } catch (e) {
      emit(ChitFundError(e.toString()));
      await loadInvitesAndOwned();
    }
  }

  Future<void> loadAdminDashboard(String chitId) async {
    try {
      emit(ChitFundLoading());
      final data = await _repository.getAdminDashboard(chitId);
      emit(ChitAdminDashboardLoaded(data));
    } catch (e) {
      emit(ChitFundError(e.toString()));
    }
  }

  Future<void> deleteChitFund(String chitId) async {
    try {
      await _repository.deleteChitFund(chitId);
      emit(const ChitFundActionSuccess('Chit group deleted successfully!'));
      await loadInvitesAndOwned();
    } catch (e) {
      emit(ChitFundError(e.toString()));
    }
  }
}
