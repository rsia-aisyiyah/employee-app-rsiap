import 'dart:math';
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
    final r = (routeKey ?? '').trim().toLowerCase();
    final i = iconName.trim().toLowerCase();

    // ── Custom Dedicated Icon untuk Game Virus Buster ──
    if (r == 'virus_buster' ||
        r == 'super_doctor' ||
        r == 'game_dokter' ||
        r == 'dokter_virus' ||
        r == 'menu_virus_buster' ||
        r == 'menu_super_doctor' ||
        i == 'virus_buster' ||
        i == 'super_doctor') {
      return VirusBusterMenuIcon(size: size);
    }

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
        case 'virus_buster':
        case 'super_doctor':
        case 'game_dokter':
        case 'dokter_virus':
        case 'menu_virus_buster':
        case 'menu_super_doctor':
          return Icons.vaccines_rounded;
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
      case 'virus_buster':
      case 'super_doctor':
      case 'game_dokter':
      case 'dokter_virus':
      case 'menu_virus_buster':
      case 'menu_super_doctor':
        return Icons.vaccines_rounded;
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

/// ── Custom High-Definition Vector Game Icon untuk Menu Virus Buster ──
class VirusBusterMenuIcon extends StatelessWidget {
  final double size;

  const VirusBusterMenuIcon({Key? key, this.size = 25}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ukuran disesuaikan agar pas dan proporsional di dalam 50x50 squircle
    final targetSize = size * 1.25;
    return SizedBox(
      width: targetSize,
      height: targetSize,
      child: CustomPaint(
        size: Size(targetSize, targetSize),
        painter: const _VirusBusterIconPainter(),
      ),
    );
  }
}

class _VirusBusterIconPainter extends CustomPainter {
  const _VirusBusterIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Skala kanvas dinamis berbasis 36x36
    final scale = size.width / 36.0;
    canvas.save();
    canvas.scale(scale);

    // ── 1. AMBIENT GLOW DI BELAKANG ─────────────────────────────
    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawCircle(const Offset(13.5, 20.5), 10.5, glowPaint);

    // ── 2. KARAKTER VIRUS MENGGEMASKAN (Kiri Bawah) ─────────────
    const vCenter = Offset(13.5, 20.5);
    const vRadius = 8.2;

    // A. Tentakel Spikes Virus (6 Tunas Berpendar)
    final spikeBasePaint = Paint()
      ..color = const Color(0xFF047857)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final spikeTipPaint = Paint()..color = const Color(0xFF10B981);

    const spikeAngles = [30.0, 90.0, 150.0, 210.0, 270.0, 330.0];
    for (final deg in spikeAngles) {
      final rad = deg * pi / 180.0;
      final start = Offset(
        vCenter.dx + cos(rad) * (vRadius - 1.2),
        vCenter.dy + sin(rad) * (vRadius - 1.2),
      );
      final tip = Offset(
        vCenter.dx + cos(rad) * (vRadius + 3.0),
        vCenter.dy + sin(rad) * (vRadius + 3.0),
      );
      canvas.drawLine(start, tip, spikeBasePaint);
      canvas.drawCircle(tip, 1.7, spikeTipPaint);
      // Titik kilau terang di kepala tentakel
      canvas.drawCircle(
        Offset(tip.dx - 0.4, tip.dy - 0.4),
        0.5,
        Paint()..color = const Color(0xFFA7F3D0),
      );
    }

    // B. Tubuh Bulat Virus dengan Gradasi Neon Toska-Lime
    final vBodyRect = Rect.fromCircle(center: vCenter, radius: vRadius);
    final vBodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF34D399), // Mint cerah
          Color(0xFF059669), // Emerald toska
        ],
        center: Alignment(-0.35, -0.35),
        radius: 0.85,
      ).createShader(vBodyRect);
    canvas.drawCircle(vCenter, vRadius, vBodyPaint);

    // Border tubuh virus
    canvas.drawCircle(
      vCenter,
      vRadius,
      Paint()
        ..color = const Color(0xFF047857)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // C. Wajah Virus yang Kaget & Lucu
    // Mata Kiri
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(11.0, 19.3), width: 3.0, height: 4.0),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(const Offset(11.4, 19.4), 1.2, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(const Offset(11.8, 18.9), 0.5, Paint()..color = Colors.white);

    // Mata Kanan
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(16.0, 19.3), width: 3.0, height: 4.0),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(const Offset(16.4, 19.4), 1.2, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(const Offset(16.8, 18.9), 0.5, Paint()..color = Colors.white);

    // Pipi Merona Pink Manis
    canvas.drawCircle(
      const Offset(9.4, 22.0),
      1.1,
      Paint()..color = const Color(0x77F43F5E),
    );
    canvas.drawCircle(
      const Offset(17.6, 22.0),
      1.1,
      Paint()..color = const Color(0x77F43F5E),
    );

    // Mulut Terkejut Bulat "o"
    final mouthPaint = Paint()..color = const Color(0xFF064E3B);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(13.5, 23.0), width: 2.0, height: 2.4),
      mouthPaint,
    );

    // ── 3. SYRINGE BLASTER MEDIS (Membidik Diagonal dari Kanan Atas) ──
    canvas.save();
    canvas.translate(26.2, 9.8);
    canvas.rotate(-pi / 4.1);

    // Tabung Syringe
    final barrelRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-3.8, -10.5, 7.6, 13.5),
      const Radius.circular(2.2),
    );
    canvas.drawRRect(barrelRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      barrelRect,
      Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Cairan Energi Serum Pink Neon di Tabung
    final serumRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-2.6, -8.0, 5.2, 9.5),
      const Radius.circular(1.3),
    );
    final serumPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(-2.6, -8.0, 5.2, 9.5));
    canvas.drawRRect(serumRect, serumPaint);

    // Skala Strip Dosis Putih
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 0.8;
    canvas.drawLine(const Offset(-1.8, -6.0), const Offset(0.2, -6.0), tickPaint);
    canvas.drawLine(const Offset(-1.8, -3.6), const Offset(0.2, -3.6), tickPaint);
    canvas.drawLine(const Offset(-1.8, -1.2), const Offset(0.2, -1.2), tickPaint);

    // Plunger Belakang
    final plungerRod = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.8;
    canvas.drawLine(const Offset(0, -10.5), const Offset(0, -14.5), plungerRod);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.8, -16.0, 5.6, 1.8),
        const Radius.circular(1.0),
      ),
      Paint()..color = const Color(0xFF0284C7),
    );

    // Moncong Nozzle Logam
    canvas.drawRect(
      const Rect.fromLTWH(-1.7, 3.0, 3.4, 2.0),
      Paint()..color = const Color(0xFF0284C7),
    );

    // Jarum Stainless Steel Perak
    final needlePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.3;
    canvas.drawLine(const Offset(0, 5.0), const Offset(0, 11.2), needlePaint);

    canvas.restore();

    // ── 4. EFEK ZAP / SPARKLE BINTANG LASER DI TITIK TEMU ──────────
    const zapCenter = Offset(19.2, 13.8);

    // Bintang 4-Sisi Emas Berkilau (Laser Impact)
    final sparkPaint = Paint()..color = const Color(0xFFFACC15);
    final sparkPath = Path();
    sparkPath.moveTo(zapCenter.dx, zapCenter.dy - 3.6);
    sparkPath.quadraticBezierTo(zapCenter.dx, zapCenter.dy, zapCenter.dx + 3.6, zapCenter.dy);
    sparkPath.quadraticBezierTo(zapCenter.dx, zapCenter.dy, zapCenter.dx, zapCenter.dy + 3.6);
    sparkPath.quadraticBezierTo(zapCenter.dx, zapCenter.dy, zapCenter.dx - 3.6, zapCenter.dy);
    sparkPath.quadraticBezierTo(zapCenter.dx, zapCenter.dy, zapCenter.dx, zapCenter.dy - 3.6);
    sparkPath.close();
    canvas.drawPath(sparkPath, sparkPaint);

    // Inti Putih Kilatan
    canvas.drawCircle(zapCenter, 1.1, Paint()..color = Colors.white);

    // Partikel Percikan Energi Neon
    canvas.drawCircle(const Offset(24.2, 15.2), 0.9, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(const Offset(16.2, 10.2), 0.8, Paint()..color = const Color(0xFFEC4899));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
