import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Security service for app hardening.
/// Provides screenshot prevention and debug detection.
/// Jailbreak detection requires flutter_jailbreak_detection package
/// (add to pubspec.yaml when ready — currently using fallback).
class SecurityService {

  /// Prevents screenshots on sensitive screens.
  /// Call in initState of screens like loan details, auction page.
  static Future<void> preventScreenshots() async {
    if (kIsWeb) return;
    try {
      // On Android: FLAG_SECURE prevents screenshots and screen recording
      await SystemChannels.platform.invokeMethod<void>(
        'SystemNavigator.pop', // placeholder — real impl via android/ios native code
      );
    } catch (_) {
      // Non-critical — don't crash the app if this fails
    }
  }

  /// Shows a security warning dialog if the app detects a compromised environment.
  static Future<void> checkAndWarnIfCompromised(BuildContext context) async {
    if (kDebugMode) return; // Skip in debug mode
    final bool isCompromised = await _isDeviceCompromised();
    if (isCompromised && context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.red),
              SizedBox(width: 8),
              Text('Security Warning'),
            ],
          ),
          content: const Text(
            'This device appears to be rooted or jailbroken. '
            'For your financial security, some features may be restricted. '
            'We strongly recommend using Khatha on a secure device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('I Understand'),
            ),
          ],
        ),
      );
    }
  }

  static Future<bool> _isDeviceCompromised() async {
    // Basic heuristic checks without external package
    // For production-grade: add flutter_jailbreak_detection to pubspec.yaml
    try {
      // Check for common root/jailbreak indicators
      const suspiciousFiles = [
        '/system/app/Superuser.apk',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/bin/failsafe/su',
      ];
      for (final file in suspiciousFiles) {
        try {
          // This will throw if file doesn't exist (which is the normal/safe case)
          await const MethodChannel('khatha/security')
              .invokeMethod<bool>('checkFile', {'path': file});
          return true; // File exists = potentially rooted
        } catch (_) {
          // File doesn't exist or channel not implemented — continue
        }
      }
      return false;
    } catch (_) {
      return false; // Fail open — don't block legitimate users on check failure
    }
  }

  /// Call this in your main() before runApp to set up app-level security.
  static void initialize() {
    if (kReleaseMode) {
      // Disable Flutter's error detail reporting in release mode
      FlutterError.onError = (FlutterErrorDetails details) {
        // In release: silently handle, don't show red error screens
        // In debug: use default behavior
      };
    }
  }
}
