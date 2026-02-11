import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://your-api-domain.com/api/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  static void setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token from secure storage
        // final token = await SecureStorage.getToken();
        // if (token != null) {
        //   options.headers['Authorization'] = 'Bearer $token';
        // }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle token refresh or logout
        }
        return handler.next(error);
      },
    ));
  }

  static Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  static Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  static Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  static Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}