import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';
import 'package:khatha/core/network/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'read') return null;
          if (methodCall.method == 'write') return null;
          if (methodCall.method == 'delete') return null;
          return null;
        });
  });

  late MockApiClient mockApiClient;
  late AuthCubit authCubit;

  setUp(() {
    mockApiClient = MockApiClient();
    authCubit = AuthCubit(api: mockApiClient);
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit - savePersonalDetails', () {
    const String testPhone = '9876543210';
    const String testEmail = 'test@example.com';
    const String firstName = 'John';
    const String lastName = 'Doe';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthenticatedEmailUnverified] when API call is successful',
      build: () {
        when(
          () => mockApiClient.put(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/auth/register'),
            data: {
              'success': true,
              'user': {
                'id': '123',
                'firstName': firstName,
                'lastName': lastName,
                'phone': testPhone,
                'email': testEmail,
                'isVerified': true,
                'city': '',
                'address': '',
                'pan': '',
                'aadhar': '',
                'dob': '',
                'gender': '',
              },
            },
            statusCode: 200,
          ),
        );
        return authCubit;
      },
      act: (cubit) => cubit.savePersonalDetails(
        firstName: firstName,
        lastName: lastName,
        email: testEmail,
        phone: testPhone,
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthenticatedEmailUnverified>()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when API call fails',
      build: () {
        when(
          () => mockApiClient.put(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/auth/register'),
            data: {'success': false, 'message': 'Failed to save details'},
            statusCode: 400,
          ),
        );
        return authCubit;
      },
      act: (cubit) => cubit.savePersonalDetails(
        firstName: firstName,
        lastName: lastName,
        email: testEmail,
        phone: testPhone,
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          'Failed to save details',
        ),
        isA<Unauthenticated>(),
      ],
    );
  });
}
