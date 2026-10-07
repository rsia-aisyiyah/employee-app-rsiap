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
    position.x = 90;
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
    if (position.x < 30) position.x = 30;

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

    // PUSAT KOORDINAT: geser ke tengah dasar kaki dokter (bottom center)
    // Dengan ini (0,0) adalah tepat di telapak kaki dokter di tanah!
    canvas.translate(size.x / 2, size.y);

    // Flip hadap kiri / kanan tepat di poros tengah tubuh dokter
    if (facingDirection == -1) {
      canvas.scale(-1, 1);
    }

    _drawDoctor(canvas);

    canvas.restore();
  }

  void _drawDoctor(Canvas canvas) {
    final double legSwing = sin(runCycle) * 11;
    final double coatSwing = sin(runCycle - 0.5) * 8;

    // 0. Bayangan di tanah (hanya menempel di telapak saat di tanah)
    if (isOnGround) {
      final shadowPaint = Paint()..color = const Color(0x35000000);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 0), width: 36, height: 7),
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
      canvas.drawCircle(const Offset(0, -38), 42, shieldGlow);
      canvas.drawCircle(const Offset(0, -38), 42, shieldPaint);
    }

    // 1. Kaki & Celana Biru Tua Formal
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
      RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 16, 11, 5), const Radius.circular(2)),
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
      RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 16, 11, 5), const Radius.circular(2)),
      shoesPaint,
    );
    canvas.restore();

    // 2. Jas Snelli Dokter Putih (Bagian Belakang / Berkibar)
    final coatBackPaint = Paint()..color = const Color(0xFFE2E8F0);
    final coatPathBack = Path();
    coatPathBack.moveTo(-11, -52);
    coatPathBack.lineTo(-13 - coatSwing, -16);
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
    tiePath.lineTo(0, -31);
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
      const Rect.fromLTWH(-12, -53, 24, 34),
      const Radius.circular(4),
    );
    canvas.drawRRect(coatFrontRect, coatFrontPaint);
    canvas.drawRRect(coatFrontRect, coatBorderPaint);

    // Kerah Snelli Jas Dokter
    final collarPaint = Paint()..color = const Color(0xFFF1F5F9);
    final leftCollar = Path();
    leftCollar.moveTo(-12, -53);
    leftCollar.lineTo(-3, -42);
    leftCollar.lineTo(-6, -34);
    leftCollar.lineTo(-12, -44);
    leftCollar.close();
    canvas.drawPath(leftCollar, collarPaint);

    final rightCollar = Path();
    rightCollar.moveTo(12, -53);
    rightCollar.lineTo(3, -42);
    rightCollar.lineTo(6, -34);
    rightCollar.lineTo(12, -44);
    rightCollar.close();
    canvas.drawPath(rightCollar, collarPaint);

    // Belahan Jas & Saku Dada
    final linePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(0, -42), const Offset(0, -20), linePaint);
    // Saku kecil dada kiri
    canvas.drawRect(const Rect.fromLTWH(4, -45, 5, 4), linePaint..style = PaintingStyle.stroke);

    // 5. Stetoskop di Leher
    final stethoPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final stethoPath = Path();
    stethoPath.moveTo(-7, -53);
    stethoPath.quadraticBezierTo(0, -42, 7, -53);
    canvas.drawPath(stethoPath, stethoPaint);
    // Bell stetoskop perak
    canvas.drawCircle(const Offset(2, -42), 2.5, Paint()..color = const Color(0xFFCBD5E1));

    // 6. Leher & Kepala
    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    canvas.drawRect(const Rect.fromLTWH(-4, -56, 8, 4), skinPaint);

    // Kepala / Muka
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -71, 20, 16), const Radius.circular(6)),
      skinPaint,
    );

    // Rambut Hitam Rapi Belah Samping (Sesuai Foto Dokter Referensi)
    final hairPaint = Paint()..color = const Color(0xFF0F172A);
    final hairPath = Path();
    hairPath.moveTo(-11, -67);
    hairPath.lineTo(-11, -74);
    hairPath.quadraticBezierTo(-3, -77, 6, -75);
    hairPath.lineTo(11, -72);
    hairPath.lineTo(11, -67);
    hairPath.lineTo(9, -69);
    hairPath.quadraticBezierTo(0, -71, -9, -69);
    hairPath.close();
    canvas.drawPath(hairPath, hairPaint);

    // 7. Kacamata Hitam Kotak Persegi Modern (Sesuai Referensi Foto Asli)
    final glassesFramePaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final glassesLensPaint = Paint()..color = const Color(0xFF1E293B);

    // Lensa Kotak Kiri & Kanan
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -67, 6.5, 5.5), const Radius.circular(1.5)),
      glassesLensPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -67, 6.5, 5.5), const Radius.circular(1.5)),
      glassesFramePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(1.5, -67, 6.5, 5.5), const Radius.circular(1.5)),
      glassesLensPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(1.5, -67, 6.5, 5.5), const Radius.circular(1.5)),
      glassesFramePaint,
    );
    // Gagang tengah kacamata
    canvas.drawLine(const Offset(-1.5, -65), const Offset(1.5, -65), glassesFramePaint);

    // Senyum Ramah
    final smilePaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      const Rect.fromLTWH(-3, -60, 6, 3),
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
    // Posisi tangan dokter memegang blaster
    canvas.translate(10, -36);

    // Lengan Jas Putih
    final sleevePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -4, 10, 7), const Radius.circular(3)),
      sleevePaint,
    );

    // Tabung Syringe Blaster
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
    // Karena anchor = bottomCenter, position.x adalah tengah dokter, position.y adalah tanah (groundY)
    // Ujung jarum suntik ada di x = 47, y = -36.5 relatif terhadap telapak kaki tengah dokter
    final offsetX = facingDirection == 1 ? 47.0 : -47.0;
    return Vector2(position.x + offsetX, position.y - 36.5);
  }
}
