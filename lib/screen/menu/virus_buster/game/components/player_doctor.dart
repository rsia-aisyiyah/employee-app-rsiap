import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerDoctor extends PositionComponent with HasGameRef, CollisionCallbacks {
  // Movement & Physics
  double velocityX = 0.0;
  double velocityY = 0.0;
  static const double moveSpeed = 220.0;
  static const double jumpForce = -420.0;
  static const double gravity = 980.0;

  bool isOnGround = true;
  double groundY = 0.0;
  int facingDirection = 1; // 1 = Kanan, -1 = Kiri

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

  PlayerDoctor() : super(size: Vector2(44, 76), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Hitbox sedikit lebih ramping untuk gameplay yang adil
    hitbox = RectangleHitbox(
      size: Vector2(30, 68),
      position: Vector2(7, 4),
    );
    add(hitbox);
  }

  void setupGround(double y) {
    groundY = y;
    position.y = groundY;
    position.x = 80;
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
    if (position.x < 24) position.x = 24;

    // Run animation cycle
    if (isMoving && isOnGround) {
      runCycle += dt * 14;
    } else if (!isOnGround) {
      runCycle = 1.5; // Pose melayang di udara
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

    // Orientasi hadap kanan / kiri
    if (facingDirection == -1) {
      canvas.scale(-1, 1);
    }

    _drawDoctor(canvas);

    canvas.restore();
  }

  void _drawDoctor(Canvas canvas) {
    final double legSwing = sin(runCycle) * 10;
    final double coatSwing = sin(runCycle - 0.5) * 8;

    // 0. Bayangan di tanah saat di dekat tanah
    if (isOnGround) {
      final shadowPaint = Paint()..color = const Color(0x33000000);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 0), width: 34, height: 8),
        shadowPaint,
      );
    }

    // Aura APD Shield (Emas Bercahaya) jika aktif
    if (isShieldActive) {
      final shieldPaint = Paint()
        ..color = const Color(0x66FFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final shieldGlow = Paint()
        ..color = const Color(0x22FFEA00)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(0, -38), 40, shieldGlow);
      canvas.drawCircle(const Offset(0, -38), 40, shieldPaint);
    }

    // 1. Kaki & Celana Biru Tua
    final pantsPaint = Paint()..color = const Color(0xFF1E293B);
    final shoesPaint = Paint()..color = const Color(0xFF0F172A);

    // Kaki Belakang
    canvas.save();
    canvas.translate(-5, -20);
    canvas.rotate((-legSwing * pi / 180));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 8, 20), const Radius.circular(3)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 17, 10, 5), const Radius.circular(2)),
      shoesPaint,
    );
    canvas.restore();

    // Kaki Depan
    canvas.save();
    canvas.translate(5, -20);
    canvas.rotate((legSwing * pi / 180));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 8, 20), const Radius.circular(3)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 17, 10, 10), const Radius.circular(2)),
      shoesPaint,
    );
    canvas.restore();

    // 2. Jas Snelli Dokter Putih (Bagian Belakang / Berkibar)
    final coatBackPaint = Paint()..color = const Color(0xFFE2E8F0);
    final coatPathBack = Path();
    coatPathBack.moveTo(-10, -50);
    coatPathBack.lineTo(-12 - coatSwing, -16);
    coatPathBack.lineTo(-2, -18);
    coatPathBack.close();
    canvas.drawPath(coatPathBack, coatBackPaint);

    // 3. Badan: Kemeja Biru Cerah & Dasi Biru Tua RSIA
    final shirtPaint = Paint()..color = const Color(0xFF38BDF8); // Kemeja biru muda
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -52, 18, 32), const Radius.circular(4)),
      shirtPaint,
    );

    // Dasi Biru RSIA
    final tiePaint = Paint()..color = const Color(0xFF0284C7);
    final tiePath = Path();
    tiePath.moveTo(0, -48);
    tiePath.lineTo(-3, -38);
    tiePath.lineTo(0, -32);
    tiePath.lineTo(3, -38);
    tiePath.close();
    canvas.drawPath(tiePath, tiePaint);

    // 4. Jas Snelli Putih Depan
    final coatFrontPaint = Paint()..color = const Color(0xFFFFFFFF);
    final coatBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final coatFrontRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-11, -52, 22, 34),
      const Radius.circular(4),
    );
    canvas.drawRRect(coatFrontRect, coatFrontPaint);
    canvas.drawRRect(coatFrontRect, coatBorderPaint);

    // Belahan Jas & Saku Dada
    final linePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(0, -46), const Offset(0, -20), linePaint);
    // Saku kecil dada kiri
    canvas.drawRect(const Rect.fromLTWH(3, -45, 5, 4), linePaint..style = PaintingStyle.stroke);

    // 5. Stetoskop di Leher
    final stethoPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final stethoPath = Path();
    stethoPath.moveTo(-6, -52);
    stethoPath.quadraticBezierTo(0, -40, 6, -52);
    canvas.drawPath(stethoPath, stethoPaint);
    // Bell stetoskop perak
    canvas.drawCircle(const Offset(2, -41), 2.5, Paint()..color = const Color(0xFFCBD5E1));

    // 6. Leher & Kepala
    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    canvas.drawRect(const Rect.fromLTWH(-4, -55, 8, 4), skinPaint);

    // Kepala / Muka
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -70, 20, 16), const Radius.circular(6)),
      skinPaint,
    );

    // Rambut Hitam Rapi Bergelombang
    final hairPaint = Paint()..color = const Color(0xFF0F172A);
    final hairPath = Path();
    hairPath.moveTo(-11, -66);
    hairPath.lineTo(-11, -73);
    hairPath.quadraticBezierTo(0, -76, 11, -73);
    hairPath.lineTo(11, -66);
    hairPath.lineTo(9, -68);
    hairPath.quadraticBezierTo(0, -70, -9, -68);
    hairPath.close();
    canvas.drawPath(hairPath, hairPaint);

    // 7. Kacamata Hitam Kotak Persegi Modern (Sesuai Referensi Foto)
    final glassesFramePaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final glassesLensPaint = Paint()..color = const Color(0xFF1E293B);

    // Lensa Kotak Kiri & Kanan
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -66, 6.5, 5.5), const Radius.circular(1.5)),
      glassesLensPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -66, 6.5, 5.5), const Radius.circular(1.5)),
      glassesFramePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(1.5, -66, 6.5, 5.5), const Radius.circular(1.5)),
      glassesLensPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(1.5, -66, 6.5, 5.5), const Radius.circular(1.5)),
      glassesFramePaint,
    );
    // Gagang tengah kacamata
    canvas.drawLine(const Offset(-1.5, -64), const Offset(1.5, -64), glassesFramePaint);

    // Senyum Percaya Diri
    final smilePaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      const Rect.fromLTWH(-3, -59, 6, 3),
      0,
      pi,
      false,
      smilePaint,
    );

    // 8. Tangan & Syringe Blaster (Senjata Medis Disinfektan)
    _drawSyringeBlaster(canvas);
  }

  void _drawSyringeBlaster(Canvas canvas) {
    canvas.save();
    // Posisi tangan memegang blaster mengarah ke depan
    canvas.translate(10, -36);

    // Lengan Jas Putih
    final sleevePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -4, 10, 7), const Radius.circular(3)),
      sleevePaint,
    );

    // Tabung Syringe Blaster (Kaca Transparan Medis)
    final syringeBodyPaint = Paint()..color = const Color(0xCCF1F5F9);
    final syringeBorder = Paint()
      ..color = const Color(0xFF00A896)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Tabung Utama
    final tubeRect = const Rect.fromLTWH(8, -5, 16, 9);
    canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(2)), syringeBodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(2)), syringeBorder);

    // Cairan Antiseptik / Vitamin Pendar di Dalam Tabung
    final fluidColor = isSpreadShotActive ? const Color(0xFFFF9100) : const Color(0xFF00E5FF);
    final fluidPaint = Paint()..color = fluidColor;
    canvas.drawRect(const Rect.fromLTWH(9, -3, 12, 5), fluidPaint);

    // Moncong Jarum Suntik Emas / Perak
    final nozzlePaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRect(const Rect.fromLTWH(24, -2, 5, 3), nozzlePaint);
    final needlePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.4;
    canvas.drawLine(const Offset(29, -0.5), const Offset(36, -0.5), needlePaint);

    // Pendorong Belakang Syringe Blaster
    final plungerPaint = Paint()..color = const Color(0xFF00A896);
    canvas.drawRect(const Rect.fromLTWH(4, -3, 4, 5), plungerPaint);

    // Pendaran Cahaya di Ujung Jarum
    final glowPaint = Paint()..color = fluidColor.withOpacity(0.5);
    canvas.drawCircle(const Offset(36, -0.5), 3.5, glowPaint);

    canvas.restore();
  }

  /// Titik keluarnya peluru tembakan dari ujung syringe blaster
  Vector2 get muzzlePosition {
    final offsetX = facingDirection == 1 ? 46.0 : -46.0;
    return Vector2(position.x + offsetX, position.y - 36.5);
  }
}
