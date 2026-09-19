with open('lib/core/network/api_client.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_eval = '''        retryEvaluator: (DioException error, int attempt) {
          final statusCode = error.response?.statusCode;
          // Do NOT retry on 401, 403, or 429
          if (statusCode == 401 || statusCode == 403 || statusCode == 429) {
            return false;
          }
          // Retry on 5xx or network errors
          if (statusCode != null && statusCode >= 500 && statusCode < 600) {
            return true;
          }
          return error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError;
        },'''

new_eval = '''        retryEvaluator: (DioException error, int attempt) {
          final statusCode = error.response?.statusCode;
          final method = error.requestOptions.method.toUpperCase();
          
          // Do NOT retry on 401, 403, or 429
          if (statusCode == 401 || statusCode == 403 || statusCode == 429) {
            return false;
          }
          
          // Only safely retry GET requests
          if (method != 'GET') {
            return false;
          }

          // Retry on 5xx or network errors for GET only
          if (statusCode != null && statusCode >= 500 && statusCode < 600) {
            return true;
          }
          return error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError;
        },'''

content = content.replace(old_eval, new_eval)

with open('lib/core/network/api_client.dart', 'w', encoding='utf-8') as f:
    f.write(content)
