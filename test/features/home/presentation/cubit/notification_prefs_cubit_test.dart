import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:khatha/core/network/api_client.dart';
import 'package:khatha/data/models/notification_preferences.dart';
import 'package:khatha/features/home/presentation/cubit/notification_prefs_cubit.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
  });

  group('NotificationPrefsCubit', () {
    test('initial state is NotificationPrefsInitial', () {
      expect(NotificationPrefsCubit(mockApi).state, isA<NotificationPrefsInitial>());
    });

    blocTest<NotificationPrefsCubit, NotificationPrefsState>(
      'load() emits Loading then Loaded when successful',
      build: () {
        when(() => mockApi.get('/users/notification-preferences')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: {
              'success': true,
              'preferences': {
                'loanUpdates': false,
                'paymentUpdates': true,
              }
            },
          ),
        );
        return NotificationPrefsCubit(mockApi);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NotificationPrefsLoading>(),
        isA<NotificationPrefsLoaded>().having((s) => s.prefs.loanUpdates, 'loanUpdates', false),
      ],
    );

    blocTest<NotificationPrefsCubit, NotificationPrefsState>(
      'update() emits optimistic update, then succeeds',
      build: () {
        when(() => mockApi.put('/users/notification-preferences', data: any(named: 'data')))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(path: ''),
                  data: {'success': true},
                ));
        return NotificationPrefsCubit(mockApi);
      },
      seed: () => const NotificationPrefsLoaded(
        prefs: NotificationPreferences(loanUpdates: true),
      ),
      act: (cubit) => cubit.update(const NotificationPreferences(loanUpdates: false)),
      expect: () => [
        isA<NotificationPrefsLoaded>()
            .having((s) => s.prefs.loanUpdates, 'loanUpdates', false)
            .having((s) => s.isSaving, 'isSaving', true),
        isA<NotificationPrefsLoaded>()
            .having((s) => s.prefs.loanUpdates, 'loanUpdates', false)
            .having((s) => s.isSaving, 'isSaving', false),
      ],
    );
    
    blocTest<NotificationPrefsCubit, NotificationPrefsState>(
      'update() reverts state on error',
      build: () {
        when(() => mockApi.put('/users/notification-preferences', data: any(named: 'data')))
            .thenThrow(DioException(requestOptions: RequestOptions(path: '')));
        return NotificationPrefsCubit(mockApi);
      },
      seed: () => const NotificationPrefsLoaded(
        prefs: NotificationPreferences(loanUpdates: true),
      ),
      act: (cubit) => cubit.update(const NotificationPreferences(loanUpdates: false)),
      expect: () => [
        isA<NotificationPrefsLoaded>()
            .having((s) => s.prefs.loanUpdates, 'loanUpdates', false)
            .having((s) => s.isSaving, 'isSaving', true),
        isA<NotificationPrefsLoaded>()
            .having((s) => s.prefs.loanUpdates, 'loanUpdates', true) // Reverted
            .having((s) => s.isSaving, 'isSaving', false)
            .having((s) => s.saveError, 'saveError', isNotNull),
      ],
    );
  });
}
