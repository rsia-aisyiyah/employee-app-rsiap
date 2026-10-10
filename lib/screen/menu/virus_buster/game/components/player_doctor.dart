import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/models/virus_buster_models.dart';

class PlayerDoctor extends PositionComponent with HasGameRef, CollisionCallbacks {
  final HeroConfig heroConfig;

  // Movement & Physics
  double velocityX = 0.0;
  double velocityY = 0.0;
  double get moveSpeed => 220.0 * heroConfig.speedMultiplier;
  static const double jumpForce = -430.0;
  static const double gravity = 980.0;

  bool isOnGround = true;
  double groundY = 0.0;
  int facingDirection = 1; // 1 = Kanan (maju sisi game), -1 = Kiri

  // Crouch / Jongkok State
  bool isCrouching = false;

  // Run animation timer
  double runCycle = 0.0;
  bool isMoving = false;

  // Invincibility / Damage cooldown
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double hitInvincibleDuration = 1.6;

  // Hazmat Shield (Powerup)
  bool isShieldActive = false;
  double shieldTimer = 0.0;

  // Spread shot (Powerup)
  bool isSpreadShotActive = false;
  double spreadShotTimer = 0.0;

  // Hitbox
  RectangleHitbox? hitbox;

  PlayerDoctor({HeroConfig? heroConfig})
      : heroConfig = heroConfig ?? HeroConfig.heroes.first,
        super(size: Vector2(88, 140), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Hitbox presisi sesuai tubuh dokter (skala 1.85x)
    hitbox = RectangleHitbox(
      size: Vector2(64, 130),
      position: Vector2(12, 6),
    );
    add(hitbox!);
    _updateHitbox();
  }

  void setupGround(double y) {
    groundY = y;
    position.y = groundY;
    position.x = 50; // Mulai di sisi kiri layar dengan nyaman
    isOnGround = true;
    velocityY = 0.0;
    velocityX = 0.0;
    isMoving = false;
    isCrouching = false;
    runCycle = 0.0;
    _updateHitbox();
  }

  void moveLeft() {
    if (isCrouching) return;
    velocityX = -moveSpeed;
    facingDirection = 1; // Tetap membidik ke kanan (ke arah datangnya virus) saat melangkah mundur
    isMoving = true;
  }

  void moveRight() {
    if (isCrouching) return;
    velocityX = moveSpeed;
    facingDirection = 1;
    isMoving = true;
  }

  void stopMoving() {
    velocityX = 0.0;
    isMoving = false;
  }

  void crouch() {
    if (isOnGround) {
      isCrouching = true;
      velocityX = 0.0;
      isMoving = false;
      _updateHitbox();
    }
  }

  void standUp() {
    if (isCrouching) {
      isCrouching = false;
      _updateHitbox();
    }
  }

  void _updateHitbox() {
    if (hitbox == null) return;
    if (isCrouching) {
      // Saat jongkok skala 1.85x: tinggi hitbox berkurang drastis
      hitbox!.size = Vector2(70, 70);
      hitbox!.position = Vector2(9, 68);
    } else {
      hitbox!.size = Vector2(64, 130);
      hitbox!.position = Vector2(12, 6);
    }
  }

  void jump() {
    if (isCrouching) {
      standUp();
    }
    if (isOnGround) {
      velocityY = jumpForce;
      isOnGround = false;
    }
  }

  /// Memantul ke atas setelah menginjak kuman di darat (Mario Stomp!)
  void bounceAfterStomp() {
    velocityY = jumpForce * 0.65;
    isOnGround = false;
  }

  void takeDamage() {
    if (isInvincible || isShieldActive) return;
    isInvincible = true;
    invincibilityTimer = hitInvincibleDuration;
  }

  void activateShield(double duration) {
    isShieldActive = true;
    shieldTimer = duration;
  }

  void activateSpreadShot(double duration) {
    isSpreadShotActive = true;
    spreadShotTimer = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply movement
    position.x += velocityX * dt;

    // Apply gravity
    if (!isOnGround) {
      velocityY += gravity * dt;
      position.y += velocityY * dt;

      if (position.y >= groundY) {
        position.y = groundY;
        velocityY = 0;
        isOnGround = true;
      }
    }

    // Keep within world bounds (sesuai ukuran karakter 1.85x)
    if (position.x < 38) position.x = 38;
    final maxX = gameRef.size.x - 56;
    if (position.x > maxX) position.x = maxX;

    // Run animation cycle
    if (isMoving && isOnGround && !isCrouching) {
      if (velocityX < 0) {
        runCycle -= dt * 14; // Ayunan langkah kaki melangkah mundur (backstep)
      } else {
        runCycle += dt * 14; // Ayunan langkah kaki melangkah maju
      }
    } else if (!isOnGround) {
      runCycle = 1.4; // Pose melompat di udara
    } else {
      runCycle = 0.0; // Berdiri / Jongkok siap
    }

    // Invincibility timers
    if (isInvincible) {
      invincibilityTimer -= dt;
      if (invincibilityTimer <= 0) {
        isInvincible = false;
      }
    }

    if (isShieldActive) {
      shieldTimer -= dt;
      if (shieldTimer <= 0) {
        isShieldActive = false;
      }
    }

    if (isSpreadShotActive) {
      spreadShotTimer -= dt;
      if (spreadShotTimer <= 0) {
        isSpreadShotActive = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Efek berkedip saat kebal setelah terkena serangan
    if (isInvincible && !isShieldActive) {
      if ((invincibilityTimer * 10).floor() % 2 == 0) {
        return; // Flash off
      }
    }

    canvas.save();

    // PUSAT KOORDINAT: dasar telapak kaki dokter di tanah (0, 0)
    canvas.translate(size.x / 2, size.y);

    // Skala 1.85x agar proporsional dan gagah di latar belakang rumah sakit
    const double doctorScale = 1.85;
    canvas.scale(doctorScale * facingDirection, doctorScale);

    if (isCrouching) {
      _drawDoctorCrouchingProfile(canvas);
    } else {
      _drawDoctorSideProfile(canvas);
    }

    canvas.restore();
  }

  /// Menggambar karakter dokter dengan pose side-profile / 3/4 menghadap sisi game (ke depan arah jalan & tembakan)
  void _drawDoctorSideProfile(Canvas canvas) {
    final double legSwing = sin(runCycle) * 11;
    final double coatSwing = sin(runCycle - 0.4) * 10;

    // 0. Bayangan di tanah (hanya menempel di telapak saat di tanah)
    if (isOnGround) {
      final shadowPaint = Paint()..color = const Color(0x35000000);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(2, 0), width: 38, height: 7),
        shadowPaint,
      );
    }

    // Aura APD Shield (Emas Bercahaya) jika aktif
    if (isShieldActive) {
      final shieldPaint = Paint()
        ..color = const Color(0x77FFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final shieldGlow = Paint()
        ..color = const Color(0x25FFEA00)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(4, -38), 42, shieldGlow);
      canvas.drawCircle(const Offset(4, -38), 42, shieldPaint);
    }

    // 1. Kaki & Celana Sesuai Hero (Tampak Samping)
    final pantsPaint = Paint()..color = heroConfig.pantsColor;
    final shoesPaint = Paint()..color = heroConfig.shoesColor;

    // Kaki Kiri (Belakang)
    canvas.save();
    canvas.translate(-4, -20);
    canvas.rotate((-legSwing * pi / 180));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 8, 20), const Radius.circular(3)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 16, 11, 5), const Radius.circular(2)),
      shoesPaint,
    );
    canvas.restore();

    // Ekor Belakang Jas/Pakaian (Berkibar ke belakang saat lari, kecuali Scrub)
    if (!heroConfig.isScrubSuit) {
      final coatBackPaint = Paint()..color = heroConfig.coatShadeColor;
      final coatTail = Path();
      coatTail.moveTo(-8, -48);
      coatTail.lineTo(-14 - coatSwing, -16);
      coatTail.lineTo(-2, -18);
      coatTail.close();
      canvas.drawPath(coatTail, coatBackPaint);
    }

    // Kaki Kanan (Depan)
    canvas.save();
    canvas.translate(6, -20);
    canvas.rotate((legSwing * pi / 180));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 8, 20), const Radius.circular(3)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 16, 12, 5), const Radius.circular(2)),
      shoesPaint,
    );
    canvas.restore();

    // 2. Tubuh & Kemeja / Lapisan Dalam Sesuai Seragam
    final shirtPaint = Paint()..color = heroConfig.shirtColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -52, 16, 32), const Radius.circular(4)),
      shirtPaint,
    );

    // Aksen Dada Khas Seragam Masing-Masing Hero
    _drawSideChestAccessory(canvas, -48);

    // 3. Jas / Scrub / Apron Pakaian Hero (Detail Berdimensi Sesuai Hero)
    final coatPaint = Paint()..color = heroConfig.coatColor;
    final coatBorder = Paint()
      ..color = heroConfig.coatBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final coatRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-9, -52, 21, 34),
      const Radius.circular(4),
    );
    canvas.drawRRect(coatRect, coatPaint);

    // Bayangan Lipatan Samping Pakaian
    final coatShadePaint = Paint()..color = heroConfig.coatShadeColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -52, 6, 34), const Radius.circular(3)),
      coatShadePaint,
    );
    canvas.drawRRect(coatRect, coatBorder);

    // Belahan & Kancing (Hanya jika berbelahan/jas)
    if (!heroConfig.isScrubSuit) {
      final placketPaint = Paint()
        ..color = heroConfig.coatBorderColor
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(3, -50), const Offset(3, -19), placketPaint);

      // Kancing Jas Mutiara
      final buttonFill = Paint()..color = Colors.white;
      final buttonRing = Paint()
        ..color = heroConfig.coatBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      for (final btnY in [-38.0, -30.0, -22.0]) {
        canvas.drawCircle(Offset(3, btnY), 1.6, buttonFill);
        canvas.drawCircle(Offset(3, btnY), 1.6, buttonRing);
      }

      // Kerah Lapel Jas
      final lapelPaint = Paint()..color = heroConfig.coatShadeColor;
      final lapelStroke = Paint()
        ..color = heroConfig.coatBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      final lapelPath = Path();
      lapelPath.moveTo(-1, -52);
      lapelPath.lineTo(8, -44);
      lapelPath.lineTo(4, -33);
      lapelPath.lineTo(1, -40);
      lapelPath.close();
      canvas.drawPath(lapelPath, lapelPaint);
      canvas.drawPath(lapelPath, lapelStroke);
    }

    // Kantong Saku Dada Kiri (Breast Pocket)
    final pocketRect = const Rect.fromLTWH(-3, -45, 6.5, 7.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pocketRect, const Radius.circular(1.5)),
      Paint()..color = heroConfig.coatShadeColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pocketRect, const Radius.circular(1.5)),
      Paint()
        ..color = heroConfig.coatBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 2 Pena Medis di Saku Dada
    canvas.drawLine(const Offset(-1.5, -47.5), const Offset(-1.5, -43), Paint()..color = const Color(0xFFEF4444)..strokeWidth = 1.3);
    canvas.drawCircle(const Offset(-1.5, -47.5), 0.8, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawLine(const Offset(1, -47.5), const Offset(1, -43), Paint()..color = heroConfig.primaryColor..strokeWidth = 1.3);
    canvas.drawCircle(const Offset(1, -47.5), 0.8, Paint()..color = const Color(0xFF94A3B8));

    // Kartu ID Card Badge RSIA (Gantung di Dada)
    final badgeLanyard = Paint()..color = heroConfig.primaryColor..strokeWidth = 1.0;
    canvas.drawLine(const Offset(2.5, -43), const Offset(2.5, -39), badgeLanyard);
    final badgeRect = RRect.fromRectAndRadius(const Rect.fromLTWH(0.5, -39, 4.5, 6), const Radius.circular(1));
    canvas.drawRRect(badgeRect, Paint()..color = Colors.white);
    canvas.drawRRect(badgeRect, Paint()..color = heroConfig.primaryColor..style = PaintingStyle.stroke..strokeWidth = 0.6);
    canvas.drawRect(const Rect.fromLTWH(1, -38.5, 3.5, 1.2), Paint()..color = heroConfig.primaryColor);

    // Kantong Samping di Pinggang
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -26, 7, 5), const Radius.circular(1)),
      Paint()..color = heroConfig.coatShadeColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -26, 7, 5), const Radius.circular(1)),
      Paint()..color = heroConfig.coatBorderColor..style = PaintingStyle.stroke..strokeWidth = 0.9,
    );

    // ── STETOSKOP MEDIS (Khusus Profesi yang Menggunakan Stetoskop) ──
    if (heroConfig.hasStethoscope) {
      final stethoColor = heroConfig.profession == HeroProfession.perawat
          ? const Color(0xFF0F766E)
          : const Color(0xFF0F172A);
      final stethoTubeOuter = Paint()
        ..color = stethoColor
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final stethoTubeInner = Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final stethoPath = Path();
      stethoPath.moveTo(-3, -54);
      stethoPath.quadraticBezierTo(-6, -46, 0, -42);
      stethoPath.lineTo(5, -42);
      canvas.drawPath(stethoPath, stethoTubeOuter);
      canvas.drawPath(stethoPath, stethoTubeInner);

      // Chestpiece / Diafragma Perak Mengkilap di Dada
      canvas.drawRect(const Rect.fromLTWH(4.5, -43.5, 2.5, 3), Paint()..color = const Color(0xFF64748B));
      final chestpieceOffset = const Offset(8, -42);
      canvas.drawCircle(chestpieceOffset, 4.2, Paint()..color = const Color(0xFF334155));
      canvas.drawCircle(chestpieceOffset, 3.5, Paint()..color = const Color(0xFFE2E8F0));
      canvas.drawCircle(chestpieceOffset, 1.8, Paint()..color = Colors.white);
    }

    // 4. Leher & Kepala Tampak Samping
    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    canvas.drawRect(const Rect.fromLTWH(-2, -56, 8, 5), skinPaint);

    final headRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-8, -71, 18, 16),
      const Radius.circular(5),
    );
    canvas.drawRRect(headRect, skinPaint);

    // Hidung Mancung Kecil
    final nosePath = Path();
    nosePath.moveTo(10, -64);
    nosePath.lineTo(13.5, -62);
    nosePath.lineTo(10, -60);
    nosePath.close();
    canvas.drawPath(nosePath, skinPaint);

    // Rambut / Jilbab Sesuai Seragam Hero
    if (heroConfig.hasHeadCover) {
      // JILBAB / KERUDUNG BERGO: Membungkus seluruh batok kepala & leher dengan rapi
      final hijabPaint = Paint()..color = heroConfig.effectiveHeadCoverColor;
      final hijabBorder = Paint()
        ..color = heroConfig.effectiveHeadCoverBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;

      final hijabPath = Path();
      hijabPath.moveTo(-10.5, -50); // pundak belakang
      hijabPath.lineTo(-10.5, -72); // belakang kepala
      hijabPath.quadraticBezierTo(0, -78, 10.5, -72.5); // puncak kubah kepala menutupi dahi depan penuh
      hijabPath.lineTo(8.5, -68.5); // dahi depan
      hijabPath.quadraticBezierTo(1.5, -64, 5.5, -55); // lekukan bukaan wajah samping di belakang mata & bawah dagu
      hijabPath.quadraticBezierTo(7.5, -50.5, 8.5, -47.5); // juntaian ke dada depan
      hijabPath.quadraticBezierTo(0, -45.5, -10.5, -50); // drapery bawah kerudung
      hijabPath.close();

      canvas.drawPath(hijabPath, hijabPaint);
      canvas.drawPath(hijabPath, hijabBorder);

      // Lis Inner Ciput di Dahi Depan
      final trimPaint = Paint()
        ..color = heroConfig.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawLine(const Offset(8.5, -68.5), const Offset(10.5, -72.5), trimPaint);

      // Bros Kebidanan Emas di Dada Depan (Hanya untuk Bidan)
      if (heroConfig.profession == HeroProfession.bidan) {
        final broochCenter = const Offset(7.5, -49);
        canvas.drawCircle(broochCenter, 2.4, Paint()..color = const Color(0xFFF59E0B));
        canvas.drawCircle(broochCenter, 1.2, Paint()..color = const Color(0xFFBE185D));
      }
    } else {
      // Rambut Hitam Rapi Belah Samping
      final hairPaint = Paint()..color = heroConfig.hairColor;
      final hairPath = Path();
      hairPath.moveTo(-9, -67);
      hairPath.lineTo(-9, -74);
      hairPath.quadraticBezierTo(2, -77, 11, -73);
      hairPath.lineTo(11, -67);
      hairPath.lineTo(8, -69);
      hairPath.quadraticBezierTo(0, -71, -7, -68);
      hairPath.close();
      canvas.drawPath(hairPath, hairPaint);
    }

    // 5. MATA & KACAMATA (Jika Hero Memakai Kacamata)
    final eyeWhite = Paint()..color = Colors.white;
    final eyePupil = Paint()..color = const Color(0xFF0F172A);
    canvas.drawOval(Rect.fromCenter(center: const Offset(4, -64.5), width: 5.5, height: 4), eyeWhite);
    canvas.drawCircle(const Offset(5, -64.5), 1.6, eyePupil);
    canvas.drawCircle(const Offset(5.5, -65), 0.6, Paint()..color = Colors.white);

    if (heroConfig.hasGlasses) {
      final clearFramePaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      final clearFrameOuter = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      final lensRect = const Rect.fromLTWH(0, -68, 11, 7.5);
      final lensRRect = RRect.fromRectAndRadius(lensRect, const Radius.circular(2.0));
      canvas.drawRRect(lensRRect, Paint()..color = const Color(0x33E0F2FE));
      canvas.drawRRect(lensRRect, clearFramePaint);
      canvas.drawRRect(lensRRect, clearFrameOuter);
      canvas.drawLine(const Offset(0, -65), const Offset(-7, -65), clearFramePaint);

      final glassShine = Paint()
        ..color = const Color(0x99FFFFFF)
        ..strokeWidth = 1.0;
      canvas.drawLine(const Offset(3, -67), const Offset(7, -62), glassShine);
    }

    final smilePaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      const Rect.fromLTWH(4, -60, 6, 3),
      0,
      pi * 0.8,
      false,
      smilePaint,
    );

    // 6. Tangan & Syringe Blaster (Dipegang Menghadap Sisi Game)
    _drawSyringeBlasterSide(canvas, -36);
  }

  void _drawSideChestAccessory(Canvas canvas, double y) {
    if (heroConfig.hasTie) {
      final tiePaint = Paint()..color = heroConfig.accentColor;
      final tiePath = Path();
      tiePath.moveTo(3, y);
      tiePath.lineTo(6, y + 10);
      tiePath.lineTo(4, y + 18);
      tiePath.lineTo(1, y + 10);
      tiePath.close();
      canvas.drawPath(tiePath, tiePaint);
    } else if (heroConfig.hasLeadApron) {
      // Simbol Trefoil Radiasi Emas-Kuning di Dada Lead Apron
      final emblemPaint = Paint()..color = const Color(0xFFFACC15);
      final center = Offset(4, y + 10);
      canvas.drawCircle(center, 2.5, emblemPaint);
      canvas.drawCircle(center, 1.0, Paint()..color = const Color(0xFF1E293B));
      for (int i = 0; i < 3; i++) {
        final angle = (i * 120 - 90) * pi / 180;
        final wingX = center.dx + cos(angle) * 4.2;
        final wingY = center.dy + sin(angle) * 4.2;
        canvas.drawCircle(Offset(wingX, wingY), 1.6, emblemPaint);
      }
    } else if (heroConfig.profession == HeroProfession.bidan) {
      // Lencana Bidan Delima Emas di Dada
      final broochPaint = Paint()..color = const Color(0xFFF59E0B);
      final center = Offset(4, y + 10);
      canvas.drawCircle(center, 3.2, broochPaint);
      canvas.drawCircle(center, 1.8, Paint()..color = const Color(0xFFBE185D));
    } else if (heroConfig.profession == HeroProfession.gizi) {
      // Pin Apel Sehat Merah dengan Daun Hijau
      final applePaint = Paint()..color = const Color(0xFFEF4444);
      final center = Offset(4, y + 10);
      canvas.drawCircle(center, 3.0, applePaint);
      canvas.drawCircle(Offset(center.dx + 1.2, center.dy - 3.2), 1.2, Paint()..color = const Color(0xFF10B981));
    } else if (heroConfig.profession == HeroProfession.farmasi) {
      // Pin Mortar & Pestle Farmasi Emas
      final mortarPaint = Paint()..color = const Color(0xFFF59E0B);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(2, y + 8, 5, 4), const Radius.circular(1.5)),
        mortarPaint,
      );
      canvas.drawLine(Offset(3, y + 7), Offset(6, y + 11), Paint()..color = Colors.white..strokeWidth = 1.0);
    } else if (heroConfig.isScrubSuit) {
      // V-neck lis toska scrub
      final vneckPaint = Paint()
        ..color = heroConfig.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final vPath = Path();
      vPath.moveTo(0, y);
      vPath.lineTo(4, y + 8);
      vPath.lineTo(7, y);
      canvas.drawPath(vPath, vneckPaint);
    }
  }

  /// Pose Jongkok (Ducking / Crouch Pose)
  void _drawDoctorCrouchingProfile(Canvas canvas) {
    // 0. Bayangan lebar di tanah saat berjongkok
    if (isOnGround) {
      final shadowPaint = Paint()..color = const Color(0x35000000);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(4, 0), width: 44, height: 7),
        shadowPaint,
      );
    }

    // Aura APD Shield (Emas Bercahaya) jika aktif - melingkupi tubuh jongkok
    if (isShieldActive) {
      final shieldPaint = Paint()
        ..color = const Color(0x77FFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final shieldGlow = Paint()
        ..color = const Color(0x25FFEA00)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(4, -22), 34, shieldGlow);
      canvas.drawCircle(const Offset(4, -22), 34, shieldPaint);
    }

    // 1. Kaki Celana Sesuai Hero Posisi Jongkok
    final pantsPaint = Paint()..color = heroConfig.pantsColor;
    final shoesPaint = Paint()..color = heroConfig.shoesColor;

    // Kaki Belakang (ditekuk rendah)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -16, 14, 9), const Radius.circular(3)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -7, 13, 7), const Radius.circular(2)),
      shoesPaint,
    );

    // Ekor Belakang Jas/Pakaian (Terlipat di belakang saat jongkok, kecuali Scrub)
    if (!heroConfig.isScrubSuit) {
      final coatBackPaint = Paint()..color = heroConfig.coatShadeColor;
      final coatTail = Path();
      coatTail.moveTo(-8, -32);
      coatTail.lineTo(-17, -8);
      coatTail.lineTo(-4, -8);
      coatTail.close();
      canvas.drawPath(coatTail, coatBackPaint);
    }

    // Kaki Depan (lutut maju ke depan)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, -18, 16, 10), const Radius.circular(4)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(6, -11, 10, 11), const Radius.circular(3)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(4, -7, 15, 7), const Radius.circular(2)),
      shoesPaint,
    );

    // 2. Tubuh & Kemeja / Lapisan Dalam (Diturunkan posisi jongkok)
    final shirtPaint = Paint()..color = heroConfig.shirtColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -36, 16, 22), const Radius.circular(4)),
      shirtPaint,
    );

    // Aksen Dada Khas Seragam Masing-Masing Hero
    _drawSideChestAccessory(canvas, -33);

    // 3. Jas / Scrub / Apron Posisi Jongkok (Detail Berdimensi Sesuai Hero)
    final coatPaint = Paint()..color = heroConfig.coatColor;
    final coatBorder = Paint()
      ..color = heroConfig.coatBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final coatRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-9, -36, 21, 24),
      const Radius.circular(4),
    );
    canvas.drawRRect(coatRect, coatPaint);

    // Shading Samping Jas/Baju
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -36, 6, 24), const Radius.circular(3)),
      Paint()..color = heroConfig.coatShadeColor,
    );
    canvas.drawRRect(coatRect, coatBorder);

    // Garis Tengah & Kancing (Kecuali Scrub)
    if (!heroConfig.isScrubSuit) {
      canvas.drawLine(const Offset(3, -34), const Offset(3, -13), Paint()..color = heroConfig.coatBorderColor..strokeWidth = 1.2);
      for (final btnY in [-27.0, -19.0]) {
        canvas.drawCircle(Offset(3, btnY), 1.5, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(3, btnY), 1.5, Paint()..color = heroConfig.coatBorderColor..style = PaintingStyle.stroke..strokeWidth = 0.8);
      }

      // Kerah Lapel Jas Jongkok
      final lapelPaint = Paint()..color = heroConfig.coatShadeColor;
      final lapelStroke = Paint()
        ..color = heroConfig.coatBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      final lapelPath = Path();
      lapelPath.moveTo(-1, -36);
      lapelPath.lineTo(8, -29);
      lapelPath.lineTo(4, -19);
      lapelPath.lineTo(1, -25);
      lapelPath.close();
      canvas.drawPath(lapelPath, lapelPaint);
      canvas.drawPath(lapelPath, lapelStroke);
    }

    // Saku Dada di Posisi Jongkok
    final pocketRect = const Rect.fromLTWH(-3, -31, 6, 6.5);
    canvas.drawRRect(RRect.fromRectAndRadius(pocketRect, const Radius.circular(1)), Paint()..color = heroConfig.coatShadeColor);
    canvas.drawRRect(RRect.fromRectAndRadius(pocketRect, const Radius.circular(1)), Paint()..color = heroConfig.coatBorderColor..style = PaintingStyle.stroke..strokeWidth = 0.9);
    canvas.drawLine(const Offset(-1.5, -33), const Offset(-1.5, -29), Paint()..color = const Color(0xFFEF4444)..strokeWidth = 1.2);
    canvas.drawLine(const Offset(1, -33), const Offset(1, -29), Paint()..color = heroConfig.primaryColor..strokeWidth = 1.2);

    // Stetoskop Medis di Pundak Jongkok (Khusus Profesi Tertentu)
    if (heroConfig.hasStethoscope) {
      final stethoColor = heroConfig.profession == HeroProfession.perawat
          ? const Color(0xFF0F766E)
          : const Color(0xFF0F172A);
      final stethoTubeOuter = Paint()
        ..color = stethoColor
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final stethoTubeInner = Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final stethoPath = Path();
      stethoPath.moveTo(-3, -38);
      stethoPath.quadraticBezierTo(-6, -30, 1, -27);
      stethoPath.lineTo(5, -27);
      canvas.drawPath(stethoPath, stethoTubeOuter);
      canvas.drawPath(stethoPath, stethoTubeInner);

      // Diafragma Perak Mengkilap di Dada Jongkok
      canvas.drawRect(const Rect.fromLTWH(4.5, -28.5, 2.5, 3), Paint()..color = const Color(0xFF64748B));
      final chestpieceOffset = const Offset(8, -27);
      canvas.drawCircle(chestpieceOffset, 3.8, Paint()..color = const Color(0xFF334155));
      canvas.drawCircle(chestpieceOffset, 3.2, Paint()..color = const Color(0xFFE2E8F0));
      canvas.drawCircle(chestpieceOffset, 1.6, Paint()..color = Colors.white);
    }

    // 4. Leher & Kepala (Posisi Rendah Membidik)
    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    canvas.drawRect(const Rect.fromLTWH(-2, -40, 8, 5), skinPaint);

    final headRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-8, -55, 18, 16),
      const Radius.circular(5),
    );
    canvas.drawRRect(headRect, skinPaint);

    // Hidung
    final nosePath = Path();
    nosePath.moveTo(10, -48);
    nosePath.lineTo(13.5, -46);
    nosePath.lineTo(10, -44);
    nosePath.close();
    canvas.drawPath(nosePath, skinPaint);

    // Rambut / Jilbab Sesuai Seragam Hero di Posisi Jongkok
    if (heroConfig.hasHeadCover) {
      // JILBAB / KERUDUNG BERGO DI POSISI JONGKOK (Membungkus batok kepala penuh)
      final hijabPaint = Paint()..color = heroConfig.effectiveHeadCoverColor;
      final hijabBorder = Paint()
        ..color = heroConfig.effectiveHeadCoverBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;

      final hijabPath = Path();
      hijabPath.moveTo(-10.5, -34); // pundak belakang
      hijabPath.lineTo(-10.5, -56); // belakang kepala
      hijabPath.quadraticBezierTo(0, -62, 10.5, -56.5); // puncak kubah kepala menutupi dahi depan penuh
      hijabPath.lineTo(8.5, -52.5); // dahi depan
      hijabPath.quadraticBezierTo(1.5, -48, 5.5, -39); // lekukan bukaan wajah samping di belakang mata & bawah dagu
      hijabPath.quadraticBezierTo(7.5, -34.5, 8.5, -31.5); // juntaian ke dada depan
      hijabPath.quadraticBezierTo(0, -29.5, -10.5, -34); // drapery bawah kerudung
      hijabPath.close();

      canvas.drawPath(hijabPath, hijabPaint);
      canvas.drawPath(hijabPath, hijabBorder);

      // Lis Inner Ciput di Dahi Depan
      final trimPaint = Paint()
        ..color = heroConfig.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawLine(const Offset(8.5, -52.5), const Offset(10.5, -56.5), trimPaint);

      // Bros Kebidanan Emas di Dada Depan (Hanya untuk Bidan)
      if (heroConfig.profession == HeroProfession.bidan) {
        final broochCenter = const Offset(7.5, -33);
        canvas.drawCircle(broochCenter, 2.4, Paint()..color = const Color(0xFFF59E0B));
        canvas.drawCircle(broochCenter, 1.2, Paint()..color = const Color(0xFFBE185D));
      }
    } else {
      final hairPaint = Paint()..color = heroConfig.hairColor;
      final hairPath = Path();
      hairPath.moveTo(-9, -51);
      hairPath.lineTo(-9, -58);
      hairPath.quadraticBezierTo(2, -61, 11, -57);
      hairPath.lineTo(11, -51);
      hairPath.lineTo(8, -53);
      hairPath.quadraticBezierTo(0, -55, -7, -52);
      hairPath.close();
      canvas.drawPath(hairPath, hairPaint);
    }

    // Mata Membidik Tajam
    final eyeWhite = Paint()..color = Colors.white;
    final eyePupil = Paint()..color = const Color(0xFF0F172A);
    canvas.drawOval(Rect.fromCenter(center: const Offset(4, -48.5), width: 5.5, height: 4), eyeWhite);
    canvas.drawCircle(const Offset(5, -48.5), 1.6, eyePupil);
    canvas.drawCircle(const Offset(5.5, -49), 0.6, Paint()..color = Colors.white);

    // Kacamata (Jika Hero Memakai Kacamata)
    if (heroConfig.hasGlasses) {
      final clearFramePaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      final clearFrameOuter = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      final lensRect = const Rect.fromLTWH(0, -52, 11, 7.5);
      final lensRRect = RRect.fromRectAndRadius(lensRect, const Radius.circular(2.0));
      canvas.drawRRect(lensRRect, Paint()..color = const Color(0x33E0F2FE));
      canvas.drawRRect(lensRRect, clearFramePaint);
      canvas.drawRRect(lensRRect, clearFrameOuter);
      canvas.drawLine(const Offset(0, -49), const Offset(-7, -49), clearFramePaint);

      final glassShine = Paint()
        ..color = const Color(0x99FFFFFF)
        ..strokeWidth = 1.0;
      canvas.drawLine(const Offset(3, -51), const Offset(7, -46), glassShine);
    }

    // Mulut Fokus / Serius
    final mouthPaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(4, -44), const Offset(9, -44), mouthPaint);

    // 5. Tangan & Syringe Blaster Rendah
    _drawSyringeBlasterSide(canvas, -17.5);
  }

  void _drawSyringeBlasterSide(Canvas canvas, double gunCenterY) {
    canvas.save();
    canvas.translate(10, gunCenterY);

    // 1. LENGAN ATAS PAKAIAN HERO (Upper Arm Sesuai Seragam)
    final armPath = Path();
    armPath.moveTo(-11, -11); // Bahu hero
    armPath.lineTo(-2, -4);   // Depan bahu
    armPath.lineTo(1, 4);     // Siku
    armPath.lineTo(-7, 7);    // Belakang siku
    armPath.close();
    canvas.drawPath(armPath, Paint()..color = heroConfig.coatColor);
    canvas.drawPath(
      armPath,
      Paint()
        ..color = heroConfig.coatBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // 2. LENGAN BAWAH & MANSET (Forearm & Cuff)
    final forearmRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-5, -3.5, 11, 8.5),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(forearmRect, Paint()..color = heroConfig.coatColor);
    canvas.drawRRect(
      forearmRect,
      Paint()
        ..color = heroConfig.coatBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    // Garis lipatan manset
    canvas.drawLine(
      const Offset(5, -3),
      const Offset(5, 5),
      Paint()
        ..color = heroConfig.coatBorderColor
        ..strokeWidth = 1.2,
    );

    // 3. SARUNG TANGAN MEDIS STERIL SESUAI WARNA HERO
    final gloveColor = heroConfig.gloveColor;
    final gloveShade = heroConfig.gloveShadeColor;
    final gloveHighlight = Color.lerp(heroConfig.gloveColor, Colors.white, 0.45)!;

    // Cincin elastis manset sarung tangan di pergelangan
    final gloveCuff = RRect.fromRectAndRadius(
      const Rect.fromLTWH(5, -2.5, 3.2, 7.5),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(gloveCuff, Paint()..color = gloveColor);
    canvas.drawRRect(gloveCuff, Paint()..color = gloveShade..style = PaintingStyle.stroke..strokeWidth = 0.8);

    // 4. GAGANG PISTOL BLASTER
    final gripPaint = Paint()..color = heroConfig.primaryColor;
    final gripBorder = Paint()
      ..color = heroConfig.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final gripPath = Path();
    gripPath.moveTo(7, 3);
    gripPath.lineTo(12, 3);
    gripPath.lineTo(10, 14);
    gripPath.lineTo(5, 14);
    gripPath.close();
    canvas.drawPath(gripPath, gripPaint);
    canvas.drawPath(gripPath, gripBorder);

    // Pelindung Pelatuk & Pelatuk
    final triggerGuard = Path();
    triggerGuard.moveTo(11, 4);
    triggerGuard.lineTo(15, 6);
    triggerGuard.lineTo(13, 10);
    triggerGuard.lineTo(9, 10);
    canvas.drawPath(
      triggerGuard,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      const Offset(11, 6),
      const Offset(10, 8.5),
      Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1.2,
    );

    // 5. TELAPAK TANGAN & JARI MENGGENGGAM GAGANG
    // Ibu jari mengunci di atas gagang
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(6, -2, 4.2, 3.8), const Radius.circular(1.5)),
      Paint()..color = gloveColor,
    );
    // Jari telunjuk di pelatuk
    final indexFinger = Path();
    indexFinger.moveTo(8, 5);
    indexFinger.lineTo(12.5, 6);
    indexFinger.lineTo(11.5, 8.2);
    indexFinger.lineTo(8, 7.8);
    indexFinger.close();
    canvas.drawPath(indexFinger, Paint()..color = gloveHighlight);
    canvas.drawPath(indexFinger, Paint()..color = gloveShade..style = PaintingStyle.stroke..strokeWidth = 0.6);

    // 3 Jari memeluk gagang
    for (int i = 0; i < 3; i++) {
      final fy = 8.0 + (i * 2.3);
      final fingerRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(6.5, fy, 4.8, 2.1),
        const Radius.circular(1.0),
      );
      canvas.drawRRect(fingerRect, Paint()..color = gloveColor);
      canvas.drawRRect(fingerRect, Paint()..color = gloveShade..style = PaintingStyle.stroke..strokeWidth = 0.5);
    }

    // 6. TANGAN KIRI MENOPANG TABUNG
    final leftHandCuff = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 5, 6.5, 4.5),
      const Radius.circular(2),
    );
    canvas.drawRRect(leftHandCuff, Paint()..color = gloveShade);
    final leftFingers = RRect.fromRectAndRadius(
      const Rect.fromLTWH(15, 2.5, 5.5, 3.2),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(leftFingers, Paint()..color = gloveHighlight);
    canvas.drawRRect(leftFingers, Paint()..color = gloveShade..style = PaintingStyle.stroke..strokeWidth = 0.6);

    // 7. TABUNG MEDIS BLASTER SESUAI ENERGI HERO
    final fluidColor = isSpreadShotActive ? const Color(0xFFFF9100) : heroConfig.bulletColor;
    const tubeRect = Rect.fromLTWH(7, -5, 17, 9);
    final tubeRRect = RRect.fromRectAndRadius(tubeRect, const Radius.circular(2.5));

    // Kaca Transparan & Rim Logam
    canvas.drawRRect(tubeRRect, Paint()..color = const Color(0x33FFFFFF));
    canvas.drawRRect(
      tubeRRect,
      Paint()
        ..color = heroConfig.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // Cairan Antiseptik/Reagen/Vitamin Berpendar
    final fluidRect = const Rect.fromLTWH(9, -3.2, 13, 5.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fluidRect, const Radius.circular(1.5)),
      Paint()..color = fluidColor,
    );
    canvas.drawLine(
      const Offset(10, -2),
      const Offset(20, -2),
      Paint()..color = Colors.white.withValues(alpha: 0.75)..strokeWidth = 1.0,
    );

    // Skala Garis Mililiter Medis
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 0.8;
    for (int t = 0; t < 4; t++) {
      final tx = 11.0 + (t * 2.8);
      canvas.drawLine(Offset(tx, 0.5), Offset(tx, 2.5), tickPaint);
    }

    // 8. PISTON PLUNGER
    canvas.drawLine(
      const Offset(2, -0.5),
      const Offset(7, -0.5),
      Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 2.0,
    );
    final plungerEnd = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, -3.5, 2.5, 6),
      const Radius.circular(1),
    );
    canvas.drawRRect(plungerEnd, Paint()..color = heroConfig.primaryColor);
    canvas.drawCircle(
      const Offset(-1.5, -0.5),
      2.5,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 9. MONCONG & JARUM SUNTIK / NOZZLE
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(24, -2.5, 4, 4), const Radius.circular(1)),
      Paint()..color = heroConfig.primaryColor,
    );
    final needlePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.8;
    canvas.drawLine(const Offset(28, -0.5), const Offset(37, -0.5), needlePaint);

    // Pendaran Energi di Ujung Jarum/Nozzle
    final glowPaint = Paint()..color = fluidColor.withValues(alpha: 0.75);
    canvas.drawCircle(const Offset(37, -0.5), 3.5, glowPaint);
    canvas.drawCircle(const Offset(37, -0.5), 1.5, Paint()..color = Colors.white);

    canvas.restore();
  }

  /// Titik keluarnya peluru tembakan presisi dari ujung jarum suntik (skala 1.85x)
  Vector2 get muzzlePosition {
    final offsetX = facingDirection == 1 ? 86.0 : -86.0;
    final offsetY = isCrouching ? 32.0 : 66.0;
    return Vector2(position.x + offsetX, position.y - offsetY);
  }
}
