import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../utils/secure_storage.dart';
import '../../config/constants.dart';
import '../error/failures.dart';

class ApiClient {
  static void Function()? onUnauthorized;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
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
          myException = e.copyWith(error: const AuthFailure('Please login again'));
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
                myException = e.copyWith(error: ServerFailure(msg ?? 'Internal Server Error'));
              } else if (statusCode == 403) {
                myException = e.copyWith(error: AuthFailure(msg ?? 'Access denied'));
              } else {
                myException = e.copyWith(error: ValidationFailure(msg ?? 'Request failed'));
              }
              break;
            default:
              break;
          }
        }
        
        return handler.next(myException);
      },
    ));

    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logPrint: print,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ));

    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    ));
  }

  Dio get dio => _dio;

  // Helper methods for common requests
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
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
