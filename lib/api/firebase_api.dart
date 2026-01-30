import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final _localNotification = FlutterLocalNotificationsPlugin();
const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications',
  importance: Importance.defaultImportance,
);

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  final data = message.data;
  var route = data['route'];

  print("Handle Background Message : route $route");

  if (route != null) {
    if (route[0] != '/') {
      route = "/$route";
    }

    print("Route not null (background) : $route");

    handleNotificationAction(route, data);
  } else {
    navigatorKey.currentState?.pushReplacementNamed('/index');
  }
}

// function go to route
Future<void> handleNotificationAction(
    String route, Map<String, dynamic> data) async {
  print("Handle Notification Action : jumping to route $route");

  navigatorKey.currentState?.pushNamed(route, arguments: data);
}

Future<void> handleMessage(RemoteMessage message) async {
  final data = message.data;
  var route = data['route'] ?? data['routes'];

  print("Handle Message : Message Data : $data");
  print("Handle Message : route $route");

  if (route != null) {
    if (route[0] != '/') {
      route = "/$route";
    }

    print("Route not null : $route");

    handleNotificationAction(route, data);
  } else {
    navigatorKey.currentState?.pushReplacementNamed('/index');
  }
}

Future initLocalNotification() async {
  const iOS = DarwinInitializationSettings();
  const android = AndroidInitializationSettings('@drawable/launcher_icon');
  const settings = InitializationSettings(iOS: iOS, android: android);

  await _localNotification.initialize(
    settings,
    onDidReceiveNotificationResponse: (details) {
      final message = RemoteMessage.fromMap(jsonDecode(details.payload!));
      handleMessage(message);
    },
  );

  final platform = _localNotification.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await platform?.createNotificationChannel(_androidChannel);
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
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: _androidChannel.importance,
          icon: "@drawable/launcher_icon",
        ),
      ),
      payload: jsonEncode(message.toMap()),
    );
  });
}

class FirebaseApi {
  Future<void> initNotif(BuildContext context) async {
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
    initPushNotification();
    initLocalNotification();
  }
}
