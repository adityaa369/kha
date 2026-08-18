import 'package:flutter/material.dart';
import '../network/exceptions.dart';
import 'dialog_utils.dart';

class ErrorHandler {
  static void showError(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred';

    if (error is AppException) {
      message = error.message;
    } else if (error is String) {
      message = error;
    } else if (error != null) {
      message = error.toString();
    }

    DialogUtils.showErrorDialog(context, message);
  }
}
