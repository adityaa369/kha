import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khatha/core/blocs/loans/interest_schedule_cubit.dart';
import 'package:khatha/data/repositories/loan_repository.dart';
import 'package:khatha/data/models/interest_schedule_model.dart';
import 'package:khatha/core/error/failures.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late MockLoanRepository mockRepo;
  late InterestScheduleCubit cubit;

  setUp(() {
    mockRepo = MockLoanRepository();
    cubit = InterestScheduleCubit(repository: mockRepo);
  });

  group('4F-4E Interest UI & Accrual Presentation', () {
    test(
      '4 & 5 & 6. Accrued, Paid, Outstanding interest originate from backend ledger',
      () async {
        // Setup the authoritative backend response
        const authoritativeSchedule = InterestScheduleModel(
          totalAccruedPaise: 99,
          totalPaidPaise: 50,
          outstandingInterestPaise: 49,
          originalPrincipalPaise: 100000, // 1000 INR
          interestRateBps: 1200, // 12%
          interestMethod: 'SIMPLE_ORIGINAL_PRINCIPAL',
          schedule: [
            InterestPeriodViewModel(
              month: 'August 2026',
              accruedPaise: 99,
              paidPaise: 50,
            ),
          ],
        );

        when(
          () => mockRepo.getInterestSchedule('loan123'),
        ).thenAnswer((_) async => authoritativeSchedule);

        await cubit.fetchSchedule('loan123');

        expect(cubit.state, isA<InterestScheduleLoaded>());
        final loaded = (cubit.state as InterestScheduleLoaded).schedule;

        // Verification: Flutter passes through the backend values and does NOT compute 0.99 itself.
        expect(loaded.totalAccruedPaise, 99);
        expect(loaded.totalPaidPaise, 50);
        expect(loaded.outstandingInterestPaise, 49);
        expect(loaded.schedule.first.month, 'August 2026');

        verify(() => mockRepo.getInterestSchedule('loan123')).called(1);
      },
    );

    test('13. Network failure preserves last known values', () async {
      // First load succeeds
      const authoritativeSchedule = InterestScheduleModel(
        totalAccruedPaise: 99,
        totalPaidPaise: 50,
        outstandingInterestPaise: 49,
        originalPrincipalPaise: 100000,
        interestRateBps: 1200,
        interestMethod: 'SIMPLE',
        schedule: [],
      );
      when(
        () => mockRepo.getInterestSchedule('loan123'),
      ).thenAnswer((_) async => authoritativeSchedule);
      await cubit.fetchSchedule('loan123');

      // Second load fails
      when(
        () => mockRepo.getInterestSchedule('loan123'),
      ).thenThrow(const NetworkFailure());
      await cubit.fetchSchedule('loan123');

      expect(cubit.state, isA<InterestScheduleError>());
      final errorState = cubit.state as InterestScheduleError;

      // Verification: The previous valid state is preserved
      expect(errorState.lastKnownData, isNotNull);
      expect(errorState.lastKnownData!.totalAccruedPaise, 99);
    });
  });
}
