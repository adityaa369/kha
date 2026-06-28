class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException([this.message = 'Something went wrong', this.prefix]);

  @override
  String toString() {
    return "${prefix != null ? '$prefix: ' : ''}$message";
  }
}

class NetworkException extends AppException {
  NetworkException([String message = 'Please check your internet connection'])
    : super(message, 'Network Error');
}

class ServerException extends AppException {
  ServerException([String message = 'Internal Server Error'])
    : super(message, 'Server Error');
}

class AuthException extends AppException {
  AuthException([String message = 'Unauthorized'])
    : super(message, 'Auth Error');
}

class BadRequestException extends AppException {
  BadRequestException([String message = 'Invalid Request'])
    : super(message, 'Bad Request');
}
