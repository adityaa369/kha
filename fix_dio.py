import re

with open('lib/core/network/api_client.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''      RetryInterceptor(
        dio: _dio,
        logPrint: kDebugMode ? print : (_) {},
        retries: 2,
        retryDelays: const [Duration(seconds: 1), Duration(seconds: 3)],
        retryEvaluator: (DioException error, int attempt) {
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
        },
      ),'''

content = content.replace("      RetryInterceptor(\n        dio: _dio,\n        logPrint: kDebugMode ? print : (_) {},\n        retries: 2,\n        retryDelays: const [Duration(seconds: 1), Duration(seconds: 3)],\n      ),", replacement)

with open('lib/core/network/api_client.dart', 'w', encoding='utf-8') as f:
    f.write(content)
