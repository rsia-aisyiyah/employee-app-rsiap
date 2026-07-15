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
import 'package:rsia_employee_app/screen/menu/surat_internal/surat_internal_screen.dart';
import 'package:rsia_employee_app/screen/menu/pengajuan_jadwal.dart';
import 'package:rsia_employee_app/screen/menu/dashboard_kunjungan.dart';
import 'package:rsia_employee_app/screen/menu/dashboard_bed.dart';
import 'package:rsia_employee_app/screen/menu/e_presensi.dart';
import 'package:rsia_employee_app/screen/menu/helpdesk_main.dart';
import 'package:rsia_employee_app/screen/menu/dashboard_penyakit.dart';
import 'package:rsia_employee_app/screen/menu/dashboard_statistik_ranap.dart';
import 'package:rsia_employee_app/screen/menu/approval_jadwal.dart';
import 'package:rsia_employee_app/screen/menu/surat_eksternal/surat_eksternal_screen.dart';
import 'package:rsia_employee_app/screen/menu/lembur.dart';
import 'package:rsia_employee_app/screen/menu/lembur_history.dart';
import 'package:rsia_employee_app/screen/menu/approval_lembur.dart';
import 'package:rsia_employee_app/screen/menu/presensi_dokter.dart';
import 'package:rsia_employee_app/screen/menu/jadwal_pegawai.dart';
import 'package:rsia_employee_app/screen/menu/pengajuan_jadwal_tambahan.dart';
import 'package:rsia_employee_app/screen/menu/approval_jadwal_tambahan.dart';
import 'package:rsia_employee_app/screen/menu/pemeliharaan_inventaris.dart';
import 'package:rsia_employee_app/screen/menu/permintaan_perbaikan.dart';
import 'package:rsia_employee_app/screen/menu/perbaikan_service.dart';
import 'package:rsia_employee_app/screen/menu/inventaris_mutasi.dart';
import 'package:rsia_employee_app/screen/menu/mood_checkin.dart';
import 'package:rsia_employee_app/screen/menu/akreditasi/akreditasi_home_screen.dart';
import 'package:rsia_employee_app/screen/menu/lapor_ikp_history.dart';

class MenuNavigator {
  static Widget? getWidget(String routeKey) {
    switch (routeKey) {
      case 'menu_dashboard':
      case 'menu_dashboard_rs':
        return const DashboardRS();
      case 'menu_e_presensi':
      case 'e_presensi':
      case 'presensi_online':
      case 'menu_presensi_online':
        return const EPresensiScreen(title: 'E-Presensi');
      case 'menu_presensi':
      case 'presensi_history':
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
      case 'menu_surat_internal':
        return const SuratInternalScreen();
      case 'menu_surat_eksternal':
        return const SuratEksternalScreen();
      case 'menu_undangan':
        return const Undangan();
      case 'menu_sertifikasi':
        return const Sertifikasi();
      case 'pengajuan_jadwal':
      case 'menu_pengajuan_jadwal':
        return const PengajuanJadwal();
      case 'jadwal_pegawai':
      case 'menu_jadwal_pegawai':
        return const JadwalPegawai();
      case 'menu_approval_cuti':
        return const ApprovalCuti();
      case 'approval':
      case 'approval/jadwal':
      case 'approval-jadwal':
      case 'approval_jadwal':
      case 'jadwal_approval':
      case 'menu_approval_jadwal':
        return const ApprovalJadwal();
      case 'menu_pengajuan_jadwal_tambahan':
        return const PengajuanJadwalTambahan();
      case 'menu_approval_jadwal_tambahan':
        return const ApprovalJadwalTambahan();
      case 'menu_dashboard_kunjungan':
        return const DashboardKunjungan();
      case 'menu_dashboard_bed':
        return const DashboardBed();
      case 'menu_helpdesk':
        return const HelpdeskMainScreen();
      case 'menu_lembur':
        return const LemburScreen(title: 'Lembur');
      case 'menu_approval_lembur':
        return const ApprovalLemburScreen();
      case 'menu_riwayat_lembur':
        return const LemburHistoryScreen();
      case 'menu_penyakit':
        return const DashboardPenyakit();
      case 'menu_statistik_ranap':
        return const DashboardStatistikRanap();
      case 'presensi_dokter':
      case 'dokter_presensi':
      case 'menu_presensi_dokter':
        return const PresensiDokter();
      case 'menu_pemeliharaan_inventaris':
      case 'pemeliharaan_inventaris':
        return const PemeliharaanInventaris();
      case 'menu_permintaan_perbaikan':
      case 'permintaan_perbaikan':
        return const PermintaanPerbaikan();
      case 'menu_perbaikan_service':
      case 'perbaikan_service':
        return const PerbaikanService();
      case 'menu_mutasi_inventaris':
      case 'mutasi_inventaris':
        return const InventarisMutasi();
      case 'menu_mood':
      case 'mood_checkin':
      case 'menu_mood_checkin':
        return const MoodCheckinScreen();
      case 'menu_akreditasi':
      case 'akreditasi':
      case 'formatting_akreditasi':
      case 'instrumen_akreditasi':
      case 'menu_instrumen_akreditasi':
        return const AkreditasiHomeScreen();
      case 'lapor-ikp':
      case 'lapor_ikp':
      case 'menu_lapor_ikp':
        return const LaporIkpHistoryScreen();
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
