import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class StageScenery extends PositionComponent with HasGameRef {
  final int stageNumber;
  final double groundY;
  double scrollOffset = 0.0;

  StageScenery({
    required this.stageNumber,
    required this.groundY,
  }) : super(priority: -10);

  void scroll(double deltaX) {
    scrollOffset += deltaX;
  }

  @override
  void render(Canvas canvas) {
    final gameSize = gameRef.size;
    final w = gameSize.x;
    final h = gameSize.y;

    switch (stageNumber) {
      case 1:
        _renderIgdStage(canvas, w, h);
        break;
      case 2:
        _renderLobbyStage(canvas, w, h);
        break;
      case 3:
      default:
        _renderNurseStationStage(canvas, w, h);
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 1: DROP-OFF IGD 24 JAM & AMBULANS RSIA
  // ─────────────────────────────────────────────────────────────────────────────
  void _renderIgdStage(Canvas canvas, double w, double h) {
    // 1. Langit / Dinding Gedung Belakang
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      ).createShader(Rect.fromLTWH(0, 0, w, groundY));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), wallPaint);

    // 2. Kanopi Merah IGD 24 Jam di Atas
    final canopyPaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 44), canopyPaint);

    // Plang IGD 24 JAM
    final signBg = Paint()..color = const Color(0xFF991B1B);
    final signRect = Rect.fromCenter(center: Offset(w / 2, 22), width: 180, height: 28);
    canvas.drawRRect(RRect.fromRectAndRadius(signRect, const Radius.circular(6)), signBg);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'IGD 24 JAM',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset((w - textPainter.width) / 2, 12));

    // 3. Pilar Gedung Drop-off (Parallax)
    final pilarPaint = Paint()..color = const Color(0xFF334155);
    final pilarAccent = Paint()..color = const Color(0xFF00A896); // Aksen toska RSIA

    final pilarSpacing = 280.0;
    final pilarStart = -(scrollOffset * 0.4) % pilarSpacing;
    for (double x = pilarStart - pilarSpacing; x < w + pilarSpacing; x += pilarSpacing) {
      canvas.drawRect(Rect.fromLTWH(x, 44, 28, groundY - 44), pilarPaint);
      canvas.drawRect(Rect.fromLTWH(x + 6, 44, 16, groundY - 44), pilarAccent);
    }

    // 4. Mobil Ambulans RSIA Aisyiyah Terparkir di Background
    final ambX = (w * 0.65) - (scrollOffset * 0.7 % (w * 1.6));
    _drawBackgroundAmbulance(canvas, ambX, groundY - 8);

    // 5. Lantai Aspal Drop-off & Marka Jalan
    final roadPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), roadPaint);

    final curbPaint = Paint()..color = const Color(0xFF00A896); // Trotoar hijau toska RSIA
    canvas.drawRect(Rect.fromLTWH(0, groundY - 6, w, 6), curbPaint);

    // Marka Jalan Putih Bergerak
    final stripePaint = Paint()..color = const Color(0xFFF8FAFC);
    final stripeSpacing = 90.0;
    final stripeStart = -(scrollOffset % stripeSpacing);
    for (double x = stripeStart - stripeSpacing; x < w + stripeSpacing; x += stripeSpacing) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, groundY + 28, 45, 6), const Radius.circular(3)),
        stripePaint,
      );
    }
  }

  void _drawBackgroundAmbulance(Canvas canvas, double x, double y) {
    if (x < -140 || x > 1000) return;
    canvas.save();
    canvas.translate(x, y - 65);

    // Bodi Putih Ambulans
    final ambBody = Paint()..color = const Color(0xFFF8FAFC);
    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 110, 52),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, ambBody);

    // Strip Hijau Toska RSIA
    final stripe = Paint()..color = const Color(0xFF00A896);
    canvas.drawRect(const Rect.fromLTWH(0, 26, 110, 10), stripe);

    // Kaca Depan & Samping
    final windowPaint = Paint()..color = const Color(0xFF38BDF8).withOpacity(0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(8, 6, 26, 18), const Radius.circular(4)),
      windowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(42, 6, 30, 18), const Radius.circular(4)),
      windowPaint,
    );

    // Palang Merah
    final crossPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRect(Rect.fromCenter(center: const Offset(88, 20), width: 3.5, height: 12), crossPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(88, 20), width: 12, height: 3.5), crossPaint);

    // Lampu Sirine Merah & Biru di Atap
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(20, -7, 12, 7), const Radius.circular(3)),
      Paint()..color = const Color(0xFFEF4444),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(34, -7, 12, 7), const Radius.circular(3)),
      Paint()..color = const Color(0xFF3B82F6),
    );

    // Roda
    final wheelPaint = Paint()..color = const Color(0xFF0F172A);
    final rimPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawCircle(const Offset(25, 52), 11, wheelPaint);
    canvas.drawCircle(const Offset(25, 52), 5, rimPaint);
    canvas.drawCircle(const Offset(85, 52), 11, wheelPaint);
    canvas.drawCircle(const Offset(85, 52), 5, rimPaint);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 2: LOBI & RUANG TUNGGU POLIKLINIK
  // ─────────────────────────────────────────────────────────────────────────────
  void _renderLobbyStage(Canvas canvas, double w, double h) {
    // 1. Dinding Interior Lobi Rumah Sakit (Beige/Modern Slate)
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
      ).createShader(Rect.fromLTWH(0, 0, w, groundY));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), wallPaint);

    // Panel Hijau Toska RSIA di Bagian Atas
    final topPanel = Paint()..color = const Color(0xFF00A896).withOpacity(0.85);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 24), topPanel);

    // 2. TV / Layar LCD Antrean Poliklinik di Dinding (Parallax)
    final tvSpacing = 360.0;
    final tvStart = -(scrollOffset * 0.3) % tvSpacing;
    for (double x = tvStart - tvSpacing; x < w + tvSpacing; x += tvSpacing) {
      _drawLcdQueueScreen(canvas, x, 40);
    }

    // 3. Deretan Kursi Tunggu Pasien Besi Panjang Silver (Sesuai Foto Referensi)
    final chairSpacing = 240.0;
    final chairStart = -(scrollOffset * 0.8) % chairSpacing;
    for (double x = chairStart - chairSpacing; x < w + chairSpacing; x += chairSpacing) {
      _drawMetalWaitingChairs(canvas, x, groundY);
    }

    // 4. Lantai Granit Lobi Rumah Sakit
    final floorPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), floorPaint);

    // List Garis Nat Keramik Mengkilap
    final lineTilePaint = Paint()
      ..color = const Color(0xFF64748B).withOpacity(0.4)
      ..strokeWidth = 1.0;
    final tileSpacing = 70.0;
    final tileStart = -(scrollOffset % tileSpacing);
    for (double x = tileStart - tileSpacing; x < w + tileSpacing; x += tileSpacing) {
      canvas.drawLine(Offset(x, groundY), Offset(x - 40, h), lineTilePaint);
    }
  }

  void _drawLcdQueueScreen(Canvas canvas, double x, double y) {
    // Frame Monitor TV
    final tvFrame = Paint()..color = const Color(0xFF0F172A);
    final tvScreen = Paint()..color = const Color(0xFF0284C7); // Layar biru info antrean
    final tvRect = Rect.fromLTWH(x, y, 92, 54);
    canvas.drawRRect(RRect.fromRectAndRadius(tvRect, const Radius.circular(5)), tvFrame);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 4, y + 4, 84, 46), const Radius.circular(3)),
      tvScreen,
    );

    // Teks Mockup Antrean
    final tp = TextPainter(
      text: const TextSpan(
        text: 'ANTREAN POLI\nA-024',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + 10, y + 14));
  }

  void _drawMetalWaitingChairs(Canvas canvas, double x, double y) {
    canvas.save();
    canvas.translate(x, y - 38);

    // Rangka Besi Perak Kursi Tunggu (3 Dudukan)
    final metalPaint = Paint()..color = const Color(0xFF94A3B8);
    final chromeShine = Paint()..color = const Color(0xFFCBD5E1);

    // Sandaran & Dudukan Melengkung
    for (int i = 0; i < 3; i++) {
      final cx = i * 28.0;
      // Sandaran Kursi
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx, 0, 24, 22), const Radius.circular(4)),
        metalPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2, 2, 8, 18), const Radius.circular(2)),
        chromeShine,
      );
      // Dudukan Kursi
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx, 22, 24, 8), const Radius.circular(3)),
        metalPaint,
      );
    }

    // Palang Besi Bawah & Kaki Penyangga
    canvas.drawRect(const Rect.fromLTWH(-4, 30, 88, 4), metalPaint);
    canvas.drawLine(const Offset(6, 34), const Offset(6, 38), metalPaint..strokeWidth = 3);
    canvas.drawLine(const Offset(76, 34), const Offset(76, 38), metalPaint..strokeWidth = 3);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 3: NURSE STATION & PINTU POLIKLINIK
  // ─────────────────────────────────────────────────────────────────────────────
  void _renderNurseStationStage(Canvas canvas, double w, double h) {
    // 1. Dinding Koridor Rumah Sakit
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF022C22), Color(0xFF064E3B)],
      ).createShader(Rect.fromLTWH(0, 0, w, groundY));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), wallPaint);

    // 2. Pintu Kaca Geser Poliklinik (Parallax)
    final doorSpacing = 320.0;
    final doorStart = -(scrollOffset * 0.4) % doorSpacing;
    for (double x = doorStart - doorSpacing; x < w + doorSpacing; x += doorSpacing) {
      _drawClinicDoor(canvas, x, groundY - 110);
    }

    // 3. Nurse Station Desk (Meja Pos Perawat) dengan Logo RSIA Akrilik
    final stationSpacing = 440.0;
    final stationStart = -(scrollOffset * 0.8) % stationSpacing;
    for (double x = stationStart - stationSpacing; x < w + stationSpacing; x += stationSpacing) {
      _drawNurseStation(canvas, x, groundY);
    }

    // 4. Lantai Koridor Vinyl Bersih
    final floorPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), floorPaint);

    // List Border Toska
    final baseboard = Paint()..color = const Color(0xFF10B981);
    canvas.drawRect(Rect.fromLTWH(0, groundY - 4, w, 4), baseboard);
  }

  void _drawClinicDoor(Canvas canvas, double x, double y) {
    // Kusen Pintu Aluminium
    final framePaint = Paint()..color = const Color(0xFF475569);
    canvas.drawRect(Rect.fromLTWH(x, y, 76, 110), framePaint);

    // Kaca Pintu Transparan Hijau Kebiruan
    final glassPaint = Paint()..color = const Color(0x666EE7B7);
    canvas.drawRect(Rect.fromLTWH(x + 4, y + 4, 32, 102), glassPaint);
    canvas.drawRect(Rect.fromLTWH(x + 40, y + 4, 32, 102), glassPaint);

    // Gagang Pintu Silver
    final handlePaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawRect(Rect.fromLTWH(x + 32, y + 45, 3, 20), handlePaint);
    canvas.drawRect(Rect.fromLTWH(x + 41, y + 45, 3, 20), handlePaint);

    // Papan Nama Poli
    final signBg = Paint()..color = const Color(0xFF00A896);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 8, y - 16, 60, 14), const Radius.circular(3)),
      signBg,
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'POLIKLINIK',
        style: TextStyle(
          color: Colors.white,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + 13, y - 14));
  }

  void _drawNurseStation(Canvas canvas, double x, double y) {
    canvas.save();
    canvas.translate(x, y - 48);

    // Meja Nurse Station Melengkung Putih
    final deskPaint = Paint()..color = const Color(0xFFF8FAFC);
    final deskRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 110, 48),
      const Radius.circular(6),
    );
    canvas.drawRRect(deskRect, deskPaint);

    // Garis Aksen Toska RSIA di Meja
    final accentPaint = Paint()..color = const Color(0xFF00A896);
    canvas.drawRect(const Rect.fromLTWH(0, 36, 110, 6), accentPaint);

    // Tanda Akrilik Logo RSIA Aisyiyah Pekajangan
    final logoBg = Paint()..color = const Color(0xFF0F766E);
    final logoRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 10, 90, 20),
      const Radius.circular(4),
    );
    canvas.drawRRect(logoRect, logoBg);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'NURSE STATION',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(16, 15));

    // Monitor Komputer Perawat & Berkas Rekam Medis di Atas Meja
    final compPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawRect(const Rect.fromLTWH(80, -14, 16, 14), compPaint);
    canvas.drawRect(const Rect.fromLTWH(86, 0, 4, 3), compPaint);

    // Berkas Map Hijau
    final folderPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawRect(const Rect.fromLTWH(18, -4, 12, 4), folderPaint);

    canvas.restore();
  }
}
