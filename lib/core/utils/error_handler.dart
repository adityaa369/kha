import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../network/exceptions.dart';
import 'dialog_utils.dart';
import '../error/failures.dart';
import 'user_message.dart';

class ErrorHandler {
  static void showError(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred';

    if (error is Failure) {
      message = error.message;
    } else if (error is DioException && error.error is Failure) {
      message = (error.error as Failure).message;
    } else if (error is DioException &&
        error.response != null &&
        error.response!.data is Map &&
        error.response!.data['message'] != null) {
      message = error.response!.data['message'];
    } else if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
          message = UserMessage.noInternet;
          break;
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = UserMessage.timeout;
          break;
        default:
          message = UserMessage.generic;
      }
    } else if (error is AppException) {
      message = error.message;
    } else if (error is String) {
      message = error;
    } else if (error != null) {
      message = UserMessage.generic;
    }

    DialogUtils.showErrorDialog(context, message);
  }
}
