import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/home.dart';
import 'package:rsia_employee_app/screen/profile.dart';

class AppConfig {
  static const String publicBaseUrl = 'https://rsiap.my.id/rsiapi-v2';

  static String baseUrl = publicBaseUrl;
  static String apiUrl = '$baseUrl/api/v2';
  static String photoUrl = 'https://rsiap.my.id/rsiap/file/pegawai/';

  static Future<void> init() async {
    // Network discovery removed to speed up startup
    debugPrint('🚀 API URL: $apiUrl');
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
