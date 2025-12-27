import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
    }

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(initializationSettings);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
      }
      _showLocalNotification(message);
    });

    // 4. Handle Background Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const BigTextStyleInformation bigTextStyleInformation =
        BigTextStyleInformation(
      '',
      htmlFormatBigText: true,
      contentTitle: '',
      htmlFormatContentTitle: true,
      summaryText: '',
      htmlFormatSummaryText: true,
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pulse_channel_high',
      'Pulse Heartbeats',
      channelDescription: 'Real-time notifications for your inner circle.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFF6750A4), // Pulse Deep Purple
      ledColor: Color(0xFFFFB6C1), // Pulse Pink
      ledOnMs: 1000,
      ledOffMs: 500,
      enableLights: true,
      enableVibration: true,
      styleInformation: bigTextStyleInformation,
      ticker: 'New Pulse received',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Pulse 💓',
      message.notification?.body ?? 'New heartbeat waiting for you.',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  static Future<void> registerDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        await _sendTokenToBackend(token);
      }
      
      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiService.dio.post('auth/register-fcm/', data: {
        'fcm_token': token,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending token to backend: $e');
      }
    }
  }
}

// Global background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}
