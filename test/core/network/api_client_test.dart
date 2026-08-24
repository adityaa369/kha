import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/core/network/api_client.dart';
import 'package:khatha/config/constants.dart';
import 'package:uuid/uuid.dart';

void main() {
  late HttpServer server;
  late String serverUrl;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serverUrl = 'http://${server.address.host}:${server.port}';
    
    // Override base url dynamically (Hack for testing)
    ApiClient().dio.options.baseUrl = serverUrl;
  });

  tearDown(() async {
    await server.close();
  });

  test('F.1 Normal request generates x-idempotency-key for mutations', () async {
    server.listen((HttpRequest request) {
      request.response
        ..statusCode = 200
        ..write('{"success":true}')
        ..close();
    });

    final response = await ApiClient().post('/test');
    
    expect(response.requestOptions.headers.containsKey('x-idempotency-key'), true);
    final key = response.requestOptions.headers['x-idempotency-key'];
    expect(Uuid.isValidUUID(fromString: key), true);
  });

  test('F.1 GET request does not generate idempotency key', () async {
    server.listen((HttpRequest request) {
      request.response
        ..statusCode = 200
        ..write('{"success":true}')
        ..close();
    });

    final response = await ApiClient().get('/test');
    expect(response.requestOptions.headers.containsKey('x-idempotency-key'), false);
  });

  test('F.1 Independent payments receive different keys', () async {
    server.listen((HttpRequest request) {
      request.response
        ..statusCode = 200
        ..write('{"success":true}')
        ..close();
    });

    final response1 = await ApiClient().post('/test1');
    final response2 = await ApiClient().post('/test2');

    final key1 = response1.requestOptions.headers['x-idempotency-key'];
    final key2 = response2.requestOptions.headers['x-idempotency-key'];

    expect(key1, isNot(equals(key2)));
  });
}
