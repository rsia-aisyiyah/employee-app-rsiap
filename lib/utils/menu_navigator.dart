import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/approval_cuti.dart';
import 'package:rsia_employee_app/screen/menu/berkas_pegawai.dart';
import 'package:rsia_employee_app/screen/menu/cuti.dart';
import 'package:rsia_employee_app/screen/menu/dashboard_rs.dart';
import 'package:rsia_employee_app/screen/menu/file_manager.dart';
import 'package:rsia_employee_app/screen/menu/jasa_medis.dart';
import 'package:rsia_employee_app/screen/menu/presensi.dart';
import 'package:rsia_employee_app/screen/menu/sertifikasi.dart';
import 'package:rsia_employee_app/screen/menu/undangan.dart';
import 'package:rsia_employee_app/screen/menu/pengajuan_jadwal.dart';
import 'package:rsia_employee_app/screen/menu/dashboard_kunjungan.dart';
import 'package:rsia_employee_app/screen/menu/dashboard_bed.dart';
import 'package:rsia_employee_app/screen/menu/helpdesk_main.dart';
import 'package:rsia_employee_app/screen/menu/dashboard_penyakit.dart';
import 'package:rsia_employee_app/screen/menu/dashboard_statistik_ranap.dart';

class MenuNavigator {
  static Widget? getWidget(String routeKey) {
    switch (routeKey) {
      case 'menu_dashboard':
      case 'menu_dashboard_rs':
        return const DashboardRS();
      case 'menu_presensi':
        return const Presensi();
      case 'menu_cuti':
        return const Cuti();
      case 'menu_jaspel':
      case 'menu_slip_jaspel':
        return const JasaMedis();
      case 'menu_berkas':
      case 'menu_berkas_kepegawaian':
        return const BerkasPegawai();
      case 'menu_dokumen':
      case 'menu_dokumen_surat':
        return const FileManager();
      case 'menu_undangan':
        return const Undangan();
      case 'menu_sertifikasi':
        return const Sertifikasi();
      case 'menu_pengajuan_jadwal':
        return const PengajuanJadwal();
      case 'menu_approval_cuti':
        return const ApprovalCuti();
      case 'menu_dashboard_kunjungan':
        return const DashboardKunjungan();
      case 'menu_dashboard_bed':
        return const DashboardBed();
      case 'menu_helpdesk':
        return const HelpdeskMainScreen();
      case 'menu_penyakit':
        return const DashboardPenyakit();
      case 'menu_statistik_ranap':
        return const DashboardStatistikRanap();
      case 'menu_berkas_pegawai':
        return null;
      default:
        return null;
    }
  }

  static void navigate(BuildContext context, String routeKey) {
    Widget? widget = getWidget(routeKey);
    if (widget != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => widget),
      );
    }
  }
}
