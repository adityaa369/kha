import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import '../utils/secure_storage.dart';
import '../../config/constants.dart';
import '../error/failures.dart';
import 'package:uuid/uuid.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static void Function()? onUnauthorized;
  static void Function()? onTokenExpired;
  static void Function()? onMaintenanceMode;

  bool _isRefreshing = false;
  final List<Completer<bool>> _refreshQueue = [];

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Platform': 'flutter',
      },
    ),
  );

  ApiClient._internal() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // F.1 Network Hardening: Auto-inject idempotency key for mutations
          final method = options.method.toUpperCase();
          if (method == 'POST' || method == 'PUT' || method == 'PATCH') {
            if (!options.headers.containsKey('x-idempotency-key')) {
              options.headers['x-idempotency-key'] = const Uuid().v4();
            }
          }
          
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          DioException myException = e;

          if (e.response?.statusCode == 401 || e.response?.statusCode == 419) {
            final refreshed = await _trySingleFlightRefresh();
            
            if (refreshed) {
              try {
                final newToken = await SecureStorage.getToken();
                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {}
            }
            
            if (e.response?.statusCode == 419) {
              onTokenExpired?.call();
              myException = e.copyWith(error: const AuthFailure('Session expired, please login again'));
            } else {
              onUnauthorized?.call();
              myException = e.copyWith(error: const AuthFailure('Please login again'));
            }
          } else {
            // Standard error mappings
            switch (e.type) {
              case DioExceptionType.connectionTimeout:
              case DioExceptionType.sendTimeout:
              case DioExceptionType.receiveTimeout:
              case DioExceptionType.connectionError:
                myException = e.copyWith(error: const NetworkFailure());
                break;
              case DioExceptionType.badResponse:
                final responseData = e.response?.data;
                String? msg;
                String? code;
                if (responseData is Map) {
                  msg = responseData['message']?.toString();
                  code = responseData['code']?.toString();
                } else if (responseData is String) {
                  msg = responseData;
                }
                final statusCode = e.response?.statusCode ?? 500;
                
                // F.2 Emergency UX: Trap 503 Kill Switch response
                if (statusCode == 503) {
                  onMaintenanceMode?.call();
                  myException = e.copyWith(error: ServerFailure(msg ?? 'Financial operations are temporarily suspended.', code));
                  break;
                }
                
                // 4F-6: Structured Error Code Mapping
                if (code == 'RATE_LIMITED' || statusCode == 429) {
                  myException = e.copyWith(error: RateLimitedFailure(msg ?? 'Too many requests', code));
                } else if (code == 'INTENT_CONSUMED') {
                  myException = e.copyWith(error: IntentConsumedFailure(msg ?? 'Action already completed', code));
                } else if (code == 'OVERPAYMENT_REJECTED' || code == 'LOAN_FROZEN' || code == 'TERMINAL_STATE' || code == 'BUSINESS_ERROR') {
                  myException = e.copyWith(error: BusinessLogicFailure(msg ?? 'Operation rejected', code));
                } else if (code == 'INVALID_ID' || code == 'VALIDATION_ERROR') {
                  myException = e.copyWith(error: ValidationFailure(msg ?? 'Invalid request data', code));
                } else if (code == 'UNAUTHORIZED' || statusCode == 401) {
                  myException = e.copyWith(error: AuthFailure(msg ?? 'Session expired', code));
                } else if (code == 'FORBIDDEN' || statusCode == 403) {
                  myException = e.copyWith(error: AuthFailure(msg ?? 'Access denied', code));
                } else if (statusCode >= 500) {
                  myException = e.copyWith(error: ServerFailure(msg ?? 'Internal Server Error', code));
                } else {
                  myException = e.copyWith(error: ValidationFailure(msg ?? 'Request failed', code));
                }
                break;
              default:
                break;
            }
          }
          return handler.next(myException);
        },
      ),
    );

    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: kDebugMode ? print : (_) {},
        retries: 2,
        retryDelays: const [Duration(seconds: 1), Duration(seconds: 3)],
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final safeHeaders = Map<String, dynamic>.from(options.headers);
            if (safeHeaders.containsKey('Authorization')) safeHeaders['Authorization'] = 'Bearer [REDACTED]';
            debugPrint('[API] ${options.method} ${options.uri}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            return handler.next(response);
          },
          onError: (e, handler) {
            debugPrint('[API ERR] ${e.response?.statusCode} ${e.requestOptions.uri}');
            return handler.next(e);
          },
        ),
      );
    }
  }

  Future<bool> _trySingleFlightRefresh() async {
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        _resolveQueue(false);
        return false;
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: { 'Content-Type': 'application/json' },
      ));

      final response = await refreshDio.post('/auth/refresh', data: {
        'refreshToken': refreshToken
      });

      final data = response.data;
      if (data is Map && data['success'] == true && data['token'] != null && data['refreshToken'] != null) {
        await SecureStorage.saveToken(data['token'].toString());
        await SecureStorage.saveRefreshToken(data['refreshToken'].toString());
        _resolveQueue(true);
        return true;
      }
      _resolveQueue(false);
      return false;
    } catch (_) {
      _resolveQueue(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _resolveQueue(bool success) {
    for (var completer in _refreshQueue) {
      completer.complete(success);
    }
    _refreshQueue.clear();
  }

  Dio get dio => _dio;
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async => await _dio.get(path, queryParameters: queryParameters, options: options);
  Future<Response> post(String path, {dynamic data, Options? options}) async => await _dio.post(path, data: data, options: options);
  Future<Response> put(String path, {dynamic data}) async => await _dio.put(path, data: data);
  Future<Response> patch(String path, {dynamic data}) async => await _dio.patch(path, data: data);
  Future<Response> delete(String path, {dynamic data}) async => await _dio.delete(path, data: data);
}


