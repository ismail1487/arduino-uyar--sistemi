//import 'package:audioplayers/audioplayers.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static Future initialize() async {
    const androidInitalize =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    const initializationSettings =
        InitializationSettings(android: androidInitalize);
    await _notifications.initialize(initializationSettings);
  }

  static Future _notificationDetails() async => const NotificationDetails(
          android: AndroidNotificationDetails(
        "CO2BİLDİRİMİ",
        "CO2",
        importance: Importance.max,
        //sound: RawResourceAndroidNotificationSound('alarm.mp3'),
      ));

  static Future showNotification({
    int id = 0,
    String title = "",
    String body = "",
  }) async =>
      _notifications.show(id, title, body, await _notificationDetails());
}
