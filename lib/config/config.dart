import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/home.dart';
import 'package:rsia_employee_app/screen/menu/berkas_pegawai.dart';
import 'package:rsia_employee_app/screen/menu/cuti.dart';
import 'package:rsia_employee_app/screen/menu/file_manager.dart';
import 'package:rsia_employee_app/screen/menu/otp_jasa_medis.dart';
import 'package:rsia_employee_app/screen/menu/presensi.dart';
import 'package:rsia_employee_app/screen/menu/undangan.dart';
import 'package:rsia_employee_app/screen/profile.dart';

const String baseUrl = 'https://sim.rsiaaisyiyah.com/rsiapi';
// const String baseUrl = 'http://172.24.19.22/rsia';
const String apiUrl = '$baseUrl/api/v2';
const String photoUrl = 'https://sim.rsiaaisyiyah.com/rsiap/file/pegawai/';

const String appName = 'RSIAP Portal Karyawan';

const int snackBarDuration = 5;

List<Map<String, Object>> menuScreenItems = [
  {
    'label': 'Presensi',
    'widget': const Presensi(),
    'disabled': false,
    'icon': Icons.more_time
  },
  {
    'label': 'Cuti',
    'widget': const Cuti(),
    'disabled': false,
    'icon': Icons.calendar_month_sharp
  },
  {
    'label': 'Slip Jaspel',
    'widget': const OtpJasaMedis(),
    'disabled': false,
    'icon': Icons.payments_outlined
  },
  {
    'label': 'Slip Gaji',
    'widget': '',
    'disabled': true,
    'icon': Icons.payments_rounded
  },
  {
    'label': 'Berkas Kepegawaian',
    'widget': const BerkasPegawai(),
    'disabled': false,
    'icon': Icons.folder_copy
  },
  {
    'label': 'Dokumen & Surat',
    'widget': const FileManager(),
    'disabled': false,
    'icon': Icons.file_copy
  },
  {
    'label': 'Undangan',
    'widget': const Undangan(),
    'disabled': false,
    'icon': Icons.mail,
  },
];

const List<Map<String, Object>> navigationItems = [
  {
    'icon': Icons.home,
    'label': 'Home',
    'widget': HomePage(),
  },
  {
    'icon': Icons.person,
    'label': 'Profile',
    'widget': ProfilePage(),
  },
];
