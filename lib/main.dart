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

  try {
    debugPrint('💾 Initializing GetStorage...');
    await GetStorage.init();
    debugPrint('✅ GetStorage initialized');
  } catch (e) {
    debugPrint('❌ Error initializing GetStorage: $e');
  }

  // Initialize Config (Network Check)
  try {
    debugPrint('⚙️ Starting AppConfig initialization...');
    await AppConfig.init().timeout(const Duration(seconds: 4));
    debugPrint('✅ AppConfig initialized');
  } catch (e) {
    debugPrint(
        '⚠️ AppConfig init failed or timed out ($e). Proceeding with defaults.');
  }

  try {
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    debugPrint('✅ Firebase initialized');
  } catch (e, stack) {
    debugPrint('❌ Firebase init failed or timed out: $e');
  }

  try {
    debugPrint('📅 Initializing date formatting...');
    await initializeDateFormatting('id_ID', null)
        .timeout(const Duration(seconds: 2));
    debugPrint('✅ Date formatting initialized');
  } catch (e) {
    debugPrint('❌ Error initializing date formatting: $e');
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

      try {
        var tkns = await Api().getData('/user/auth/detail');
        if (tkns.statusCode != 200) {
          return false;
        }
      } catch (e) {
        debugPrint('❌ Auth check failed: $e');
        // Let it throw or return false.
        // Returning false will redirect to login, which is safer.
        // But if it's a timeout, maybe we want to show the error UI.
        // FutureBuilder will catch the exception and show snapshot.hasError.
        rethrow;
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
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to connect to server.\nPlease check your internet connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
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
