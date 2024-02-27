import 'dart:convert';

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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
    debug: true, // optional: set to false to disable printing logs to console (default: true)
    ignoreSsl: true, // option: set to false to disable working with http links (default: false)
  );

  await initializeDateFormatting('id_ID', null).then(
    (_) => runApp(
      const MyApp(),
    ),
  );
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
      home: Directionality(
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
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());

    // if token available
    if (token != null) {
      // validate token by exp
      var now = DateTime.now().millisecondsSinceEpoch / 1000;
      if (decodeToken['exp'] < now) {
        return false;
      }

      var tkns = await Api().postRequest('/auth/me').then((val) async {
        var res = jsonDecode(val.body);
        if (val.statusCode != 200 || res['success'] == false) {
          return false;
        }
      });

      if (tkns == false) {
        return false;
      }

      return true;
    } else {
      return false;
    }
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
        } else {
          print("snapshot: ${snapshot.data}");
          if (snapshot.hasData) {
            if (snapshot.data == true) {
              return const IndexScreen();
            } else {
              return const LoginScreen();
            }
          } else {
            return const LoginScreen();
          }
        }
      },
    );

    // Widget child;
    // if (isAuth) {
    //   child = const IndexScreen();
    // } else {
    //   child = const LoginScreen();
    // }
    // return child;
  }
}
