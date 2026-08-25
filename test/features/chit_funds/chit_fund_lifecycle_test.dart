import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khatha/core/blocs/chit_funds/chit_fund_cubit.dart';
import 'package:khatha/core/blocs/chit_funds/chit_fund_state.dart';
import 'package:khatha/data/repositories/chit_fund_repository.dart';
import 'package:khatha/data/models/chit_fund_model.dart';

// Mock Repository
class MockChitFundRepository extends Mock implements ChitFundRepository {}

void main() {
  late ChitFundCubit chitFundCubit;
  late MockChitFundRepository mockRepository;

  setUp(() {
    mockRepository = MockChitFundRepository();
    chitFundCubit = ChitFundCubit(mockRepository);
  });

  tearDown(() {
    chitFundCubit.close();
  });

  group('Chit Fund Full Lifecycle Test', () {
    
    // 1. Creation Phase
    blocTest<ChitFundCubit, ChitFundState>(
      'Step 1: Admin creates a new Chit Fund group',
      build: () {
        when(() => mockRepository.createChitFund(
              name: 'Test Group',
              totalValue: 500000,
              totalMonths: 20,
              commissionPercent: 5.0,
              branchName: 'KPHB-CAO',
            )).thenAnswer((_) async => ChitFundModel.fromJson({
              '_id': 'chit_123',
              'name': 'Test Group',
              'totalValue': 500000,
              'totalMonths': 20,
              'monthlySubscription': 25000,
              'commissionPercentage': 5.0,
              'status': 'FORMING',
              'currentSubscribersCount': 1,
            }));
        
        // Mock the reload calls that happen after success
        when(() => mockRepository.getCachedVacantChits()).thenAnswer((_) async => []);
        when(() => mockRepository.getCachedMyInvites()).thenAnswer((_) async => []);
        when(() => mockRepository.getCachedMyChits()).thenAnswer((_) async => []);
        when(() => mockRepository.getVacantChits()).thenAnswer((_) async => []);
        when(() => mockRepository.getMyInvites()).thenAnswer((_) async => []);
        when(() => mockRepository.getMyChits()).thenAnswer((_) async => []);

        return chitFundCubit;
      },
      act: (cubit) => cubit.createChitGroup(
        name: 'Test Group',
        totalValue: 500000,
        totalMonths: 20,
      ),
      expect: () => [
        isA<ChitFundLoading>(),
        const ChitFundActionSuccess('Chit Group Created Successfully!'),
        isA<ChitFundLoading>(), // From reload
        isA<ChitFundInvitesLoaded>(), // From reload
      ],
    );

    // 2. Invitation Phase
    blocTest<ChitFundCubit, ChitFundState>(
      'Step 2: Admin sends an invite to a user',
      build: () {
        when(() => mockRepository.sendInvite('chit_123', '9876543210'))
            .thenAnswer((_) async => true);
            
        when(() => mockRepository.getCachedVacantChits()).thenAnswer((_) async => []);
        when(() => mockRepository.getCachedMyInvites()).thenAnswer((_) async => []);
        when(() => mockRepository.getCachedMyChits()).thenAnswer((_) async => []);
        when(() => mockRepository.getVacantChits()).thenAnswer((_) async => []);
        when(() => mockRepository.getMyInvites()).thenAnswer((_) async => []);
        when(() => mockRepository.getMyChits()).thenAnswer((_) async => []);

        return chitFundCubit;
      },
      act: (cubit) => cubit.sendInvite('chit_123', '9876543210'),
      expect: () => [
        const ChitFundActionSuccess('Invite sent successfully!'),
        isA<ChitFundLoading>(),
        isA<ChitFundInvitesLoaded>(),
      ],
    );

    // 3. User Accepts Invite
    blocTest<ChitFundCubit, ChitFundState>(
      'Step 3: User accepts the invite and joins the group',
      build: () {
        when(() => mockRepository.respondToInvite('inv_456', 'accepted'))
            .thenAnswer((_) async => true);
            
        when(() => mockRepository.getCachedVacantChits()).thenAnswer((_) async => []);
        when(() => mockRepository.getCachedMyInvites()).thenAnswer((_) async => []);
        when(() => mockRepository.getCachedMyChits()).thenAnswer((_) async => []);
        when(() => mockRepository.getVacantChits()).thenAnswer((_) async => []);
        when(() => mockRepository.getMyInvites()).thenAnswer((_) async => []);
        when(() => mockRepository.getMyChits()).thenAnswer((_) async => []);

        return chitFundCubit;
      },
      act: (cubit) => cubit.respondToInvite('inv_456', 'accepted'),
      expect: () => [
        const ChitFundActionSuccess('Invite Accepted & Joined!'),
        isA<ChitFundLoading>(),
        isA<ChitFundInvitesLoaded>(),
      ],
    );

    // 4. Open Auction
    blocTest<ChitFundCubit, ChitFundState>(
      'Step 4: Admin opens the live auction for the month',
      build: () {
        when(() => mockRepository.openAuctionMonth('chit_123', 1, 500000.0))
            .thenAnswer((_) async => true);
        
        when(() => mockRepository.getAdminDashboard('chit_123'))
            .thenAnswer((_) async => {'status': 'LIVE', 'activeMonth': 1});

        return chitFundCubit;
      },
      act: (cubit) => cubit.openAuctionMonth(
        chitId: 'chit_123',
        monthNumber: 1,
        baseAmount: 500000.0,
      ),
      expect: () => [
        isA<ChitFundLoading>(),
        const ChitFundActionSuccess('Auction opened successfully! Notifications sent.'),
        isA<ChitFundLoading>(),
        isA<ChitAdminDashboardLoaded>(),
      ],
    );

    // 5. Submit Bid
    blocTest<ChitFundCubit, ChitFundState>(
      'Step 5: User submits a discount bid during the live auction',
      build: () {
        when(() => mockRepository.submitBid('chit_123', 50000.0)) // Bidding 50k discount
            .thenAnswer((_) async => true);
            
        when(() => mockRepository.getAdminDashboard('chit_123'))
            .thenAnswer((_) async => {'status': 'LIVE'});

        return chitFundCubit;
      },
      act: (cubit) => cubit.submitBid(
        chitId: 'chit_123',
        bidDiscount: 50000.0,
      ),
      expect: () => [
        isA<ChitFundLoading>(),
        const ChitFundActionSuccess('Bid submitted successfully!'),
        isA<ChitFundLoading>(),
        isA<ChitAdminDashboardLoaded>(),
      ],
    );

    // 6. Finalize Auction & Distribute Dividends
    blocTest<ChitFundCubit, ChitFundState>(
      'Step 6: Auction completes, winner declared, dividends distributed',
      build: () {
        when(() => mockRepository.finalizeAuction(
              chitId: 'chit_123',
              winnerUserId: 'user_999',
              bidDiscount: 50000.0,
            )).thenAnswer((_) async => {'success': true});
            
        when(() => mockRepository.getAdminDashboard('chit_123'))
            .thenAnswer((_) async => {'status': 'COMPLETED'});

        return chitFundCubit;
      },
      act: (cubit) => cubit.manualFinalizeAuction(
        chitId: 'chit_123',
        winnerUserId: 'user_999',
        bidDiscount: 50000.0,
      ),
      expect: () => [
        isA<ChitFundLoading>(),
        const ChitFundActionSuccess('Auction Finalized successfully!'),
        isA<ChitFundLoading>(),
        isA<ChitAdminDashboardLoaded>(),
      ],
    );
  });
}
