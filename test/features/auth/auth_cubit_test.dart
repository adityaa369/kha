import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';
import 'package:khatha/core/network/api_client.dart';
import 'package:khatha/core/utils/secure_storage.dart';
import 'package:khatha/data/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthCubit authCubit;
  late MockApiClient mockApiClient;

  const kycCompleteUser = UserModel(
    id: 'user_1',
    firstName: 'John',
    lastName: 'Doe',
    phone: '+919999999999',
    email: 'john@example.com',
    isEmailVerified: true,
    pan: 'ABCDE1234F',
    aadhar: '123456789012',
    dob: '1990-01-01',
  );

  const kycIncompleteUser = UserModel(
    id: 'user_1',
    firstName: 'John',
    lastName: 'Doe',
    phone: '+919999999999',
    email: 'john@example.com',
    isEmailVerified: true,
  );

  const emailUnverifiedUser = UserModel(
    id: 'user_1',
    firstName: 'John',
    lastName: 'Doe',
    phone: '+919999999999',
    email: 'john@example.com',
    isEmailVerified: false,
    pan: 'ABCDE1234F',
    aadhar: '123456789012',
    dob: '1990-01-01',
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    mockApiClient = MockApiClient();
    authCubit = AuthCubit(api: mockApiClient);
  });

  tearDown(() {
    authCubit.close();
  });

  group('4F-2 Boot & Authoritative State Tests', () {
    
    // 1. App boot with valid token
    blocTest<AuthCubit, AuthState>(
      'App boot with valid token emits AuthenticatedKycComplete',
      setUp: () async {
        await SecureStorage.saveToken('valid_token');
        await SecureStorage.saveUserData(jsonEncode(kycCompleteUser.toFullJson()));
        when(() => mockApiClient.get('/auth/me')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/auth/me'),
            data: {'success': true, 'user': kycCompleteUser.toFullJson()},
            statusCode: 200,
          ),
        );
      },
      build: () => authCubit,
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthInitial>(),
        isA<AuthenticatedKycComplete>(),
      ],
    );

    // 2. App boot with expired token / 3. revoked user
    blocTest<AuthCubit, AuthState>(
      'App boot with revoked/expired token forces logout and emits Unauthenticated',
      setUp: () async {
        await SecureStorage.saveToken('expired_token');
        when(() => mockApiClient.get('/auth/me')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/me'),
            response: Response(requestOptions: RequestOptions(path: '/'), statusCode: 401),
          ),
        );
      },
      build: () => authCubit,
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthInitial>(),
        isA<Unauthenticated>(),
      ],
      verify: (_) async {
        final token = await SecureStorage.getToken();
        expect(token, isNull);
      }
    );

    // 4. /auth/me timeout & 5. network failure
    blocTest<AuthCubit, AuthState>(
      'App boot with network timeout falls back to AuthOffline',
      setUp: () async {
        await SecureStorage.saveToken('valid_token');
        await SecureStorage.saveUserData(jsonEncode(kycCompleteUser.toFullJson()));
        when(() => mockApiClient.get('/auth/me')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/me'),
            type: DioExceptionType.connectionTimeout,
          ),
        );
      },
      build: () => authCubit,
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthInitial>(),
        isA<AuthOffline>(),
      ],
    );

    // 6. email-unverified routing check
    blocTest<AuthCubit, AuthState>(
      'Emits AuthenticatedEmailUnverified if email is not verified',
      setUp: () async {
        await SecureStorage.saveToken('valid_token');
        when(() => mockApiClient.get('/auth/me')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/auth/me'),
            data: {'success': true, 'user': emailUnverifiedUser.toFullJson()},
            statusCode: 200,
          ),
        );
      },
      build: () => authCubit,
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthInitial>(),
        isA<AuthenticatedEmailUnverified>(),
      ],
    );

    // 7. KYC-incomplete routing check
    blocTest<AuthCubit, AuthState>(
      'Emits AuthenticatedEmailVerifiedKycIncomplete if KYC missing',
      setUp: () async {
        await SecureStorage.saveToken('valid_token');
        when(() => mockApiClient.get('/auth/me')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/auth/me'),
            data: {'success': true, 'user': kycIncompleteUser.toFullJson()},
            statusCode: 200,
          ),
        );
      },
      build: () => authCubit,
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthInitial>(),
        isA<AuthenticatedEmailVerifiedKycIncomplete>(),
      ],
    );

    // 9. Logout
    blocTest<AuthCubit, AuthState>(
      'Logout clears auth data and emits Unauthenticated',
      setUp: () async {
        await SecureStorage.saveToken('valid_token');
      },
      build: () => authCubit,
      act: (cubit) => cubit.logout(),
      expect: () => [
        isA<AuthLoading>(),
        isA<Unauthenticated>(),
      ],
      verify: (_) async {
        final token = await SecureStorage.getToken();
        expect(token, isNull);
      }
    );
  });
}
