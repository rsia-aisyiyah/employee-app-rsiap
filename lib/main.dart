import 'package:firebase_core/firebase_core.dart';
import 'package:rsia_employee_app/api/firebase_api.dart';
import 'package:rsia_employee_app/firebase_options.dart';
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
import 'package:rsia_employee_app/screen/menu/helpdesk_main.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  print('🚀 Starting app initialization...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ WidgetsFlutterBinding initialized');

  // Initialize Config (Network Check)
  await AppConfig.init();

  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
  } catch (e, stack) {
    print('❌ Firebase init error: $e');
    print('Stack: $stack');
  }

  try {
    print('📅 Initializing date formatting...');
    await initializeDateFormatting('id_ID', null);
    print('✅ Date formatting initialized');
  } catch (e) {
    print('❌ Error initializing date formatting: $e');
  }

  try {
    print('💾 Initializing GetStorage...');
    await GetStorage.init();
    print('✅ GetStorage initialized');
  } catch (e) {
    print('❌ Error initializing GetStorage: $e');
  }

  // FlutterDownloader only supports Android and iOS
  // Temporarily disabled for iOS due to potential crash
  // if (Platform.isAndroid) {
  //   try {
  //     print('⬇️ Initializing FlutterDownloader...');
  //     await FlutterDownloader.initialize(
  //       debug: false,
  //       ignoreSsl: false, // Changed to false for security reasons
  //     );
  //     print('✅ FlutterDownloader initialized');
  //   } catch (e) {
  //     print('❌ Error initializing FlutterDownloader: $e');
  //   }
  // }

  print('🎯 Running app...');
  runApp(const MyApp());
  print('✅ App started successfully');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(useMaterial3: false),
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
        '/undangan': (context) => const Undangan(),
        '/helpdesk_main': (context) => const HelpdeskMainScreen(),
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
        });
  }
}
