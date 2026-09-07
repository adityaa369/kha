import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/core/network/api_client.dart';
import 'package:khatha/core/blocs/system/system_state_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

void main() {
  late HttpServer server;
  late String serverUrl;
  late SystemStateCubit systemStateCubit;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    const MethodChannel channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });

    dotenv.testLoad(fileInput: '''API_URL=http://localhost:5000''');

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serverUrl = 'http://${server.address.host}:${server.port}';
    ApiClient().dio.options.baseUrl = serverUrl;

    systemStateCubit = SystemStateCubit();
    ApiClient.onMaintenanceMode = () {
      systemStateCubit.pauseFinancialOperations();
    };
  });

  tearDown(() async {
    await server.close();
  });

  test(
    'F.2 Kill Switch response triggers global PAUSED state and preserves failure',
    () async {
      server.listen((HttpRequest request) {
        request.response
          ..statusCode = 503
          ..write(
            '{"success":false, "message":"Financial operations are temporarily suspended."}',
          )
          ..close();
      });

      expect(systemStateCubit.state, SystemState.normal);

      try {
        await ApiClient().post('/test');
        fail('Expected DioException');
      } on DioException catch (e) {
        // original API failure preserved
        expect(e.response?.statusCode, 503);
      }

      // Global state transitioned to paused
      expect(systemStateCubit.state, SystemState.financialOperationsPaused);
    },
  );

  test('F.2 Recovery to NORMAL state works', () async {
    systemStateCubit.pauseFinancialOperations();
    expect(systemStateCubit.state, SystemState.financialOperationsPaused);
    systemStateCubit.resumeOperations();
    expect(systemStateCubit.state, SystemState.normal);
  });

  test('F.2 Unrelated 500 error does NOT trigger PAUSED state', () async {
    server.listen((HttpRequest request) {
      request.response
        ..statusCode = 500
        ..write('{"success":false, "message":"Database crash"}')
        ..close();
    });

    try {
      await ApiClient().post('/test-500');
    } catch (_) {}

    // State should remain normal
    expect(systemStateCubit.state, SystemState.normal);
  });
}
