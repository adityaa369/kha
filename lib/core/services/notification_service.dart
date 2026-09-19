import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer';
import 'dart:async';

/// Top-level handler required by Firebase for background messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by this point.
  log('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Broadcast stream — foreground message data forwarded to listeners
  static final StreamController<RemoteMessage> onForegroundMessage =
      StreamController.broadcast();

  /// Broadcast stream — notification tap events (background/foreground)
  static final StreamController<RemoteMessage> onNotificationTap =
      StreamController.broadcast();

  static const _channelId = 'khatha_high_importance';
  static const _channelName = 'Khatha Notifications';

  static Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    log('[FCM] Auth status: ${settings.authorizationStatus}');

    // Android local notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Initialize local plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Local notification tapped in foreground — payload is raw JSON
        // We re-emit via onNotificationTap handled in NotificationListenerWidget
      },
    );

    // Foreground messages: show heads-up AND broadcast
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('[FCM] Foreground message: ${message.messageId}');
      onForegroundMessage.add(message);
      _showLocalNotification(message);
    });

    // Background → foreground tap — unified into onNotificationTap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('[FCM] Notification opened app: ${message.messageId}');
      onNotificationTap.add(message);
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id: message.messageId.hashCode & 0x7FFFFFFF,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
    );
  }

  static Future<String?> getToken() async {
    try {
      final token = await _fcm.getToken();
      log('[FCM] Token: $token');
      return token;
    } catch (e) {
      log('[FCM] Failed to get token: $e');
      return null;
    }
  }

  /// Expose token refresh stream for re-registration
  static Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;
}
