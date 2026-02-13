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
    debugPrint('🔍 Checking network connectivity...');

    try {
      // Reduced timeout for faster startup
      await _discoverNetwork().timeout(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint(
          '🌐 Network discovery failed or timed out ($e). Using fallback.');
      baseUrl = publicBaseUrl;
    }

    _updateUrls();
    debugPrint('🚀 API URL: $apiUrl');
  }

  /// Switch to alternative URL (toggle between local and public)
  static void switchToAlternativeUrl() {
    baseUrl = getAlternativeUrl();
    _updateUrls();
    debugPrint('🔄 Switched to alternative URL: $apiUrl');
  }

  /// Get the alternative URL (opposite of current)
  static String getAlternativeUrl() {
    return baseUrl == localBaseUrl ? publicBaseUrl : localBaseUrl;
  }

  /// Update apiUrl and photoUrl based on current baseUrl
  static void _updateUrls() {
    apiUrl = '$baseUrl/api/v2';
    photoUrl = baseUrl == localBaseUrl
        ? 'http://192.168.100.33/rsiap/file/pegawai/'
        : 'https://sim.rsiaaisyiyah.com/rsiap/file/pegawai/';
  }

  static Future<void> _discoverNetwork() async {
    try {
      final host = localBaseUrl.replaceFirst('http://', '').split('/')[0];

      // Very short timeout for quick failure detection
      final socket = await Socket.connect(host, 80,
          timeout: const Duration(milliseconds: 400));
      socket.destroy();

      debugPrint('✅ Local IP reachable. Using local API.');
      baseUrl = localBaseUrl;
    } catch (e) {
      // If local IP is not reachable, fallback will happen via catch in init()
      rethrow;
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
