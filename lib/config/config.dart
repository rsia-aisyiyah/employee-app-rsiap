import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/home.dart';
import 'package:rsia_employee_app/screen/profile.dart';

class AppConfig {
  static const String publicBaseUrl = 'https://sim.rsiaaisyiyah.com/rsiapi-v2';
  static const String localBaseUrl =
      'http://192.168.100.33/rsiapi-v2'; // Adjust this IP as needed

  static String baseUrl = publicBaseUrl;
  static String apiUrl = '$baseUrl/api/v2';
  static String photoUrl = 'https://sim.rsiaaisyiyah.com/rsiap/file/pegawai/';

  static Future<void> init() async {
    print('Checking network connectivity...');
    try {
      // Try to connect to office local IP (port 80 or 443)
      // Extract IP from localBaseUrl (e.g., 192.168.1.100)
      final host = localBaseUrl.replaceFirst('http://', '').split('/')[0];

      final socket =
          await Socket.connect(host, 80, timeout: const Duration(seconds: 2));
      socket.destroy();

      print('✅ Office network detected. Using local API.');
      baseUrl = localBaseUrl;
    } catch (e) {
      print('🌐 External network or local IP unreachable. Using public API.');
      baseUrl = publicBaseUrl;
    }

    apiUrl = '$baseUrl/api/v2';
    // Update photo URL if it mirrors base URL structure
    if (baseUrl == localBaseUrl) {
      // Adjust local photo URL if different
      photoUrl = 'http://192.168.100.33/rsiap/file/pegawai/';
    } else {
      photoUrl = 'https://sim.rsiaaisyiyah.com/rsiap/file/pegawai/';
    }
  }
}

// Keep constants for external compatibility but redirect to AppConfig
String get apiUrl => AppConfig.apiUrl;
String get photoUrl => AppConfig.photoUrl;
String get baseUrl => AppConfig.baseUrl;

const String appName = 'RSIAP Portal Karyawan';

const int snackBarDuration = 5;

final List<Map<String, Object>> navigationItems = [
  {
    'icon': Icons.home,
    'label': 'Home',
    'widget': const HomePage(),
  },
  {
    'icon': Icons.person,
    'label': 'Profile',
    'widget': const ProfilePage(),
  },
];
