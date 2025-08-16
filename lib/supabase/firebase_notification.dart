
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotification {
  static final FirebaseNotification _notificationService =
  FirebaseNotification._internal();

  factory FirebaseNotification() {
    return _notificationService;
  }

  FirebaseNotification._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void init() async {
    // TODO: Need to assgin icon at AndroidInitializationSettings('')
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('');

    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void createNotification(String title, String details) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'local_notification',   // channelId:
        'local_notification', // channelName:
        channelDescription: '',
        importance: Importance.max,
        priority: Priority.max
    );

    NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics,
        iOS: null,
        linux: null,
        macOS: null);
    await flutterLocalNotificationsPlugin.show(
        Random().nextInt(100),
        title,
        details,
        platformChannelSpecifics,
        payload: '');
  }
}