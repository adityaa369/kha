import 'package:flutter/material.dart';
import '../network/exceptions.dart';

class ErrorHandler {
  static void showSnackBar(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred';
    
    if (error is AppException) {
      message = error.message;
    } else if (error is String) {
      message = error;
    } else if (error != null) {
      message = error.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
