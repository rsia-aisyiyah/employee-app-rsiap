import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerDoctor extends PositionComponent with HasGameRef, CollisionCallbacks {
  // Movement & Physics
  double velocityX = 0.0;
  double velocityY = 0.0;
  static const double moveSpeed = 220.0;
  static const double jumpForce = -430.0;
  static const double gravity = 980.0;

  bool isOnGround = true;
  double groundY = 0.0;
  int facingDirection = 1; // 1 = Kanan (maju sisi game), -1 = Kiri

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
  late RectangleHitbox hitbox;

  PlayerDoctor() : super(size: Vector2(48, 76), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Hitbox presisi sesuai tubuh dokter
    hitbox = RectangleHitbox(
      size: Vector2(34, 72),
      position: Vector2(7, 2),
    );
    add(hitbox);
  }

  void setupGround(double y) {
    groundY = y;
    position.y = groundY;
    position.x = 42; // Mulai di sisi kiri layar
    isOnGround = true;
    velocityY = 0;
  }

  void moveLeft() {
    velocityX = -moveSpeed;
    facingDirection = -1;
    isMoving = true;
  }

  void moveRight() {
    velocityX = moveSpeed;
    facingDirection = 1;
    isMoving = true;
  }

  void stopMoving() {
    velocityX = 0.0;
    isMoving = false;
  }

  void jump() {
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

    // Keep within world bounds
    if (position.x < 28) position.x = 28;
    final maxX = gameRef.size.x - 36;
    if (position.x > maxX) position.x = maxX;

    // Run animation cycle
    if (isMoving && isOnGround) {
      runCycle += dt * 14;
    } else if (!isOnGround) {
      runCycle = 1.4; // Pose melompat di udara
    } else {
      runCycle = 0.0; // Berdiri siap
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

    // Flip hadap kiri / kanan tepat di poros tengah tubuh dokter
    if (facingDirection == -1) {
      canvas.scale(-1, 1);
    }

    _drawDoctorSideProfile(canvas);

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

    // 1. Kaki & Celana Biru Tua Formal (Tampak Samping)
    final pantsPaint = Paint()..color = const Color(0xFF1E293B);
    final shoesPaint = Paint()..color = const Color(0xFF0F172A);

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

    // Ekor Belakang Jas Snelli Putih (Berkibar ke belakang saat lari)
    final coatBackPaint = Paint()..color = const Color(0xFFE2E8F0);
    final coatTail = Path();
    coatTail.moveTo(-8, -48);
    coatTail.lineTo(-14 - coatSwing, -16);
    coatTail.lineTo(-2, -18);
    coatTail.close();
    canvas.drawPath(coatTail, coatBackPaint);

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

    // 2. Tubuh & Kemeja Biru Muda Tampak Samping
    final shirtPaint = Paint()..color = const Color(0xFF38BDF8); // Kemeja biru muda
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -52, 16, 32), const Radius.circular(4)),
      shirtPaint,
    );

    // Dasi Biru Tua RSIA (Menjuntai di dada depan)
    final tiePaint = Paint()..color = const Color(0xFF0284C7);
    final tiePath = Path();
    tiePath.moveTo(3, -48);
    tiePath.lineTo(6, -38);
    tiePath.lineTo(4, -30);
    tiePath.lineTo(1, -38);
    tiePath.close();
    canvas.drawPath(tiePath, tiePaint);

    // 3. Jas Snelli Putih Tampak Tiga Perempat Samping
    final coatPaint = Paint()..color = const Color(0xFFFFFFFF);
    final coatBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final coatRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-9, -52, 20, 33),
      const Radius.circular(4),
    );
    canvas.drawRRect(coatRect, coatPaint);
    canvas.drawRRect(coatRect, coatBorder);

    // Kerah Lapel Jas Dokter Tampak Samping
    final lapelPaint = Paint()..color = const Color(0xFFF1F5F9);
    final lapelPath = Path();
    lapelPath.moveTo(-2, -52);
    lapelPath.lineTo(7, -44);
    lapelPath.lineTo(3, -34);
    lapelPath.lineTo(0, -42);
    lapelPath.close();
    canvas.drawPath(lapelPath, lapelPaint);

    // Kantong Jas Snelli Samping
    canvas.drawRect(const Rect.fromLTWH(-3, -33, 7, 4), Paint()..color = const Color(0xFFE2E8F0));

    // Stetoskop di Pundak
    final stethoPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawArc(const Rect.fromLTWH(-4, -53, 10, 14), 0, pi, false, stethoPaint);
    canvas.drawCircle(const Offset(5, -42), 2.2, Paint()..color = const Color(0xFFCBD5E1));

    // 4. Leher & Kepala Tampak Samping (Menghadap Kanan / Sisi Game)
    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    canvas.drawRect(const Rect.fromLTWH(-2, -56, 8, 5), skinPaint);

    // Kepala Profil Samping
    final headRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-8, -71, 18, 16),
      const Radius.circular(5),
    );
    canvas.drawRRect(headRect, skinPaint);

    // Hidung Mancung Kecil Menghadap Kanan (Sisi Game)
    final nosePath = Path();
    nosePath.moveTo(10, -64);
    nosePath.lineTo(13.5, -62);
    nosePath.lineTo(10, -60);
    nosePath.close();
    canvas.drawPath(nosePath, skinPaint);

    // Rambut Hitam Rapi Belah Samping (Tampak Samping)
    final hairPaint = Paint()..color = const Color(0xFF0F172A);
    final hairPath = Path();
    hairPath.moveTo(-9, -67);
    hairPath.lineTo(-9, -74);
    hairPath.quadraticBezierTo(2, -77, 11, -73);
    hairPath.lineTo(11, -67);
    hairPath.lineTo(8, -69);
    hairPath.quadraticBezierTo(0, -71, -7, -68);
    hairPath.close();
    canvas.drawPath(hairPath, hairPaint);

    // 5. MATA DOKTER RAMAH & KACAMATA PUTIH/BENING SESUAI REFERENSI ASLI
    // Mata dokter menatap ke depan sisi game
    final eyeWhite = Paint()..color = Colors.white;
    final eyePupil = Paint()..color = const Color(0xFF0F172A);
    canvas.drawOval(Rect.fromCenter(center: const Offset(4, -64.5), width: 5.5, height: 4), eyeWhite);
    canvas.drawCircle(const Offset(5, -64.5), 1.6, eyePupil);
    canvas.drawCircle(const Offset(5.5, -65), 0.6, Paint()..color = Colors.white); // Kilau mata

    // KACAMATA BINGKAI PUTIH / BENING TRANSPARAN (CLEAR FRAMES) SESUAI FOTO DOKTER ASLI
    final clearFramePaint = Paint()
      ..color = const Color(0xFFFFFFFF) // Frame Putih Bersih
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final clearFrameOuter = Paint()
      ..color = const Color(0xFFCBD5E1) // Aksen border halus
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Lensa Persegi Bening dengan Pantulan Kaca Transparan
    final lensRect = Rect.fromLTWH(0, -68, 11, 7.5);
    final lensRRect = RRect.fromRectAndRadius(lensRect, const Radius.circular(2.0));
    canvas.drawRRect(
      lensRRect,
      Paint()..color = const Color(0x33E0F2FE), // Kaca bening dengan semburat kilau lembut
    );
    canvas.drawRRect(lensRRect, clearFramePaint);
    canvas.drawRRect(lensRRect, clearFrameOuter);

    // Gagang Kacamata Putih ke Arah Telinga Belakang
    canvas.drawLine(const Offset(0, -65), const Offset(-7, -65), clearFramePaint);

    // Garis Kilau Refleksi Cahaya Miring di Kaca Bening
    final glassShine = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(3, -67), const Offset(7, -62), glassShine);

    // Senyum Ramah di Wajah Samping
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
    _drawSyringeBlasterSide(canvas);
  }

  void _drawSyringeBlasterSide(Canvas canvas) {
    canvas.save();
    // Posisi kedua tangan memegang syringe blaster ke arah kanan (sisi game)
    canvas.translate(10, -36);

    // Lengan Jas Snelli Putih
    final sleevePaint = Paint()..color = const Color(0xFFFFFFFF);
    final sleeveBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final armRect = RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -4, 11, 8), const Radius.circular(3));
    canvas.drawRRect(armRect, sleevePaint);
    canvas.drawRRect(armRect, sleeveBorder);

    // Tabung Syringe Blaster Medis
    final syringeBodyPaint = Paint()..color = const Color(0xEEF1F5F9);
    final syringeBorder = Paint()
      ..color = const Color(0xFF00A896)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final tubeRect = const Rect.fromLTWH(8, -5, 16, 9);
    canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(2)), syringeBodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(2)), syringeBorder);

    // Cairan Antiseptik / Vitamin Pendar di Dalam Tabung
    final fluidColor = isSpreadShotActive ? const Color(0xFFFF9100) : const Color(0xFF00E5FF);
    final fluidPaint = Paint()..color = fluidColor;
    canvas.drawRect(const Rect.fromLTWH(9, -3, 12, 5), fluidPaint);

    // Moncong Jarum Suntik Perak
    final nozzlePaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRect(const Rect.fromLTWH(24, -2, 4, 3), nozzlePaint);
    final needlePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.6;
    // Jarum memanjang dari 28 sampai 37 (total x = 10 + 37 = 47)
    canvas.drawLine(const Offset(28, -0.5), const Offset(37, -0.5), needlePaint);

    // Pendorong Belakang Syringe Blaster
    final plungerPaint = Paint()..color = const Color(0xFF00A896);
    canvas.drawRect(const Rect.fromLTWH(4, -3, 4, 5), plungerPaint);

    // Pendaran Cahaya di Ujung Jarum
    final glowPaint = Paint()..color = fluidColor.withOpacity(0.6);
    canvas.drawCircle(const Offset(37, -0.5), 3.5, glowPaint);

    canvas.restore();
  }

  /// Titik keluarnya peluru tembakan presisi dari ujung jarum suntik
  Vector2 get muzzlePosition {
    final offsetX = facingDirection == 1 ? 47.0 : -47.0;
    return Vector2(position.x + offsetX, position.y - 36.5);
  }
}
