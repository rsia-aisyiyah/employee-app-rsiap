import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/bullet.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/player_doctor.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/models/virus_buster_models.dart';

class VirusEnemy extends PositionComponent with HasGameRef, CollisionCallbacks {
  final VirusType type;
  final double moveSpeed;
  final double initialGroundY;
  int currentHp;
  final int maxHp;

  double animTimer = 0.0;
  double hitFlashTimer = 0.0;

  // Gerakan khusus
  double bounceBaseY = 0.0;
  double bouncePhase = 0.0;
  bool hasEnteredScreen = false;

  final void Function(VirusEnemy enemy, int scoreAwarded)? onDefeated;
  final void Function(PlayerDoctor player)? onHitPlayer;

  late CircleHitbox hitbox;

  VirusEnemy({
    required this.type,
    required Vector2 position,
    required this.initialGroundY,
    this.moveSpeed = 90.0,
    this.onDefeated,
    this.onHitPlayer,
  })  : maxHp = _calcMaxHp(type),
        currentHp = _calcMaxHp(type),
        super(
          position: position,
          size: _calcSize(type),
          anchor: Anchor.center,
        ) {
    bounceBaseY = position.y;
    bouncePhase = Random().nextDouble() * pi * 2;
  }

  static int _calcMaxHp(VirusType type) {
    switch (type) {
      case VirusType.fluGoo:
        return 1;
      case VirusType.mosquito:
        return 1;
      case VirusType.spikeCorona:
        return 2;
      case VirusType.bossMega:
        return 16;
    }
  }

  static Vector2 _calcSize(VirusType type) {
    switch (type) {
      case VirusType.fluGoo:
        return Vector2(36, 32);
      case VirusType.mosquito:
        return Vector2(34, 28);
      case VirusType.spikeCorona:
        return Vector2(42, 42);
      case VirusType.bossMega:
        return Vector2(88, 88);
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    hitbox = CircleHitbox(radius: size.x * 0.45, position: Vector2(size.x * 0.05, size.y * 0.05));
    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    animTimer += dt * 6;

    if (hitFlashTimer > 0) {
      hitFlashTimer -= dt;
    }

    // Gerakan Horizontal ke arah kiri (mendekati dokter)
    if (type == VirusType.bossMega) {
      final double arenaTargetX = gameRef.size.x - (size.x * 0.6) - 12;
      if (!hasEnteredScreen) {
        // Fase Masuk ke Layar (Entrance): Bergerak maju ke dalam arena
        position.x -= 140 * dt;
        if (position.x <= arenaTargetX) {
          position.x = arenaTargetX;
          hasEnteredScreen = true;
        }
      } else {
        // Fase Pertarungan di Dalam Layar (On-Screen Battle): Melayang naik-turun & maju-mundur
        position.x = arenaTargetX + sin(animTimer * 0.7) * 22;
        position.y = bounceBaseY + sin(animTimer * 1.5) * 32;
      }
    } else if (type == VirusType.spikeCorona) {
      position.x -= moveSpeed * dt;
      // Memantul gelombang
      position.y = bounceBaseY + sin(animTimer + bouncePhase) * 35;
    } else if (type == VirusType.mosquito) {
      position.x -= (moveSpeed + 40) * dt;
      // Menukik zig-zag
      position.y = bounceBaseY + cos(animTimer * 1.5) * 30;
    } else {
      // Flu Goo merayap di lantai
      position.x -= moveSpeed * dt;
      position.y = initialGroundY - (size.y / 2);
    }

    // Keluar layar ke kiri
    if (position.x < -100) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is AntisepticBullet) {
      other.removeFromParent();
      takeDamage(1);
    } else if (other is PlayerDoctor) {
      if (other.isShieldActive) {
        // Player memiliki pelindung APD: hancurkan virus langsung tanpa melukai player
        takeDamage(currentHp);
      } else if (type == VirusType.fluGoo && other.velocityY > 0 && other.position.y <= position.y + 10) {
        // MARIO STOMP: Kuman yang jalan di darat mati jika diinjak dari atas!
        takeDamage(currentHp);
        other.bounceAfterStomp();
      } else {
        onHitPlayer?.call(other);
      }
    }
  }

  void takeDamage(int damage) {
    currentHp -= damage;
    hitFlashTimer = 0.12;

    if (currentHp <= 0) {
      final score = type == VirusType.bossMega
          ? 250
          : (type == VirusType.spikeCorona ? 40 : 25);
      onDefeated?.call(this, score);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    final bool isFlash = hitFlashTimer > 0;

    switch (type) {
      case VirusType.fluGoo:
        _drawFluGoo(canvas, isFlash);
        break;
      case VirusType.spikeCorona:
        _drawSpikeCorona(canvas, isFlash);
        break;
      case VirusType.mosquito:
        _drawMosquito(canvas, isFlash);
        break;
      case VirusType.bossMega:
        _drawBossMega(canvas, isFlash);
        break;
    }

    // Draw HP Bar if Boss
    if (type == VirusType.bossMega) {
      _drawBossHpBar(canvas);
    }

    canvas.restore();
  }

  void _drawFluGoo(Canvas canvas, bool isFlash) {
    final wobble = sin(animTimer) * 2.5;
    final bodyPaint = Paint()
      ..color = isFlash ? Colors.white : const Color(0xFF22C55E); // Hijau lendir
    final shadowPaint = Paint()..color = const Color(0xFF15803D);

    // Tubuh lendir slime
    final path = Path();
    path.moveTo(-14, 12);
    path.quadraticBezierTo(-18 - wobble, -2, -10, -12);
    path.quadraticBezierTo(0, -16 + wobble, 10, -12);
    path.quadraticBezierTo(18 + wobble, -2, 14, 12);
    path.close();

    canvas.drawPath(path, bodyPaint);

    // Mata jahat / nakal
    final eyeWhite = Paint()..color = Colors.white;
    final eyePupil = Paint()..color = const Color(0xFF0F172A);

    canvas.drawCircle(const Offset(-5, -4), 4, eyeWhite);
    canvas.drawCircle(const Offset(-6, -4), 2, eyePupil);

    canvas.drawCircle(const Offset(5, -4), 4, eyeWhite);
    canvas.drawCircle(const Offset(4, -4), 2, eyePupil);

    // Alis marah
    final browPaint = Paint()
      ..color = const Color(0xFF052E16)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(-8, -9), const Offset(-2, -7), browPaint);
    canvas.drawLine(const Offset(2, -7), const Offset(8, -9), browPaint);
  }

  void _drawSpikeCorona(Canvas canvas, bool isFlash) {
    final spin = animTimer * 0.8;
    canvas.rotate(spin);

    final coronaColor = isFlash ? Colors.white : const Color(0xFFEF4444); // Merah Corona
    final spikeColor = isFlash ? Colors.white : const Color(0xFFB91C1C);

    // 8 Duri Spike berputar
    for (int i = 0; i < 8; i++) {
      final angle = i * (pi / 4);
      final dx = cos(angle);
      final dy = sin(angle);

      final spikeStem = Paint()
        ..color = spikeColor
        ..strokeWidth = 2.5;
      canvas.drawLine(Offset(dx * 12, dy * 12), Offset(dx * 18, dy * 18), spikeStem);
      canvas.drawCircle(Offset(dx * 19, dy * 19), 3.0, Paint()..color = spikeColor);
    }

    // Bola tengah
    canvas.drawCircle(Offset.zero, 13, Paint()..color = coronaColor);
    canvas.drawCircle(
      const Offset(-3, -3),
      11,
      Paint()..color = isFlash ? Colors.white : const Color(0xFFDC2626),
    );

    // Mata merah menyala
    canvas.drawCircle(const Offset(-4, -1), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(4, -1), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(-4, -1), 1.2, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(4, -1), 1.2, Paint()..color = Colors.black);
  }

  void _drawMosquito(Canvas canvas, bool isFlash) {
    final wingFlap = sin(animTimer * 4) * 6;

    // Sayap Kiri & Kanan (Transparan)
    final wingPaint = Paint()..color = const Color(0x9993C5FD);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-10, -10 + wingFlap), width: 14, height: 6),
      wingPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-2, -12 - wingFlap), width: 14, height: 6),
      wingPaint,
    );

    // Badan serangga/mikrob
    final bodyPaint = Paint()..color = isFlash ? Colors.white : const Color(0xFF6B21A8);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 16, height: 10),
      bodyPaint,
    );

    // Moncong runcing penusuk
    final proboscisPaint = Paint()
      ..color = const Color(0xFF3B0764)
      ..strokeWidth = 1.8;
    canvas.drawLine(const Offset(-8, 2), const Offset(-16, 7), proboscisPaint);

    // Mata kuning menyala
    canvas.drawCircle(const Offset(-5, -2), 2.2, Paint()..color = const Color(0xFFFACC15));
  }

  void _drawBossMega(Canvas canvas, bool isFlash) {
    final spin = animTimer * 0.4;
    canvas.save();
    canvas.rotate(spin);

    final bossColor = isFlash ? Colors.white : const Color(0xFF9333EA); // Ungu gelap mutasi
    final auraColor = const Color(0x33A855F7);

    // Aura pendar boss
    canvas.drawCircle(Offset.zero, 44, Paint()..color = auraColor);

    // 12 Duri Mahkota Mutasi
    for (int i = 0; i < 12; i++) {
      final angle = i * (pi / 6);
      final dx = cos(angle);
      final dy = sin(angle);

      final spikeStem = Paint()
        ..color = isFlash ? Colors.white : const Color(0xFF7E22CE)
        ..strokeWidth = 4.0;
      canvas.drawLine(Offset(dx * 26, dy * 26), Offset(dx * 38, dy * 38), spikeStem);
      canvas.drawCircle(
        Offset(dx * 39, dy * 39),
        5.5,
        Paint()..color = const Color(0xFFF43F5E), // Ujung merah membara
      );
    }

    // Inti Monster Boss
    canvas.drawCircle(Offset.zero, 28, Paint()..color = bossColor);
    canvas.restore();

    // Wajah Boss Tetap Menghadap Depan
    final eyePaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(const Offset(-9, -6), 6, eyePaint);
    canvas.drawCircle(const Offset(9, -6), 6, eyePaint);
    canvas.drawCircle(const Offset(-9, -6), 3, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(9, -6), 3, Paint()..color = Colors.black);

    // Mulut bergigi tajam
    final mouthPath = Path();
    mouthPath.moveTo(-12, 10);
    mouthPath.lineTo(-6, 16);
    mouthPath.lineTo(0, 11);
    mouthPath.lineTo(6, 16);
    mouthPath.lineTo(12, 10);
    mouthPath.close();
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF0F172A));
  }

  void _drawBossHpBar(Canvas canvas) {
    const double barWidth = 60.0;
    const double barHeight = 6.0;
    final barRect = Rect.fromCenter(center: const Offset(0, -48), width: barWidth, height: barHeight);

    // Background bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF334155),
    );

    // Progress bar
    final fillRatio = (currentHp / maxHp).clamp(0.0, 1.0);
    final fillRect = Rect.fromLTWH(
      barRect.left,
      barRect.top,
      barWidth * fillRatio,
      barHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFFEF4444),
    );
  }
}
