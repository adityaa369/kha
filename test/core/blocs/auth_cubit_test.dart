import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';
import 'package:khatha/core/network/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late AuthCubit authCubit;

  setUp(() {
    mockApiClient = MockApiClient();
    authCubit = AuthCubit(api: mockApiClient);
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit - sendOtp', () {
    const String testPhone = '9876543210';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, OtpSent] when API call is successful',
      build: () {
        when(() => mockApiClient.post(any(), data: any(named: 'data')))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(path: '/auth/send-otp'),
                  data: {'success': true},
                  statusCode: 200,
                ));
        return authCubit;
      },
      act: (cubit) => cubit.sendOtp(testPhone),
      expect: () => [
        isA<AuthLoading>(),
        isA<OtpSent>().having((s) => s.phone, 'phone', testPhone),
      ],
      verify: (_) {
        verify(() => mockApiClient.post('/auth/send-otp', data: {'phone': testPhone})).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when API call fails',
      build: () {
        when(() => mockApiClient.post(any(), data: any(named: 'data')))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(path: '/auth/send-otp'),
                  data: {'success': false, 'message': 'Invalid phone number'},
                  statusCode: 400,
                ));
        return authCubit;
      },
      act: (cubit) => cubit.sendOtp(testPhone),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((s) => s.message, 'message', 'Invalid phone number'),
      ],
    );
  });
}
