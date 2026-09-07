import 'package:flutter_bloc/flutter_bloc.dart';
import 'chit_fund_state.dart';
import '../../../../data/repositories/chit_fund_repository.dart';

class ChitFundCubit extends Cubit<ChitFundState> {
  final ChitFundRepository _repository;

  ChitFundCubit(this._repository) : super(ChitFundInitial());

  Future<void> loadInvitesAndOwned() async {
    // 1. Load from local cache instantly if state is not already loaded
    if (state is! ChitFundInvitesLoaded) {
      try {
        final cachedVacant = await _repository.getCachedVacantChits();
        final cachedInvites = await _repository.getCachedMyInvites();
        final cachedMyChits = await _repository.getCachedMyChits();

        if ((cachedVacant != null && cachedVacant.isNotEmpty) ||
            (cachedInvites != null && cachedInvites.isNotEmpty) ||
            (cachedMyChits != null && cachedMyChits.isNotEmpty)) {
          emit(
            ChitFundInvitesLoaded(
              ownedChits: cachedVacant ?? [],
              pendingInvites: cachedInvites ?? [],
              mySubscriptions: cachedMyChits ?? [],
            ),
          );
        } else {
          emit(ChitFundLoading());
        }
      } catch (_) {
        emit(ChitFundLoading());
      }
    }

    // 2. Fetch from server in the background
    try {
      final ownedChits = await _repository.getVacantChits();
      final pendingInvites = await _repository.getMyInvites();
      final mySubscriptions = await _repository.getMyChits();

      emit(
        ChitFundInvitesLoaded(
          ownedChits: ownedChits,
          pendingInvites: pendingInvites,
          mySubscriptions: mySubscriptions,
        ),
      );
    } catch (e) {
      // Only emit error if we don't have loaded data to show
      if (state is! ChitFundInvitesLoaded) {
        emit(ChitFundError(e.toString()));
      }
    }
  }

  Future<void> createChitGroup({
    required String name,
    required double totalValue,
    required int totalMonths,
    double commissionPercent = 5.0,
    String branchName = 'KPHB-CAO',
  }) async {
    try {
      emit(ChitFundLoading());
      await _repository.createChitFund(
        name: name,
        totalValue: totalValue,
        totalMonths: totalMonths,
        commissionPercent: commissionPercent,
        branchName: branchName,
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
      emit(
        ChitFundActionSuccess(
          'Invite ${status == 'accepted' ? 'Accepted & Joined' : 'Declined'}!',
        ),
      );
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

  Future<void> manualFinalizeAuction({
    required String chitId,
    required String winnerUserId,
    required double bidDiscount,
  }) async {
    try {
      emit(ChitFundLoading());
      await _repository.finalizeAuction(
        chitId: chitId,
        winnerUserId: winnerUserId,
        bidDiscount: bidDiscount,
      );
      emit(const ChitFundActionSuccess('Auction Finalized successfully!'));
      await loadAdminDashboard(chitId);
    } catch (e) {
      emit(ChitFundError(e.toString()));
      await loadAdminDashboard(chitId);
    }
  }

  // Open auction
  Future<void> openAuctionMonth({
    required String chitId,
    required int monthNumber,
    required double baseAmount,
  }) async {
    try {
      emit(ChitFundLoading());
      await _repository.openAuctionMonth(chitId, monthNumber, baseAmount);
      emit(
        const ChitFundActionSuccess(
          'Auction opened successfully! Notifications sent.',
        ),
      );
      await loadAdminDashboard(chitId);
    } catch (e) {
      emit(ChitFundError(e.toString()));
      await loadAdminDashboard(chitId);
    }
  }

  // Submit Bid
  Future<void> submitBid({
    required String chitId,
    required double bidDiscount,
  }) async {
    try {
      emit(ChitFundLoading());
      await _repository.submitBid(chitId, bidDiscount);
      emit(const ChitFundActionSuccess('Bid submitted successfully!'));
      await loadAdminDashboard(chitId);
    } catch (e) {
      emit(ChitFundError(e.toString()));
      await loadAdminDashboard(chitId);
    }
  }

  // Get Auction Bids
  Future<List<Map<String, dynamic>>> getAuctionBids(
    String chitId,
    int monthNumber,
  ) async {
    try {
      return await _repository.getAuctionBids(chitId, monthNumber);
    } catch (e) {
      return [];
    }
  }

  // Verify Payment for explicitly selected month
  Future<void> verifyMonthPayment({
    required String chitId,
    required int monthNumber,
    required String subscriberId,
    required bool isPaid,
  }) async {
    try {
      await _repository.verifyMonthPayment(
        chitId,
        monthNumber,
        subscriberId,
        isPaid,
      );
      // Silently reload dashboard to show updated UI without showing success snackbar every single time
      final data = await _repository.getAdminDashboard(chitId);
      emit(ChitAdminDashboardLoaded(data));
    } catch (e) {
      emit(ChitFundError(e.toString()));
    }
  }

  // Load Member Detail (member's own view of a chit)
  Future<void> loadMemberDetail(String chitId) async {
    try {
      emit(ChitFundLoading());
      final result = await _repository.getMemberDetail(chitId);
      emit(
        ChitMemberDetailLoaded(
          memberData: Map<String, dynamic>.from(result['subscription'] ?? {}),
          auctionHistory: List<Map<String, dynamic>>.from(
            (result['auctionHistory'] ?? []).map(
              (e) => Map<String, dynamic>.from(e),
            ),
          ),
          paymentHistory: List<Map<String, dynamic>>.from(
            (result['paymentHistory'] ?? []).map(
              (e) => Map<String, dynamic>.from(e),
            ),
          ),
          chitInfo: Map<String, dynamic>.from(result['chitInfo'] ?? {}),
        ),
      );
    } catch (e) {
      emit(ChitFundError(e.toString()));
    }
  }

  // Mark payment paid/unpaid (owner action)
  Future<void> markPaymentPaid({
    required String chitId,
    required int monthNumber,
    required String subscriberId,
    required bool isPaid,
  }) async {
    try {
      await _repository.verifyMonthPayment(
        chitId,
        monthNumber,
        subscriberId,
        isPaid,
      );
      // Silently reload dashboard
      final data = await _repository.getAdminDashboard(chitId);
      emit(ChitAdminDashboardLoaded(data));
    } catch (e) {
      emit(ChitFundError(e.toString()));
    }
  }
}
