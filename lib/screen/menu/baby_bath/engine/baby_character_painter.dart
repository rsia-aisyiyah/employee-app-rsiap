import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/baby_bath_models.dart';
import 'foam_particle_system.dart';

/// Renderer Kartun Karakter Bayi & Bak Mandi RSIA secara Prosedural di Canvas
class BabyCharacterPainter extends CustomPainter {
  final BathPhase phase;
  final BabyMood mood;
  final double animationTime;
  final FoamParticleSystem particleSystem;
  final double cleanlinessProgress;
  final double waterLevel; // 0.0 s.d. 1.0
  final double waterTemp; // misal 37.0 C
  final Offset duckPosition;
  final bool isDuckSqueaking;
  final List<BabyDirtSpot> dirtSpots;
  final List<BabyFloatingToast> floatingToasts;
  final bool isBabyInCrib;
  final String babyName;
  final Color swaddleColor;

  BabyCharacterPainter({
    required this.phase,
    required this.mood,
    required this.animationTime,
    required this.particleSystem,
    required this.cleanlinessProgress,
    required this.waterLevel,
    required this.waterTemp,
    required this.duckPosition,
    this.dirtSpots = const [],
    this.isDuckSqueaking = false,
    this.floatingToasts = const [],
    this.isBabyInCrib = false,
    this.babyName = "Bayi Ny. Annisa",
    this.swaddleColor = const Color(0xFFBAE6FD),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;

    // ── SCENE KHUSUS: Mengembalikan Bayi ke Tempat Tidur (Baby Crib) ──
    if (phase == BathPhase.returnToCrib) {
      _drawBabyCribScene(canvas, size, cx, cy);
      _drawFloatingToasts(canvas, size);
      return;
    }

    // ── 1. Menggambar Bak Mandi Bayi (Bathtub) ──
    _drawBathtubBackground(canvas, size, cx, cy);

    // ── 2. Menggambar Air Hangat di Bak Mandi ──
    if (waterLevel > 0.05) {
      _drawWaterLayer(canvas, size, cx, cy);
    }

    // ── 3. Menggambar Karakter Bayi Lucu ──
    _drawCuteBaby(canvas, size, cx, cy);

    // ── 4. Mainan Bebek Karet Mengapung (Rubber Duck) ──
    if (phase == BathPhase.bodyScrub || phase == BathPhase.waterPrep || phase == BathPhase.rinsing) {
      _drawRubberDuck(canvas, duckPosition.dx, duckPosition.dy);
    }

    // ── 5. Partikel Busa Sabun & Percikan Air ──
    _drawParticles(canvas);

    // ── 6. Bibir Depan Bak Mandi & Ornamen Halus ──
    _drawBathtubFrontRim(canvas, size, cx, cy);

    // ── 7. Notifikasi Teks Melayang (Floating Feedback Toasts) ──
    _drawFloatingToasts(canvas, size);
  }

  /// Gambar Bak Mandi Bayi (Latar Belakang Dinding Dalam)
  void _drawBathtubBackground(Canvas canvas, Size size, double cx, double cy) {
    final tubRect = Rect.fromCenter(
      center: Offset(cx, cy + 30),
      width: size.width * 0.88,
      height: size.height * 0.44,
    );

    // Bayangan bak mandi di lantai
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + tubRect.height * 0.5 + 45),
        width: tubRect.width * 0.86,
        height: 28,
      ),
      shadowPaint,
    );

    // Dinding dalam bak mandi (Cyan lembut RSIA)
    final tubInnerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE0F2FE),
          Color(0xFFBAE6FD),
        ],
      ).createShader(tubRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(tubRect, const Radius.circular(55)),
      tubInnerPaint,
    );
  }

  /// Gambar Lapisan Air Bergelombang
  void _drawWaterLayer(Canvas canvas, Size size, double cx, double cy) {
    final waterY = cy + 45 - (waterLevel * 40);
    final waterRect = Rect.fromCenter(
      center: Offset(cx, cy + 50),
      width: size.width * 0.80,
      height: size.height * 0.30,
    );

    final isOptimalTemp = waterTemp >= 36.5 && waterTemp <= 37.5;
    final waterColors = isOptimalTemp
        ? [
            const Color(0xFF38BDF8).withValues(alpha: 0.45),
            const Color(0xFF0284C7).withValues(alpha: 0.65),
          ]
        : (waterTemp > 38.0
            ? [
                const Color(0xFFF87171).withValues(alpha: 0.45),
                const Color(0xFFEF4444).withValues(alpha: 0.60),
              ]
            : [
                const Color(0xFF93C5FD).withValues(alpha: 0.45),
                const Color(0xFF3B82F6).withValues(alpha: 0.60),
              ]);

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: waterColors,
      ).createShader(waterRect);

    // Gelombang mikro air
    final path = Path();
    path.moveTo(cx - waterRect.width / 2, waterY);
    for (double x = cx - waterRect.width / 2; x <= cx + waterRect.width / 2; x += 15) {
      final wave = math.sin((x * 0.04) + (animationTime * 3.5)) * 3.5;
      path.lineTo(x, waterY + wave);
    }
    path.lineTo(cx + waterRect.width / 2, cy + 120);
    path.lineTo(cx - waterRect.width / 2, cy + 120);
    path.close();

    canvas.drawPath(path, waterPaint);
  }

  /// Gambar Bayi Lucu Prosedural
  void _drawCuteBaby(Canvas canvas, Size size, double cx, double cy) {
    final babyY = cy - 25 + math.sin(animationTime * 2.0) * 2.0;

    // ── Tubuh Bayi (Soft Warm Skin) ──
    final skinPaint = Paint()
      ..color = const Color(0xFFFFDFBA); // Kulit bayi lembut hangat

    // Badan bayi di dalam air
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, babyY + 65), width: 110, height: 95),
      skinPaint,
    );

    // Tangan kiri & kanan mengayun
    final armSwing = math.sin(animationTime * 4.0) * 6.0;
    final leftWrist = Offset(cx - 52, babyY + 58 + armSwing);
    final rightWrist = Offset(cx + 52, babyY + 58 - armSwing);

    canvas.drawCircle(leftWrist, 15, skinPaint);
    canvas.drawCircle(rightWrist, 15, skinPaint);

    // ── Kepala Bayi (Chubby Cute Head) ──
    final headRect = Rect.fromCenter(
      center: Offset(cx, babyY),
      width: 125,
      height: 115,
    );
    canvas.drawOval(headRect, skinPaint);

    // Pipi Chubby Kemerahan (Blush)
    final blushColor = mood == BabyMood.crying
        ? const Color(0xFFEF4444).withValues(alpha: 0.35) // pipi memerah saat menangis
        : const Color(0xFFF472B6).withValues(alpha: 0.40);
    final blushPaint = Paint()..color = blushColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 36, babyY + 14), width: 22, height: 14),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 36, babyY + 14), width: 22, height: 14),
      blushPaint,
    );

    // ── Mata Bayi Dinamis (Berkedip, Sensitif Sabun, & Emosi) ──
    _drawBabyEyes(canvas, cx, babyY);

    // ── Mulut Bayi ──
    _drawBabyMouth(canvas, cx, babyY);

    // ── Rambut Bayi Halus Sejumput (Baby Hair Curl) ──
    final hairPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final hairPath = Path();
    hairPath.moveTo(cx, babyY - 55);
    hairPath.quadraticBezierTo(cx - 8, babyY - 72, cx + 5, babyY - 75);
    canvas.drawPath(hairPath, hairPaint);

    // Busa sampo di kepala jika fase keramas
    if (cleanlinessProgress > 0 && phase == BathPhase.faceAndHair) {
      final foamPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
      canvas.drawCircle(Offset(cx - 20, babyY - 50), 12, foamPaint);
      canvas.drawCircle(Offset(cx + 15, babyY - 53), 14, foamPaint);
      canvas.drawCircle(Offset(cx, babyY - 58), 16, foamPaint);
    }

    // ── Titik Noda Medis & Gumpalan Busa Sabun Tubuh ──
    _drawDirtSpotsAndFoam(canvas, cx, babyY);
  }

  /// Gambar Titik Noda Visual & Efek Busa Sabun Interaktif
  void _drawDirtSpotsAndFoam(Canvas canvas, double cx, double babyY) {
    if (dirtSpots.isEmpty) return;

    for (final spot in dirtSpots) {
      final spotPos = Offset(cx + spot.dxOffset, babyY + spot.dyOffset);

      // Tampilkan noda jika berada di fase aktif dan belum bersih sempurna
      if (spot.phase == phase && !spot.isClean) {
        final spotAlpha = ((1.0 - spot.cleanliness) * 0.70).clamp(0.08, 0.75);
        final spotPaint = Paint()..color = spot.spotColor.withValues(alpha: spotAlpha);

        // Lingkaran noda kotoran / verniks
        canvas.drawCircle(spotPos, spot.radius, spotPaint);

        // Cincin panduan usap berdenyut lembut
        final pulse = math.sin((animationTime * 4.0) + (spot.dxOffset * 0.1)) * 2.5;
        final ringPaint = Paint()
          ..color = spot.spotColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawCircle(spotPos, spot.radius + 3.0 + pulse, ringPaint);
      }

      // Tampilkan busa jika titik ini berbusa dan belum dibilas
      if (spot.isFoamed && !spot.isRinsed) {
        final foamWhite = Paint()..color = Colors.white.withValues(alpha: 0.90);
        final foamShadow = Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.65);

        // Klaster 3 bulatan busa sabun
        canvas.drawCircle(spotPos, spot.radius * 0.85, foamShadow);
        canvas.drawCircle(spotPos + const Offset(-3, -2), spot.radius * 0.65, foamWhite);
        canvas.drawCircle(spotPos + const Offset(4, 2), spot.radius * 0.60, foamWhite);
        canvas.drawCircle(spotPos + const Offset(0, -4), spot.radius * 0.50, foamWhite);
      }
    }
  }

  void _drawBabyEyes(Canvas canvas, double cx, double babyY) {
    final eyePaint = Paint()..color = const Color(0xFF1E293B);
    final eyeWhite = Paint()..color = Colors.white;

    // Interval kedipan mata setiap ~3.5 detik
    final bool isBlinking = (animationTime % 3.5) < 0.16;

    if (mood == BabyMood.crying) {
      // ── MATA MENYIPIT MENANGIS (Kena Sabun / Pedih) ──
      final cryEyePaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;

      // Bentuk melengkung rapat > <
      final p1 = Path()
        ..moveTo(cx - 32, babyY + 1)
        ..quadraticBezierTo(cx - 24, babyY - 7, cx - 16, babyY + 1);
      final p2 = Path()
        ..moveTo(cx + 16, babyY + 1)
        ..quadraticBezierTo(cx + 24, babyY - 7, cx + 32, babyY + 1);

      canvas.drawPath(p1, cryEyePaint);
      canvas.drawPath(p2, cryEyePaint);

      // Tetesan air mata mengalir di kedua pipi
      final tearPaint = Paint()..color = const Color(0xFF38BDF8);
      final tearOffset = (math.sin(animationTime * 6.0) * 4.0).abs();
      canvas.drawCircle(Offset(cx - 34, babyY + 10 + tearOffset), 3.5, tearPaint);
      canvas.drawCircle(Offset(cx + 34, babyY + 10 + tearOffset), 3.5, tearPaint);

      // Partikel buih sabun kecil pedih di dekat mata
      final soapBubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      canvas.drawCircle(Offset(cx - 22, babyY - 6), 2.5, soapBubblePaint);
      canvas.drawCircle(Offset(cx + 22, babyY - 6), 2.5, soapBubblePaint);
    } else if (isBlinking || mood == BabyMood.giggling) {
      // Mata menyipit senang (smile eyes)
      final happyEyePaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      final p1 = Path()
        ..moveTo(cx - 32, babyY - 2)
        ..quadraticBezierTo(cx - 24, babyY + 5, cx - 16, babyY - 2);
      final p2 = Path()
        ..moveTo(cx + 16, babyY - 2)
        ..quadraticBezierTo(cx + 24, babyY + 5, cx + 32, babyY - 2);

      canvas.drawPath(p1, happyEyePaint);
      canvas.drawPath(p2, happyEyePaint);
    } else {
      // Mata bulat imut dengan kilau putih (Sparkle eyes)
      // Mata Kiri
      canvas.drawCircle(Offset(cx - 24, babyY - 1), 7.5, eyePaint);
      canvas.drawCircle(Offset(cx - 26, babyY - 3), 2.5, eyeWhite);
      canvas.drawCircle(Offset(cx - 22, babyY + 1), 1.2, eyeWhite);

      // Mata Kanan
      canvas.drawCircle(Offset(cx + 24, babyY - 1), 7.5, eyePaint);
      canvas.drawCircle(Offset(cx + 22, babyY - 3), 2.5, eyeWhite);
      canvas.drawCircle(Offset(cx + 26, babyY + 1), 1.2, eyeWhite);
    }
  }

  void _drawBabyMouth(Canvas canvas, double cx, double babyY) {
    final mouthPaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.fill;

    if (mood == BabyMood.crying) {
      // Mulut terbuka menangis
      final path = Path()
        ..moveTo(cx - 11, babyY + 22)
        ..quadraticBezierTo(cx, babyY + 34, cx + 11, babyY + 22)
        ..close();
      canvas.drawPath(path, mouthPaint);
    } else if (mood == BabyMood.giggling) {
      // Tertawa riang terbuka
      final path = Path()
        ..moveTo(cx - 12, babyY + 18)
        ..quadraticBezierTo(cx, babyY + 30, cx + 12, babyY + 18)
        ..close();
      canvas.drawPath(path, mouthPaint);
    } else {
      // Senyum imut kecil
      final smilePaint = Paint()
        ..color = const Color(0xFFE11D48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(cx - 8, babyY + 20)
        ..quadraticBezierTo(cx, babyY + 26, cx + 8, babyY + 20);
      canvas.drawPath(path, smilePaint);
    }
  }

  /// Gambar Mainan Bebek Karet Mengapung (Rubber Duck)
  void _drawRubberDuck(Canvas canvas, double dx, double dy) {
    final bobbingY = dy + math.sin(animationTime * 4.0) * 3.5;
    final scale = isDuckSqueaking ? 1.2 : 1.0;

    canvas.save();
    canvas.translate(dx, bobbingY);
    canvas.scale(scale);

    final duckYellow = Paint()..color = const Color(0xFFFBBF24);
    final duckOrange = Paint()..color = const Color(0xFFF97316);
    final duckEye = Paint()..color = Colors.black;

    // Badan bebek
    canvas.drawOval(const Rect.fromLTWH(-16, -10, 32, 22), duckYellow);

    // Ekor bebek lancip di belakang
    final tailPath = Path()
      ..moveTo(-14, -6)
      ..lineTo(-22, -14)
      ..lineTo(-8, -2)
      ..close();
    canvas.drawPath(tailPath, duckYellow);

    // Kepala bebek
    canvas.drawCircle(const Offset(10, -12), 11, duckYellow);

    // Paruh oranye
    final beakPath = Path()
      ..moveTo(18, -14)
      ..lineTo(28, -10)
      ..lineTo(18, -6)
      ..close();
    canvas.drawPath(beakPath, duckOrange);

    // Mata bebek
    canvas.drawCircle(const Offset(12, -15), 2.2, duckEye);
    canvas.drawCircle(const Offset(11.5, -15.5), 0.8, Paint()..color = Colors.white);

    canvas.restore();
  }

  /// Gambar Partikel Busa dan Percikan Air
  void _drawParticles(Canvas canvas) {
    // 1. Gambar Busa
    for (final b in particleSystem.bubbles) {
      final bubblePaint = Paint()
        ..color = b.color.withValues(alpha: b.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(b.x, b.y), b.radius, bubblePaint);

      // Kilau cahaya gelembung
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: b.alpha * 0.75);
      canvas.drawCircle(
        Offset(b.x - b.radius * 0.35, b.y - b.radius * 0.35),
        b.radius * 0.28,
        highlightPaint,
      );
    }

    // 2. Gambar Percikan Air
    for (final s in particleSystem.splashes) {
      final splashPaint = Paint()
        ..color = s.color.withValues(alpha: s.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(s.x, s.y), s.radius, splashPaint);
    }
  }

  /// Gambar Bibir Depan Bak Mandi & Emblem Ornamen RSIA Aisyiyah
  void _drawBathtubFrontRim(Canvas canvas, Size size, double cx, double cy) {
    final tubRect = Rect.fromCenter(
      center: Offset(cx, cy + 30),
      width: size.width * 0.88,
      height: size.height * 0.44,
    );

    final rimPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    canvas.drawRRect(
      RRect.fromRectAndRadius(tubRect, const Radius.circular(55)),
      rimPaint,
    );

    // Bibir highlight kilau bak mandi
    final rimHighlight = Paint()
      ..color = const Color(0xFFBAE6FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(tubRect, const Radius.circular(55)),
      rimHighlight,
    );

    // ── Ornamen Resmi RSIA Aisyiyah di Dinding Depan Bak Mandi ──
    final badgeCenter = Offset(cx, cy + tubRect.height * 0.5 + 24);
    _drawRsiaTubBadge(canvas, badgeCenter);
  }

  /// Ornamen Bersih Simbol Perinatologi di Dinding Bak Mandi
  void _drawRsiaTubBadge(Canvas canvas, Offset center) {
    // Background Pill Badge Bersih
    final badgeRect = Rect.fromCenter(center: center, width: 70, height: 22);
    final badgeBg = Paint()..color = Colors.white;
    final badgeBorder = Paint()
      ..color = const Color(0xFF0D9488) // Tosca RSIA
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rrect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(11));
    canvas.drawRRect(rrect, badgeBg);
    canvas.drawRRect(rrect, badgeBorder);

    // Simbol Hati & Daun Kasih Sayang Perinatologi
    final heartPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - 10, center.dy), 4.5, heartPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - 2), 4.5, heartPaint);
    canvas.drawCircle(Offset(center.dx + 10, center.dy), 4.5, heartPaint);
  }

  /// Gambar Scene Tempat Tidur Bayi (Baby Bassinet / Crib)
  void _drawBabyCribScene(Canvas canvas, Size size, double cx, double cy) {
    final cribY = cy + 10;

    // ── 1. Rangka Tiang & Kaki Boks Bayi Modern ──
    final standPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Tiang kaki kiri & kanan
    canvas.drawLine(Offset(cx - 85, cribY + 65), Offset(cx - 95, cribY + 155), standPaint);
    canvas.drawLine(Offset(cx + 85, cribY + 65), Offset(cx + 95, cribY + 155), standPaint);
    // Palang horizontal bawah
    canvas.drawLine(Offset(cx - 105, cribY + 150), Offset(cx + 105, cribY + 150), standPaint);

    // 4 Roda Boks Bayi (Wheels)
    final wheelPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawCircle(Offset(cx - 105, cribY + 158), 6, wheelPaint);
    canvas.drawCircle(Offset(cx - 85, cribY + 158), 5, wheelPaint);
    canvas.drawCircle(Offset(cx + 85, cribY + 158), 5, wheelPaint);
    canvas.drawCircle(Offset(cx + 105, cribY + 158), 6, wheelPaint);

    // ── 2. Keranjang Akrilik Transparan Boks Bayi (Acrylic Bassinet) ──
    final cribRect = Rect.fromCenter(center: Offset(cx, cribY), width: 235, height: 140);
    final cribBg = Paint()..color = const Color(0xFFF0FDFA).withValues(alpha: 0.95);
    final cribBorder = Paint()
      ..color = const Color(0xFF0D9488).withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final cribRRect = RRect.fromRectAndRadius(cribRect, const Radius.circular(32));
    canvas.drawRRect(cribRRect, cribBg);
    canvas.drawRRect(cribRRect, cribBorder);

    // ── 3. Kasur Bayi Empuk & Bantal ──
    final mattressRect = Rect.fromCenter(center: Offset(cx, cribY + 12), width: 205, height: 95);
    final mattressPaint = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(mattressRect, const Radius.circular(22)), mattressPaint);

    // Bantal kepala bayi (Pillow)
    final pillowRect = Rect.fromCenter(center: Offset(cx, cribY - 14), width: 100, height: 42);
    final pillowPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawRRect(RRect.fromRectAndRadius(pillowRect, const Radius.circular(16)), pillowPaint);

    // ── 4. Label Akrilik di Depan Boks (Nama Bayi) ──
    final nameTagRect = Rect.fromCenter(center: Offset(cx, cribY + 70), width: 170, height: 26);
    final nameTagBg = Paint()..color = Colors.white;
    final nameTagBorder = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final tagRRect = RRect.fromRectAndRadius(nameTagRect, const Radius.circular(8));
    canvas.drawRRect(tagRRect, nameTagBg);
    canvas.drawRRect(tagRRect, nameTagBorder);

    final nameSpan = TextSpan(
      text: "🛏️ $babyName",
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F766E),
      ),
    );
    final nameTp = TextPainter(text: nameSpan, textDirection: TextDirection.ltr);
    nameTp.layout(maxWidth: 160);
    nameTp.paint(canvas, Offset(cx - nameTp.width / 2, cribY + 70 - nameTp.height / 2));

    // ── 5. Bayi di Atas Menunggu Ditaruh ATAU Sudah di Boks ──
    if (!isBabyInCrib) {
      final bobbing = math.sin(animationTime * 3.5) * 8.0;
      final babyCenter = Offset(cx, cribY - 80 + bobbing);
      _drawSwaddledBaby(canvas, babyCenter, false);

      // Teks instruksi
      const promptSpan = TextSpan(
        text: "👇 Ketuk Boks untuk Menaruh Bayi",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0284C7),
        ),
      );
      final promptTp = TextPainter(text: promptSpan, textDirection: TextDirection.ltr);
      promptTp.layout();
      promptTp.paint(canvas, Offset(cx - promptTp.width / 2, cribY - 145));
    } else {
      final babyCenter = Offset(cx, cribY - 6);
      _drawSwaddledBaby(canvas, babyCenter, true);

      // Selimut lembut menutupi dada
      final blanketRect = Rect.fromCenter(center: Offset(cx, cribY + 32), width: 195, height: 55);
      final blanketPaint = Paint()..color = swaddleColor.withValues(alpha: 0.94);
      canvas.drawRRect(RRect.fromRectAndRadius(blanketRect, const Radius.circular(16)), blanketPaint);

      // Efek Gelembung Tidur "Zzz..."
      _drawSleepingZzz(canvas, cx + 46, cribY - 32);
    }
  }

  /// Menggambar Karakter Bayi yang Dibedong Hangat (Swaddled Baby)
  void _drawSwaddledBaby(Canvas canvas, Offset center, bool isSleeping) {
    final skinPaint = Paint()..color = const Color(0xFFFFDFC4);
    final swaddlePaint = Paint()..color = swaddleColor;

    // Tubuh dibedong (Swaddle Wrap)
    final bodyRect = Rect.fromCenter(center: Offset(center.dx, center.dy + 35), width: 85, height: 95);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(35)), swaddlePaint);

    // Kepala Bayi
    final headCenter = Offset(center.dx, center.dy - 10);
    canvas.drawCircle(headCenter, 34, skinPaint);

    // Pipi Merona
    final blushPaint = Paint()..color = const Color(0xFFF472B6).withValues(alpha: 0.40);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 18, center.dy - 3), width: 14, height: 9), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 18, center.dy - 3), width: 14, height: 9), blushPaint);

    // Mata (Terpejam Bahagia / Melek Senyum)
    final eyePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    if (isSleeping) {
      // Mata terpejam tersenyum lengkung
      final leftPath = Path()..addArc(Rect.fromCenter(center: Offset(center.dx - 14, center.dy - 12), width: 14, height: 10), 0, math.pi);
      final rightPath = Path()..addArc(Rect.fromCenter(center: Offset(center.dx + 14, center.dy - 12), width: 14, height: 10), 0, math.pi);
      canvas.drawPath(leftPath, eyePaint);
      canvas.drawPath(rightPath, eyePaint);
    } else {
      // Mata melek imut
      canvas.drawCircle(Offset(center.dx - 14, center.dy - 12), 4, Paint()..color = const Color(0xFF1E293B));
      canvas.drawCircle(Offset(center.dx + 14, center.dy - 12), 4, Paint()..color = const Color(0xFF1E293B));
    }

    // Mulut Senyum
    final mouthPath = Path()..addArc(Rect.fromCenter(center: Offset(center.dx, center.dy), width: 12, height: 8), 0, math.pi);
    canvas.drawPath(mouthPath, eyePaint);

    // Rambut Bayi Halus
    final hairPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final hairPath = Path();
    hairPath.moveTo(center.dx, center.dy - 44);
    hairPath.quadraticBezierTo(center.dx - 6, center.dy - 56, center.dx + 4, center.dy - 58);
    canvas.drawPath(hairPath, hairPaint);
  }

  /// Menggambar Efek "Zzz..." Saat Bayi Tidur di Boks
  void _drawSleepingZzz(Canvas canvas, double startX, double startY) {
    const letters = ["z", "Z", "Z"];
    for (int i = 0; i < letters.length; i++) {
      final float = math.sin((animationTime * 2.0) + (i * 1.2)) * 4.0;
      final x = startX + (i * 14.0);
      final y = startY - (i * 15.0) + float;

      final tp = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: TextStyle(
            fontSize: 12.0 + (i * 3.5),
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0284C7).withValues(alpha: 0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  /// Gambar Notifikasi Floating Feedback di Canvas
  void _drawFloatingToasts(Canvas canvas, Size size) {
    for (final toast in floatingToasts) {
      final alpha = (toast.lifeTime / 1.2).clamp(0.0, 1.0);
      final y = toast.position.dy + toast.yOffset;
      final x = toast.position.dx.clamp(70.0, size.width - 70.0);

      final textSpan = TextSpan(
        text: toast.text,
        style: TextStyle(
          color: toast.isWarning ? const Color(0xFFDC2626) : const Color(0xFF0369A1),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();

      final bubbleRect = Rect.fromCenter(
        center: Offset(x, y),
        width: tp.width + 20,
        height: tp.height + 10,
      );

      final bgPaint = Paint()
        ..color = (toast.isWarning ? const Color(0xFFFEE2E2) : Colors.white).withValues(alpha: alpha * 0.95);
      final borderPaint = Paint()
        ..color = (toast.isWarning ? const Color(0xFFF87171) : const Color(0xFF38BDF8)).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final rrect = RRect.fromRectAndRadius(bubbleRect, const Radius.circular(12));
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);

      tp.paint(canvas, Offset(bubbleRect.left + 10, bubbleRect.top + 5));
    }
  }

  @override
  bool shouldRepaint(covariant BabyCharacterPainter oldDelegate) => true;
}
