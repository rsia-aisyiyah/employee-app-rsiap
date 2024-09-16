
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
  runZonedGuarded<Future<void>>(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp();
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      await initializeDateFormatting('id_ID', null);
      await GetStorage.init();
      await FlutterDownloader.initialize(
        debug: false,
        ignoreSsl: false, // Changed to false for security reasons
      );

      runApp(const MyApp());
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
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

class CheckAuth extends StatelessWidget {
  const CheckAuth({super.key});

  @override
  Widget build(BuildContext context) {
    Future authCheck() async {
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

    return FutureBuilder(
      future: authCheck(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Something went wrong!'),
              ),
            );
          }

          if (snapshot.hasData) {
            if (snapshot.data == true) {
              return const IndexScreen();
            } else {
              return const LoginScreen();
            }
          }

          return const LoginScreen();
        }
    );
  }
}
