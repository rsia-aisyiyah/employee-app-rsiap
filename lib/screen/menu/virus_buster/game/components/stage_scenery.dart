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
        _renderWaitingLobbyStage(canvas, w, h);
        break;
      case 3:
      default:
        _renderNurseStationClinicStage(canvas, w, h);
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 1: DROP-OFF UGD 24 JAM & AMBULANS SILVER RSIA (SESUAI FOTO REFERENSI ASLI)
  // ─────────────────────────────────────────────────────────────────────────────
  void _renderIgdStage(Canvas canvas, double w, double h) {
    // 1. Langit & Bangunan Utama Krem Hangat RSIA
    final skyPaint = Paint()..color = const Color(0xFFBAE6FD); // Langit cerah siang
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), skyPaint);

    // Dinding Gedung Belakang (Krem Hangat Rumah Sakit)
    final bldgPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawRect(Rect.fromLTWH(0, 30, w, groundY - 30), bldgPaint);

    // Atap Genteng Merah Bata Coklat di Atas Gedung
    final roofPaint = Paint()..color = const Color(0xFF9A3412);
    canvas.drawRect(Rect.fromLTWH(0, 20, w, 14), roofPaint);

    // Spanduk Resmi Hijau & Biru di Atap Gedung: "RSIA AISYIYAH PEKAJANGAN"
    _drawRoofBanner(canvas, w);

    // Kanopi Baja Hitam Parkiran di Bagian Kiri (Sesuai Foto 4)
    final canopyFrame = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 3.5;
    final canopyRoof = Paint()..color = const Color(0xFF334155);
    canvas.drawRect(Rect.fromLTWH(0, 60, w * 0.45, 12), canopyRoof);
    canvas.drawLine(const Offset(30, 72), Offset(30, groundY), canopyFrame);
    canvas.drawLine(Offset(w * 0.42, 72), Offset(w * 0.42, groundY), canopyFrame);

    // 2. Bangunan Drop-off UGD 24 JAM
    final ugdWall = Paint()..color = const Color(0xFFFFFBEB);
    final ugdRect = Rect.fromLTWH(w * 0.48, 65, w * 0.52, groundY - 65);
    canvas.drawRect(ugdRect, ugdWall);

    // Plang Putih Berbingkai Merah: "UGD 24 JAM" (Persis di Foto 4)
    final plangBox = Rect.fromLTWH(w * 0.55, 78, 120, 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plangBox, const Radius.circular(4)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plangBox, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFDC2626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    final plangText = TextPainter(
      text: const TextSpan(
        text: 'UGD 24 JAM',
        style: TextStyle(
          color: Color(0xFFDC2626),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    plangText.paint(canvas, Offset(w * 0.55 + (120 - plangText.width) / 2, 83));

    // Pintu Kaca UGD Gelap dengan Stiker Merah UGD
    final ugdDoor = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.58, 114, 58, groundY - 114), const Radius.circular(4)),
      ugdDoor,
    );

    // Pilar Silinder Kembar Penyangga Teras Drop-off (Bulat Krem, Persis Foto 4)
    final pillarSpacing = 320.0;
    final pillarStart = -(scrollOffset * 0.5) % pillarSpacing;
    for (double x = pillarStart - pillarSpacing; x < w + pillarSpacing; x += pillarSpacing) {
      _drawDoublePillars(canvas, x, groundY);
    }

    // Mobil Ambulans Asli RSIA (Minibus Silver Metalik + Striping Biru + Logo Matahari)
    final ambX = (w * 0.22) - (scrollOffset * 0.7 % (w * 2.0));
    _drawRealRsiaAmbulance(canvas, ambX, groundY);

    // 3. LANTAI: Paving Interlock Kotak-Kotak Catur Coklat-Krem-Terracotta (PERSIS FOTO ASLI 4)
    _drawInterlockingPavingFloor(canvas, w, h);
  }

  void _drawRoofBanner(Canvas canvas, double w) {
    // Spanduk Banner Hijau & Toska RSIA Aisyiyah Pekajangan
    final bannerRect = Rect.fromLTWH(w * 0.35, 12, w * 0.62, 34);
    final bannerBg = Paint()..color = const Color(0xFF0F766E);
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(5)), bannerBg);

    // Logo Matahari Mini di Kiri Banner
    _drawAisyiyahSunLogo(canvas, w * 0.35 + 20, 29, 11);

    // Tulisan Banner
    final tp = TextPainter(
      text: const TextSpan(
        text: 'RSIA AISYIYAH PEKAJANGAN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.35 + 38, 22));
  }

  void _drawDoublePillars(Canvas canvas, double x, double gY) {
    // Sepasang Pilar Silinder Krem Bersih (Persis di Foto 4)
    final pillarPaint = Paint()..color = const Color(0xFFFDE68A);
    final shadePaint = Paint()..color = const Color(0xFFF59E0B).withOpacity(0.35);

    // Pilar 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, 60, 20, gY - 60), const Radius.circular(8)),
      pillarPaint,
    );
    canvas.drawRect(Rect.fromLTWH(x + 13, 60, 7, gY - 60), shadePaint);

    // Pilar 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 28, 60, 20, gY - 60), const Radius.circular(8)),
      pillarPaint,
    );
    canvas.drawRect(Rect.fromLTWH(x + 41, 60, 7, gY - 60), shadePaint);
  }

  void _drawRealRsiaAmbulance(Canvas canvas, double x, double gY) {
    if (x < -200 || x > 1100) return;
    canvas.save();
    canvas.translate(x, gY - 74);

    // Bodi Utama Ambulans: Minibus Silver Abu-abu Metalik (Daihatsu Gran Max / APV Asli)
    final silverBody = Paint()..color = const Color(0xFFE2E8F0);
    final silverShadow = Paint()..color = const Color(0xFFCBD5E1);

    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 6, 150, 58),
      const Radius.circular(10),
    );
    canvas.drawRRect(bodyRect, silverBody);

    // Bemper & Bagian Bawah
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 48, 150, 16), const Radius.circular(4)),
      silverShadow,
    );

    // Kaca Depan Miring & Kaca Jendela Samping
    final windowGlass = Paint()..color = const Color(0xFF38BDF8).withOpacity(0.35);
    final windowFrame = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Kaca depan
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(10, 12, 34, 24), const Radius.circular(4)),
      windowGlass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(10, 12, 34, 24), const Radius.circular(4)),
      windowFrame,
    );
    // Kaca tengah & belakang
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(50, 12, 44, 24), const Radius.circular(4)),
      windowGlass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(100, 12, 42, 24), const Radius.circular(4)),
      windowGlass,
    );

    // STRIPING BIRU DINAMIS ASLI (Sesuai Foto 4)
    final stripeBlue = Paint()..color = const Color(0xFF0284C7);
    final stripeLight = Paint()..color = const Color(0xFF38BDF8);

    final stripePath = Path();
    stripePath.moveTo(0, 40);
    stripePath.lineTo(150, 40);
    stripePath.lineTo(150, 48);
    stripePath.lineTo(0, 48);
    stripePath.close();
    canvas.drawPath(stripePath, stripeBlue);

    // Striping garis-garis miring khas di samping
    for (int i = 0; i < 4; i++) {
      final sx = 40.0 + (i * 12);
      canvas.drawLine(Offset(sx, 48), Offset(sx + 8, 40), stripeLight..strokeWidth = 2.5);
    }

    // LOGO MATAHARI AISYIYAH BESAR DI BODI SAMPING (Persis Foto 4)
    _drawAisyiyahSunLogo(canvas, 115, 36, 12);

    // Sirine Merah di Atap
    final sirenRed = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(30, 0, 18, 7), const Radius.circular(3)),
      sirenRed,
    );

    // Roda Hitam & Velg Perak
    final tirePaint = Paint()..color = const Color(0xFF0F172A);
    final rimPaint = Paint()..color = const Color(0xFF94A3B8);

    canvas.drawCircle(const Offset(32, 64), 13, tirePaint);
    canvas.drawCircle(const Offset(32, 64), 6, rimPaint);

    canvas.drawCircle(const Offset(118, 64), 13, tirePaint);
    canvas.drawCircle(const Offset(118, 64), 6, rimPaint);

    // Plang Bulat "JALUR AMBULANS" di Samping Mobil (Persis Foto 4)
    final signPole = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.5;
    canvas.drawLine(const Offset(165, 34), const Offset(165, 74), signPole);
    canvas.drawCircle(const Offset(165, 34), 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(165, 34),
      9,
      Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    canvas.restore();
  }

  void _drawInterlockingPavingFloor(Canvas canvas, double w, double h) {
    // Lantai Paving Tegel Bertekstur Kotak-Kotak Catur Coklat Terracotta (PERSIS FOTO 4)
    final baseFloor = Paint()..color = const Color(0xFFD97706); // Terracotta dasar
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), baseFloor);

    // Paving Interlocking pattern
    const double tileSize = 24.0;
    final startX = -(scrollOffset % tileSize);

    final colors = [
      const Color(0xFFFED7AA), // Krem muda
      const Color(0xFFFDBA74), // Oranye peach
      const Color(0xFFFB923C), // Terracotta
      const Color(0xFFF59E0B), // Coklat emas
    ];

    final groutPaint = Paint()
      ..color = const Color(0xFF9A3412).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    int rowIndex = 0;
    for (double y = groundY; y < h; y += tileSize) {
      int colIndex = 0;
      for (double x = startX - tileSize; x < w + tileSize; x += tileSize) {
        final colorIndex = (rowIndex + colIndex) % colors.length;
        final tilePaint = Paint()..color = colors[colorIndex];
        final tileRect = Rect.fromLTWH(x + 1, y + 1, tileSize - 2, tileSize - 2);

        canvas.drawRRect(RRect.fromRectAndRadius(tileRect, const Radius.circular(2)), tilePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(tileRect, const Radius.circular(2)), groutPaint);
        colIndex++;
      }
      rowIndex++;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 2: LOBI & RUANG TUNGGU KURSI BESI CHROME (FOTO 2 & FOTO 5)
  // ─────────────────────────────────────────────────────────────────────────────
  void _renderWaitingLobbyStage(Canvas canvas, double w, double h) {
    // 1. Dinding Panel Kayu Vertikal Lobi RSIA (Foto 5)
    final woodPaint = Paint()..color = const Color(0xFFB45309);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), woodPaint);

    // Strip Panel Kayu Vertikal
    final stripePaint = Paint()
      ..color = const Color(0xFF92400E)
      ..strokeWidth = 1.5;
    for (double x = 0; x < w; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, groundY), stripePaint);
    }

    // 2. Neon Box Huruf Timbul LED di Dinding: "RSIA AISYIYAH PEKAJANGAN" (Foto 5)
    _drawWallNeonSign(canvas, w);

    // 3. Monitor TV Antrean Gantung Besar (Foto 5)
    _drawQueueTvScreen(canvas, w);

    // 4. Pintu Kaca "KANTIN KOPERASI KARYAWAN RSIA" di Sebelah Kiri (Foto 2)
    final doorSpacing = 480.0;
    final doorStart = -(scrollOffset * 0.4) % doorSpacing;
    for (double x = doorStart - doorSpacing; x < w + doorSpacing; x += doorSpacing) {
      _drawKantinGlassDoor(canvas, x, groundY);
    }

    // 5. Deretan Kursi Tunggu Pasien Besi Chrome Lengkung Mengkilap (PERSIS FOTO 2)
    final chairSpacing = 220.0;
    final chairStart = -(scrollOffset * 0.8) % chairSpacing;
    for (double x = chairStart - chairSpacing; x < w + chairSpacing; x += chairSpacing) {
      _drawChromeWaitingChairs(canvas, x, groundY);
    }

    // 6. Lantai Keramik Putih Mengkilap Bersih (Foto 2)
    final tileFloor = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), tileFloor);

    // Nat Keramik Putih Mengkilap
    final natPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;
    const tileW = 60.0;
    final startNatX = -(scrollOffset % tileW);
    for (double x = startNatX - tileW; x < w + tileW; x += tileW) {
      canvas.drawLine(Offset(x, groundY), Offset(x - 30, h), natPaint);
    }
  }

  void _drawWallNeonSign(Canvas canvas, double w) {
    // Neon Box Akrilik Putih dengan LED Pendar (Persis Foto 5)
    final signRect = Rect.fromCenter(center: Offset(w * 0.45, 48), width: 220, height: 42);

    // Glow cahaya indirect putih
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(RRect.fromRectAndRadius(signRect, const Radius.circular(8)), glowPaint);

    // Box Akrilik Putih
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, const Radius.circular(6)),
      Paint()..color = Colors.white,
    );

    // Logo Matahari Aisyiyah di Kiri Sign
    _drawAisyiyahSunLogo(canvas, w * 0.45 - 86, 48, 12);

    // Teks 3D Biru Tua: "RSIA AISYIYAH PEKAJANGAN"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'RSIA AISYIYAH\nPEKAJANGAN',
        style: TextStyle(
          color: Color(0xFF1E3A8A),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          height: 1.15,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(w * 0.45 - 68, 38));
  }

  void _drawQueueTvScreen(Canvas canvas, double w) {
    // Monitor TV Antrean Besar Menggantung di Kanan (Persis Foto 5)
    final tvRect = Rect.fromLTWH(w * 0.72, 18, 105, 58);
    // Frame Monitor
    canvas.drawRRect(
      RRect.fromRectAndRadius(tvRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF0F172A),
    );

    // Header Toska Layar
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.72 + 3, 21, 99, 14), const Radius.circular(3)),
      Paint()..color = const Color(0xFF0D9488),
    );

    // Badan Layar Biru Muda Info Antrean
    canvas.drawRect(
      Rect.fromLTWH(w * 0.72 + 3, 35, 99, 38),
      Paint()..color = const Color(0xFF38BDF8),
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'ANTREAN: B9',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.72 + 14, 46));
  }

  void _drawKantinGlassDoor(Canvas canvas, double x, double gY) {
    // Pintu Kaca Putih "KANTIN KOPERASI" (Foto 2)
    final doorRect = Rect.fromLTWH(x, gY - 110, 80, 110);
    canvas.drawRect(doorRect, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(x + 4, gY - 106, 72, 102),
      Paint()..color = const Color(0x5538BDF8),
    );

    // Stiker Logo Matahari di Kaca
    _drawAisyiyahSunLogo(canvas, x + 40, gY - 75, 10);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'KANTIN\nKOPERASI RSIA',
        style: TextStyle(
          color: Color(0xFFB45309),
          fontSize: 7,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + 12, gY - 55));
  }

  void _drawChromeWaitingChairs(Canvas canvas, double x, double gY) {
    // Kursi Tunggu Pasien Besi Chrome Lengkung Mengkilap (PERSIS FOTO 2)
    canvas.save();
    canvas.translate(x, gY - 36);

    final chromePaint = Paint()..color = const Color(0xFFCBD5E1);
    final chromeShine = Paint()..color = Colors.white;
    final seatBlack = Paint()..color = const Color(0xFF1E293B); // Jok bantalan hitam

    // 3 Dudukan Kursi Berjejer
    for (int i = 0; i < 3; i++) {
      final cx = i * 26.0;

      // Sandaran Melengkung Hitam
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx, 0, 22, 18), const Radius.circular(4)),
        seatBlack,
      );
      // Bingkai Besi Chrome Mengkilap
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx, 0, 22, 18), const Radius.circular(4)),
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Jok Dudukan Hitam
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx, 18, 22, 8), const Radius.circular(3)),
        seatBlack,
      );
    }

    // Pegangan Tangan Melengkung Chrome di Kiri dan Kanan (Sangat Khas di Foto 2)
    final armPathLeft = Path();
    armPathLeft.moveTo(-4, 16);
    armPathLeft.quadraticBezierTo(-8, 8, -2, 2);
    canvas.drawPath(armPathLeft, Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 3.0..style = PaintingStyle.stroke);

    final armPathRight = Path();
    armPathRight.moveTo(76, 16);
    armPathRight.quadraticBezierTo(80, 8, 74, 2);
    canvas.drawPath(armPathRight, Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 3.0..style = PaintingStyle.stroke);

    // Kaki Penyangga Melengkung Chrome (Foto 2)
    canvas.drawLine(const Offset(-4, 26), const Offset(78, 26), chromePaint..strokeWidth = 3.5);
    canvas.drawLine(const Offset(6, 26), const Offset(2, 36), chromePaint..strokeWidth = 3.0);
    canvas.drawLine(const Offset(68, 26), const Offset(72, 36), chromePaint..strokeWidth = 3.0);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 3: NURSE STATION & PINTU POLIKLINIK RESMI (FOTO 1 & FOTO 3)
  // ─────────────────────────────────────────────────────────────────────────────
  void _renderNurseStationClinicStage(Canvas canvas, double w, double h) {
    // 1. Dinding Interior Krem Cerah Poliklinik (Foto 1 & 3)
    final wallPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), wallPaint);

    // Plafon Drop Ceiling dengan Lampu Downlight (Foto 1)
    final ceilingPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 28), ceilingPaint);
    for (double x = 40; x < w; x += 100) {
      canvas.drawCircle(Offset(x, 14), 6, Paint()..color = const Color(0xFFFEF08A));
    }

    // 2. Pintu Masuk Kaca POLIKLINIK (Foto 3)
    final doorSpacing = 420.0;
    final doorStart = -(scrollOffset * 0.4) % doorSpacing;
    for (double x = doorStart - doorSpacing; x < w + doorSpacing; x += doorSpacing) {
      _drawPoliklinikDoor(canvas, x, groundY);
    }

    // 3. Nurse Station Konter Pelayanan (Foto 1)
    final stationSpacing = 460.0;
    final stationStart = -(scrollOffset * 0.8) % stationSpacing;
    for (double x = stationStart - stationSpacing; x < w + stationSpacing; x += stationSpacing) {
      _drawNurseStationDesk(canvas, x, groundY);
    }

    // 4. Lantai Keramik Mengkilap Putih Bersih
    final floorPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), floorPaint);

    // List Tile Keramik
    final natPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;
    for (double x = -(scrollOffset % 50); x < w + 50; x += 50) {
      canvas.drawLine(Offset(x, groundY), Offset(x - 25, h), natPaint);
    }
  }

  void _drawPoliklinikDoor(Canvas canvas, double x, double gY) {
    // Plang Hitam di Atas Pintu Kaca: "POLIKLINIK" Warna Kuning Tebal (PERSIS FOTO 3)
    final signRect = Rect.fromLTWH(x + 6, gY - 145, 96, 24);
    canvas.drawRect(signRect, Paint()..color = const Color(0xFF0F172A));

    final tp = TextPainter(
      text: const TextSpan(
        text: 'POLIKLINIK',
        style: TextStyle(
          color: Color(0xFFFACC15), // Kuning tebal
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + 6 + (96 - tp.width) / 2, gY - 141));

    // Pintu Kaca Tempered Ganda Bening
    final glassDoor = Rect.fromLTWH(x, gY - 120, 108, 120);
    canvas.drawRect(glassDoor, Paint()..color = const Color(0x4438BDF8));
    canvas.drawRect(
      glassDoor,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Garis Kaca Sandblast Buram Horizontal (Foto 3)
    final sandblast = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawRect(Rect.fromLTWH(x + 4, gY - 75, 100, 20), sandblast);

    // Dua Logo Matahari Aisyiyah di Kaca (Kiri & Kanan, Foto 3)
    _drawAisyiyahSunLogo(canvas, x + 30, gY - 80, 9);
    _drawAisyiyahSunLogo(canvas, x + 78, gY - 80, 9);

    // Handle Stainless Steel Vertikal Panjang (Foto 3)
    final handlePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(x + 50, gY - 80), Offset(x + 50, gY - 40), handlePaint);
    canvas.drawLine(Offset(x + 58, gY - 80), Offset(x + 58, gY - 40), handlePaint);

    // Keset Hitam di Depan Pintu
    canvas.drawRect(Rect.fromLTWH(x + 24, gY + 4, 60, 6), Paint()..color = const Color(0xFF1E293B));
  }

  void _drawNurseStationDesk(Canvas canvas, double x, double gY) {
    // Meja Nurse Station & Neon Box di Dinding Belakang (PERSIS FOTO 1)
    canvas.save();
    canvas.translate(x, gY - 58);

    // Neon Box di Dinding Belakang Meja: "RSIA AISYIYAH PEKAJANGAN" (Foto 1)
    final neonBox = Rect.fromLTWH(10, -38, 130, 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(neonBox, const Radius.circular(5)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(neonBox, const Radius.circular(5)),
      Paint()
        ..color = const Color(0xFFFEF08A).withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    _drawAisyiyahSunLogo(canvas, 24, -23, 8);
    final signText = TextPainter(
      text: const TextSpan(
        text: 'RSIA AISYIYAH\nPEKAJANGAN',
        style: TextStyle(
          color: Color(0xFF1E3A8A),
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    signText.paint(canvas, const Offset(36, -30));

    // Meja Konter Kayu & Putih (Foto 1)
    final woodTop = Paint()..color = const Color(0xFFD97706); // Panel kayu coklat muda
    final whiteFront = Paint()..color = Colors.white;
    final blackStripe = Paint()..color = const Color(0xFF0F172A);

    // Badan Meja
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 150, 58), const Radius.circular(6)),
      whiteFront,
    );
    // Panel Kayu di Samping
    canvas.drawRect(const Rect.fromLTWH(0, 0, 24, 58), woodTop);
    canvas.drawRect(const Rect.fromLTWH(126, 0, 24, 58), woodTop);
    // Strip Hitam Modern di Bagian Tengah Meja
    canvas.drawRect(const Rect.fromLTWH(26, 14, 98, 36), blackStripe);

    // Kursi Lipat Perak Staf di Belakang Meja (Foto 1)
    canvas.drawRect(const Rect.fromLTWH(62, -14, 26, 14), Paint()..color = const Color(0xFF94A3B8));

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HELPER: LOGO MATAHARI BULAT RESMI RSIA AISYIYAH PEKAJANGAN
  // ─────────────────────────────────────────────────────────────────────────────
  void _drawAisyiyahSunLogo(Canvas canvas, double cx, double cy, double radius) {
    // Sinar Matahari Kuning Berputar di Lingkaran Luar
    final sunRays = Paint()..color = const Color(0xFFFACC15);
    for (int i = 0; i < 12; i++) {
      final angle = i * (pi / 6);
      final rx = cx + cos(angle) * (radius + 2.5);
      final ry = cy + sin(angle) * (radius + 2.5);
      canvas.drawCircle(Offset(rx, ry), 1.5, sunRays);
    }

    // Lingkaran Hijau Tengah
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = const Color(0xFF0D9488));
    // Lingkaran Kuning Dalam
    canvas.drawCircle(Offset(cx, cy), radius * 0.7, Paint()..color = const Color(0xFFFACC15));
    // Inti Hijau
    canvas.drawCircle(Offset(cx, cy), radius * 0.4, Paint()..color = const Color(0xFF065F46));
  }
}
