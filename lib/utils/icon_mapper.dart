import 'package:flutter/material.dart';

class IconMapper {
  static String? getEmoji(String iconName, {String? routeKey}) {
    final r = (routeKey ?? '').trim().toLowerCase();
    final i = iconName.trim().toLowerCase();
    if (r == 'emergency_rush' ||
        r == 'ambulans_gesit' ||
        r == 'game_ambulans' ||
        r == 'menu_ambulans' ||
        r == 'menu_emergency_rush' ||
        i == 'emergency_rush' ||
        i == 'ambulans_gesit' ||
        i == 'ambulans') {
      return '🚑';
    }
    if (r == 'kantin' ||
        r == 'menu_kantin' ||
        r == 'kantin_rsia' ||
        r == 'pesan_makanan' ||
        i == 'kantin' ||
        i == 'menu_kantin' ||
        i == 'kantin_rsia') {
      return '🍱';
    }
    return null;
  }

  static Widget buildIcon(
    String iconName, {
    String? routeKey,
    Color? color,
    double size = 24,
  }) {
    final emoji = getEmoji(iconName, routeKey: routeKey);
    if (emoji != null) {
      return Text(
        emoji,
        style: TextStyle(
          fontSize: size * 0.95,
          height: 1.1,
        ),
      );
    }
    return Icon(
      getIcon(iconName, routeKey: routeKey),
      size: size,
      color: color,
    );
  }

  static IconData getIcon(String iconName, {String? routeKey}) {
    if (routeKey != null && routeKey.isNotEmpty) {
      switch (routeKey.toLowerCase()) {
        case 'emergency_rush':
        case 'ambulans_gesit':
        case 'game_ambulans':
        case 'menu_ambulans':
        case 'menu_emergency_rush':
          return Icons.airport_shuttle_rounded;
        case 'kantin':
        case 'menu_kantin':
        case 'kantin_rsia':
        case 'pesan_makanan':
          return Icons.restaurant_rounded;
        case 'menu_tts':
        case 'tts':
        case 'game_tts':
        case 'teka_teki_silang':
          return Icons.extension_rounded;
        case 'menu_kebugaran':
        case 'menu_kesehatan':
        case 'kebugaran_saya':
        case 'kebugaran':
          return Icons.watch_rounded;
        case 'menu_pengajuan_jadwal':
        case 'pengajuan_jadwal':
          return Icons.edit_calendar_rounded;
        case 'menu_jadwal_pegawai':
        case 'jadwal_pegawai':
          return Icons.calendar_month;
        case 'menu_pengajuan_jadwal_tambahan':
          return Icons.more_time_rounded;
        case 'menu_approval_jadwal_tambahan':
          return Icons.fact_check_rounded;
      }
    }

    switch (iconName.toLowerCase()) {
      // Kebugaran & Smartwatch
      case 'kebugaran':
      case 'kebugaran_saya':
      case 'menu_kebugaran':
      case 'wellness':
      case 'wellness_saya':
      case 'menu_wellness':
      case 'kesehatan':
      case 'menu_kesehatan':
      case 'watch':
      case 'smartwatch':
      case 'fitness':
      case 'health':
        return Icons.watch_rounded;

      // Mini Games & Arcade
      case 'emergency_rush':
      case 'ambulans_gesit':
      case 'game_ambulans':
      case 'menu_ambulans':
      case 'menu_emergency_rush':
        return Icons.airport_shuttle_rounded;
      case 'menu_tts':
      case 'tts':
      case 'game_tts':
      case 'teka_teki_silang':
        return Icons.extension_rounded;

      // Kantin & Makanan
      case 'kantin':
      case 'menu_kantin':
      case 'kantin_rsia':
      case 'pesan_makanan':
      case 'makanan':
        return Icons.restaurant_rounded;

      // Essentials & Common Actions
      case 'home':
        return Icons.home;
      case 'add':
      case 'plus':
        return Icons.add;
      case 'edit':
      case 'update':
        return Icons.edit;
      case 'delete':
      case 'remove':
      case 'trash':
        return Icons.delete_outline;
      case 'check':
      case 'approve':
      case 'success':
        return Icons.check_circle_outline;
      case 'close':
      case 'cancel':
      case 'reject':
        return Icons.cancel_outlined;
      case 'info':
        return Icons.info_outline;
      case 'warning':
      case 'warning_amber_rounded':
      case 'icons.warning_amber_rounded':
      case 'ikp':
      case 'lapor_ikp':
        return Icons.warning_amber_rounded;
      case 'settings':
      case 'gear':
        return Icons.settings_outlined;
      case 'search':
        return Icons.search;
      case 'history':
      case 'rekap':
        return Icons.history;

      // SDI / Personnel Specific
      case 'user':
      case 'person':
      case 'pegawai':
        return Icons.person_outline;
      case 'users':
      case 'people':
      case 'kelompok':
        return Icons.people_outline;
      case 'dashboard':
      case 'analytics':
      case 'overview':
        return Icons.analytics_rounded;
      case 'fingerprint':
      case 'presensi':
      case 'absensi':
      case 'checkin':
      case 'attendance':
      case 'presence':
      case 'lokasi':
      case 'location':
        return Icons.fingerprint_rounded;
      case 'calendar':
      case 'calendar_month':
      case 'cuti':
        return Icons.calendar_month;
      case 'event':
      case 'pengajuan_jadwal':
      case 'menu_pengajuan_jadwal':
        return Icons.edit_calendar_rounded;
      case 'jadwal_pegawai':
      case 'menu_jadwal_pegawai':
        return Icons.calendar_month;
      case 'jadwal-tambahan':
      case 'menu_pengajuan_jadwal_tambahan':
        return Icons.more_time_rounded;
      case 'approval':
      case 'approval_jadwal':
      case 'jadwal_approval':
      case 'menu_approval_jadwal':
        return Icons.event_available_rounded;
      case 'approval-jadwal-tambahan':
      case 'menu_approval_jadwal_tambahan':
        return Icons.fact_check_rounded;
      case 'money':
      case 'payments':
      case 'payment':
      case 'jaspel':
      case 'gaji':
      case 'slip':
        return Icons.payments_outlined;
      case 'folder':
      case 'berkas':
        return Icons.folder_copy_outlined;
      case 'file':
      case 'dokumen':
      case 'surat':
        return Icons.file_copy_outlined;
      case 'mail':
      case 'pesan':
      case 'undangan':
        return Icons.mail_outline;
      case 'template_dokumen':
      case 'template':
        return Icons.copy_all_rounded;
      case 'surat_internal':
      case 'internal':
        return Icons.domain_rounded;
      case 'surat_eksternal':
      case 'eksternal':
      case 'fas fa-envelope-open-text':
        return Icons.public_rounded;
      case 'kinerja':
      case 'assessment':
        return Icons.assessment_outlined;
      case 'education':
      case 'school':
      case 'elearning':
      case 'pelatihan':
        return Icons.school_outlined;
      case 'membership':
      case 'card_membership':
      case 'sertifikasi':
      case 'licence':
        return Icons.card_membership_outlined;
      case 'overtime':
      case 'lembur':
      case 'menu_lembur':
        return Icons.more_time_rounded;
      case 'riwayat_lembur':
      case 'menu_riwayat_lembur':
        return Icons.manage_history_rounded;
      case 'approval_lembur':
      case 'menu_approval_lembur':
        return Icons.verified_user_rounded;
      case 'campaign':
      case 'news':
      case 'pengumuman':
        return Icons.campaign_outlined;
      case 'support':
      case 'helpdesk':
      case 'menu_helpdesk':
      case 'tiket':
      case 'support_agent':
      case 'ticket':
      case 'lapor':
      case 'report':
        return Icons.support_agent;
      case 'hospital':
      case 'medis':
        return Icons.local_hospital_outlined;
      case 'medicine':
      case 'obat':
        return Icons.medical_services_outlined;
      case 'patient':
      case 'pasien':
        return Icons.accessible_forward_outlined;
      case 'penyakit':
      case 'diagnosa':
      case 'diagnosis':
      case 'icd10':
        return Icons.sick_outlined;
      case 'bed':
      case 'tempat_tidur':
      case 'kamar':
        return Icons.hotel_outlined;
      case 'statistik':
      case 'statistik_ranap':
      case 'indikator':
      case 'indikator_ranap':
        return Icons.query_stats_rounded;

      // E-Book & Jurnal
      case 'ebook':
      case 'e_book':
      case 'menu_ebook':
      case 'menu_e_book':
      case 'menu_ebook_jurnal':
        return Icons.menu_book_rounded;
      case 'jurnal':
      case 'menu_jurnal':
        return Icons.article_rounded;

      // Akreditasi (parent menu)
      case 'akreditasi':
      case 'menu_akreditasi':
      case 'snars':
      case 'akred':
        return Icons.verified_rounded;

      // Instrumen Akreditasi (sub menu — daftar standar & EP)
      case 'instrumen_akreditasi':
      case 'menu_instrumen_akreditasi':
        return Icons.checklist_rounded;

      // Aset & Fasilitas
      case 'maintenance':
      case 'pemeliharaan':
      case 'pemeliharaan_inventaris':
        return Icons.build_circle_rounded;
      case 'permintaan_perbaikan':
        return Icons.assignment_late_rounded;
      case 'perbaikan_service':
        return Icons.home_repair_service_rounded;
      case 'inventory':
      case 'inventaris':
      case 'aset':
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      case 'track_changes':
      case 'mutasi':
      case 'riwayat_mutasi':
      case 'inventaris_mutasi':
        return Icons.track_changes;

      // Default
      default:
        return Icons.apps;
    }
  }
}
