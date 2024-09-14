
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/screen/index.dart';
import 'package:rsia_employee_app/screen/login.dart';
import 'package:rsia_employee_app/screen/logout.dart';
import 'package:rsia_employee_app/screen/menu/undangan.dart';
import 'package:rsia_employee_app/screen/profile.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use runZonedGuarded for everything, including Firebase and other async initialization
  runZonedGuarded<Future<void>>(() async {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    await initializeDateFormatting('id_ID', null);
    await GetStorage.init();
    await FlutterDownloader.initialize(
      debug: false, // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl: true, // option: set to false to disable working with http links (default: false)
    );

    runApp(const MyApp());
  }, (error, stackTrace) async {
    await FirebaseCrashlytics.instance.recordError(error, stackTrace);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false
      ),
      title: appName,
      debugShowCheckedModeBanner: false,
      home: const Directionality(
        textDirection: TextDirection.ltr,
        child: CheckAuth(),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/index': (context) => const IndexScreen(),
        '/profile': (context) => const ProfilePage(),
        '/logout': (context) => const LogoutScreen(),
        '/undangan': (context) => const Undangan()
      },
    );
  }
}

class CheckAuth extends StatefulWidget {
  const CheckAuth({super.key});

  @override
  State<CheckAuth> createState() => _CheckAuthState();
}

class _CheckAuthState extends State<CheckAuth> {
  bool isAuth = false;

  @override
  void initState() {
    super.initState();

    // _checkIsLoggedin();
  }

  Future _authCheck() async {
    var token = await GetStorage().read('token');

    // Null check before decoding
    if (token == null) {
      return false;
    }

    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());

    // Check token expiry
    var now = DateTime.now().millisecondsSinceEpoch / 1000;
    if (decodeToken['exp'] < now) {
      return false;
    }

    var tkns = await Api().getData('/user/auth/detail');
    if (tkns.statusCode != 200) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authCheck(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Something went wrong!'),
              ),
            );
          } else if (snapshot.hasData) {
            if (snapshot.data == true) {
              return const IndexScreen();
            } else {
              return const LoginScreen();
            }
          } else {
            return const LoginScreen();
          }
        }
    );
  }
}
