import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:khatha/data/repositories/loan_repository.dart';
import 'package:khatha/core/network/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}
class MockUser extends Mock implements User {}

void main() {
  late LoanRepository loanRepository;
  late MockApiClient mockApi;
  late MockUser mockUser;
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockApi = MockApiClient();
    mockDio = MockDio();
    mockUser = MockUser();

    when(() => mockApi.dio).thenReturn(mockDio);
    
    loanRepository = TestableLoanRepository(api: mockApi, mockUser: mockUser);
  });

  group('4F-3 API Contract Tests', () {
    test('1 & 2: Valid idToken is sent, legacy otp is removed for recordPayment', () async {
      when(() => mockUser.getIdToken(any())).thenAnswer((_) async => 'mock_firebase_token');
      when(() => mockApi.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'success': true},
          statusCode: 200,
        ),
      );

      await loanRepository.recordPayment('loan_1', amountRupees: 10000);

      final captured = verify(() => mockApi.post('/loans/loan_1/record-payment', data: captureAny(named: 'data'))).captured;
      final payload = captured.first as Map<String, dynamic>;

      expect(payload.containsKey('idToken'), isTrue);
      expect(payload['idToken'], 'mock_firebase_token');
      expect(payload.containsKey('otp'), isFalse);
      expect(payload.containsKey('verificationId'), isFalse);
      
      expect(payload['amount'], 10000.0);
    });

    test('3 & 4: Expired Firebase ID token refreshes correctly and retries', () async {
      when(() => mockUser.getIdToken(false)).thenAnswer((_) async => 'expired_token');
      when(() => mockUser.getIdToken(true)).thenAnswer((_) async => 'fresh_token');
      
      when(() => mockApi.post('/loans/loan_1/record-payment', data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/loans/loan_1/record-payment', data: {'amount': 5000.0, 'idToken': 'expired_token'}),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'success': false, 'message': 'Invalid idToken'},
          ),
        ),
      );

      when(() => mockDio.fetch(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'success': true},
          statusCode: 200,
        ),
      );

      final result = await loanRepository.recordPayment('loan_1', amountRupees: 5000);
      expect(result, isTrue);

      verify(() => mockUser.getIdToken(true)).called(1); 
      
      final capturedFetch = verify(() => mockDio.fetch(captureAny())).captured;
      final retryOptions = capturedFetch.first as RequestOptions;
      expect(retryOptions.data['idToken'], 'fresh_token');
    });
  });
}

class TestableLoanRepository extends LoanRepository {
  final MockUser mockUser;
  TestableLoanRepository({required super.api, required this.mockUser});

  @override
  Future<String> getValidIdToken({bool forceRefresh = false}) async {
    final token = await mockUser.getIdToken(forceRefresh);
    if (token == null) throw Exception('No token');
    return token;
  }
}
