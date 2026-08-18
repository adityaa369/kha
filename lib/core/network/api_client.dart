import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import '../utils/secure_storage.dart';
import '../../config/constants.dart';
import '../error/failures.dart';

class ApiClient {
  static void Function()? onUnauthorized;
  static void Function()? onTokenExpired;

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

  ApiClient() {
    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          DioException myException = e;

          if (e.response?.statusCode == 401) {
            onUnauthorized?.call();
            myException = e.copyWith(
              error: const AuthFailure('Please login again'),
            );
          } else if (e.response?.statusCode == 419) {
            // Token expired — server returns 419
            onTokenExpired?.call();
            myException = e.copyWith(
              error: const AuthFailure('Session expired, please login again'),
            );
          } else {
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
                if (responseData is Map) {
                  msg = responseData['message']?.toString();
                } else if (responseData is String) {
                  msg = responseData;
                }
                final statusCode = e.response?.statusCode ?? 500;
                if (statusCode >= 500) {
                  myException = e.copyWith(
                    error: ServerFailure(msg ?? 'Internal Server Error'),
                  );
                } else if (statusCode == 403) {
                  myException = e.copyWith(
                    error: AuthFailure(msg ?? 'Access denied'),
                  );
                } else {
                  myException = e.copyWith(
                    error: ValidationFailure(msg ?? 'Request failed'),
                  );
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

    // Retry interceptor — only retry on network errors, NOT auth errors
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: kDebugMode ? print : (_) {},
        retries: 2,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 3),
        ],
      ),
    );

    // Logger — ONLY in debug/profile mode, never in release
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Scrub sensitive headers before logging
            final safeHeaders = Map<String, dynamic>.from(options.headers);
            if (safeHeaders.containsKey('Authorization')) {
              safeHeaders['Authorization'] = 'Bearer [REDACTED]';
            }
            debugPrint('[API] ${options.method} ${options.uri}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('[API] ${response.statusCode} ${response.requestOptions.uri}');
            return handler.next(response);
          },
          onError: (e, handler) {
            debugPrint('[API ERR] ${e.response?.statusCode} ${e.requestOptions.uri}: ${e.message}');
            return handler.next(e);
          },
        ),
      );
    }
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await _dio.delete(path, data: data);
  }
}
