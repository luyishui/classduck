import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: settings);
  }

  static Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'classduck_channel',
      'ClassDuck 通知',
      channelDescription: '用于课程和待办提醒',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
