import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rsia_employee_app/utils/menu_navigator.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final _localNotification = FlutterLocalNotificationsPlugin();

// Channel dengan importance MAX agar notif muncul sebagai heads-up / alert
const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications',
  importance: Importance.max, // FIXED: was defaultImportance (silent)
  playSound: true,
);

// Top-level background handler – harus di-register sebelum app init
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  final data = message.data;
  var route = data['route'];
  print("Handle Background Message : route $route");
}

// Navigasi ke route tertentu berdasarkan payload notifikasi
Future<void> handleNotificationAction(
    String route, Map<String, dynamic> data) async {
  print("Handle Notification Action : jumping to route $route");

  String routeKey = route;
  if (routeKey.startsWith('/')) {
    routeKey = routeKey.substring(1);
  }

  final BuildContext? context = navigatorKey.currentContext;
  if (context != null) {
    final widget = MenuNavigator.getWidget(routeKey);
    if (widget != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => widget),
      );
      return;
    }
  }

  navigatorKey.currentState?.pushNamed(route, arguments: data);
}

Future<void> handleMessage(RemoteMessage message) async {
  final data = message.data;
  var route = data['route'] ?? data['routes'];

  print("Handle Message : Message Data : $data");
  print("Handle Message : route $route");

  if (route != null) {
    if (route.isNotEmpty && route[0] != '/') {
      route = "/$route";
    }
    handleNotificationAction(route, data);
  } else {
    navigatorKey.currentState?.pushReplacementNamed('/index');
  }
}

/// Menampilkan notifikasi lokal dari RemoteMessage (foreground)
void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;

  // Ambil title & body: prioritaskan dari notification, fallback ke data
  final String title = notification?.title ?? message.data['title'] ?? 'MESSA';
  final String body  = notification?.body  ?? message.data['body']  ?? '';

  if (title.isEmpty && body.isEmpty) return;

  _localNotification.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@drawable/launcher_icon',
        // Heads-up display (peek) agar notif muncul di atas layar
        fullScreenIntent: false,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(message.toMap()),
  );
}

Future<void> initLocalNotification() async {
  const iOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const android = AndroidInitializationSettings('@drawable/launcher_icon');
  const settings = InitializationSettings(iOS: iOS, android: android);

  await _localNotification.initialize(
    settings,
    onDidReceiveNotificationResponse: (details) {
      if (details.payload == null) return;
      try {
        final message = RemoteMessage.fromMap(jsonDecode(details.payload!));
        handleMessage(message);
      } catch (e) {
        print("Error parsing notification payload: $e");
      }
    },
  );

  // Buat channel dengan importance MAX (penting untuk Android 8+)
  final platform = _localNotification.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await platform?.createNotificationChannel(_androidChannel);
}

Future<void> initPushNotification() async {
  // Register background handler SEBELUM apapun
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  // Foreground presentation options (iOS)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Handle saat app dibuka dari notifikasi (terminated state)
  FirebaseMessaging.instance.getInitialMessage().then((initialMessage) {
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }
  });

  // Handle saat app di-background dan notif di-tap
  FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

  // Handle saat app foreground – tampilkan notifikasi lokal
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground FCM received: ${message.data}");
    _showLocalNotification(message);
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
    await initLocalNotification(); // init local DULU (channel harus ada)
    await initPushNotification();  // baru setup FCM listener
  }
}
