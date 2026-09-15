import 'package:flutter/services.dart';
import 'dart:io';

class SecurityUtils {
  static const MethodChannel _channel = MethodChannel('com.vest.khataa/security');

  static Future<void> secureScreen() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('secureScreen');
      } catch (e) {
        // Ignore errors or log them
      }
    }
  }

  static Future<void> unsecureScreen() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('unsecureScreen');
      } catch (e) {
        // Ignore errors or log them
      }
    }
  }
}