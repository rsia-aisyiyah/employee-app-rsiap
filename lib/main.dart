import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/screen/index.dart';
import 'package:rsia_employee_app/screen/login.dart';
import 'package:rsia_employee_app/screen/profile.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug:
          true, // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl:
          true // option: set to false to disable working with http links (default: false)
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

    _checkIsLoggedin();
  }

  void _checkIsLoggedin() {
    SharedPreferences.getInstance().then((prefs) {
      var token = prefs.getString('token');
      if (token != null) {
        if (mounted) {
          setState(() {
            isAuth = true;
          });
        }
        // Api().postRequest('/auth/login').then((res) {
        //   print(res.statusCode);
        //   if (res.statusCode == 200) {
        //     if (mounted) {
        //       setState(() {
        //         isAuth = true;
        //       });
        //     }
        //   } else {
        //     if (mounted) {
        //       Msg.error(context, "Your session has expired");
        //       setState(() {
        //         isAuth = false;
        //       });
        //     }
        //   }
        // });
      } else {
        if (mounted) {
          Msg.error(context, "Your session has expired");
          setState(() {
            isAuth = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isAuth) {
      child = const IndexScreen();
    } else {
      child = const LoginScreen();
    }
    return child;
  }
}
