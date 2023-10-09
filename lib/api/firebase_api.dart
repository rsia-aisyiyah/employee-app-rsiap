import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rsia_employee_app/screen/menu/cuti.dart';
import 'package:rsia_employee_app/screen/menu/otp_jasa_medis.dart';

late BuildContext ctx;
FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final _localNotification = FlutterLocalNotificationsPlugin();
final _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications',
  importance: Importance.defaultImportance,
);

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  Navigator.of(ctx).push(
    MaterialPageRoute(
      builder: (context) => const OtpJasaMedis(),
    ),
  );
}

Future<void> handleMessage(RemoteMessage message) async {
  Navigator.of(ctx).push(
    MaterialPageRoute(
      builder: (context) => const OtpJasaMedis(),
    ),
  );
}

Future initLocalNotification() async {
  const iOS = DarwinInitializationSettings();
  const android = AndroidInitializationSettings('@drawable/launcher_icon');
  final settings = InitializationSettings(iOS: iOS, android: android);

  await _localNotification.initialize(
    settings,
    onDidReceiveNotificationResponse: (details) {
      final message = RemoteMessage.fromMap(jsonDecode(details.payload!));
      handleMessage(message);
    },
  );

  final platform = _localNotification.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()!;
  platform.createNotificationChannel(_androidChannel);
}

Future initPushNotification() async {
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  FirebaseMessaging.instance.getInitialMessage().then((initialMessage) {
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotification.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
            _androidChannel.id, _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: _androidChannel.importance,
            icon: "@drawable/launcher_icon"),
      ),
      payload: jsonEncode(message.toMap()),
    );
  });
}

class FirebaseApi {
  Future<void> initNotif(BuildContext context) async {
    ctx = context;
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    final fCMToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fCMToken');
    print(ctx);
    initPushNotification();
    initLocalNotification();
  }
}
