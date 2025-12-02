import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsiOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsiOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('notification payload: $payload');
      // Navigate to the appropriate screen based on payload
      // You'll implement navigation logic here
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? type,
  }) async {
    // Customize notification style based on type
    AndroidNotificationDetails androidDetails = _getAndroidDetails(type);

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  AndroidNotificationDetails _getAndroidDetails(String? type) {
    Color ledColor;
    String channelId;
    String channelName;
    Importance importance;

    switch (type) {
      case 'payment_reminder':
        ledColor = const Color(0xFFF59E0B);
        channelId = 'payment_channel';
        channelName = 'Payment Notifications';
        importance = Importance.high;
        break;
      case 'booking_upcoming':
        ledColor = const Color(0xFF0077B6);
        channelId = 'booking_channel';
        channelName = 'Booking Notifications';
        importance = Importance.defaultImportance;
        break;
      case 'booking_accepted':
        ledColor = const Color(0xFF10B981);
        channelId = 'status_channel';
        channelName = 'Status Updates';
        importance = Importance.high;
        break;
      case 'booking_rejected':
        ledColor = const Color(0xFFEF4444);
        channelId = 'status_channel';
        channelName = 'Status Updates';
        importance = Importance.high;
        break;
      case 'room_suggestion':
        ledColor = const Color(0xFF8B5CF6);
        channelId = 'suggestion_channel';
        channelName = 'Suggestions';
        importance = Importance.low;
        break;
      default:
        ledColor = const Color(0xFF0077B6);
        channelId = 'general_channel';
        channelName = 'General Notifications';
        importance = Importance.defaultImportance;
    }

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for $channelName',
      importance: importance,
      priority: Priority.high,
      color: const Color(0xFF0077B6),
      ledColor: ledColor,
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: const BigTextStyleInformation(''),
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}