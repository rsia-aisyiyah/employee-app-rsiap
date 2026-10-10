import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/player_doctor.dart';

class AntisepticBullet extends PositionComponent with HasGameRef, CollisionCallbacks {
  final double speed;
  final double directionX;
  final double directionY;
  final bool isEnhanced; // Spread/Vitamin C shot
  final double maxDistance;
  final Color? customBulletColor;
  final Color? customGlowColor;
  double traveledDistance = 0.0;

  late RectangleHitbox hitbox;

  AntisepticBullet({
    required Vector2 startPosition,
    this.speed = 560.0,
    this.directionX = 1.0,
    this.directionY = 0.0,
    this.isEnhanced = false,
    this.maxDistance = 850.0,
    this.customBulletColor,
    this.customGlowColor,
  }) : super(
          position: startPosition,
          size: Vector2(28, 13),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    hitbox = RectangleHitbox();
    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final dx = speed * directionX * dt;
    final dy = speed * directionY * dt;
    position.x += dx;
    position.y += dy;
    traveledDistance += sqrt(dx * dx + dy * dy);

    if (traveledDistance >= maxDistance) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final bulletColor = isEnhanced
        ? const Color(0xFFFF9100)
        : (customBulletColor ?? const Color(0xFF00E5FF));
    final glowColor = isEnhanced
        ? const Color(0x66FF9100)
        : (customGlowColor ?? const Color(0x6600E5FF));

    // Cahaya pendar peluru
    final glowPaint = Paint()..color = glowColor;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 11, glowPaint);

    // Kapsul antiseptik
    final corePaint = Paint()..color = bulletColor;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 1, size.x, size.y - 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, corePaint);

    // Ujung putih terang
    final tipPaint = Paint()..color = Colors.white;
    final tipX = directionX >= 0 ? size.x - 5 : 0.0;
    canvas.drawCircle(Offset(tipX + 2.5, size.y / 2), 2.5, tipPaint);
  }
}

/// Proyektil serangan Boss (Lendir Flu, Duri Corona, Spora Beracun)
class VirusProjectile extends PositionComponent with HasGameRef, CollisionCallbacks {
  final double speed;
  final double directionX;
  final double directionY;
  final Color coreColor;
  final Color glowColor;
  final double radius;
  final void Function(PlayerDoctor player)? onHitPlayer;

  double animTimer = 0.0;
  late CircleHitbox hitbox;

  VirusProjectile({
    required Vector2 startPosition,
    this.speed = 210.0,
    this.directionX = -1.0,
    this.directionY = 0.0,
    this.coreColor = const Color(0xFFEF4444), // Merah corona default
    this.glowColor = const Color(0x66EF4444),
    this.radius = 12.0,
    this.onHitPlayer,
  }) : super(
          position: startPosition,
          size: Vector2(radius * 2, radius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    hitbox = CircleHitbox(radius: radius * 0.85, position: Vector2(radius * 0.15, radius * 0.15));
    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    animTimer += dt * 6.0;

    position.x += speed * directionX * dt;
    position.y += speed * directionY * dt;

    // Hilang jika keluar layar kiri atau bawah
    if (position.x < -50 || position.y > gameRef.size.y + 50 || position.y < -50) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is PlayerDoctor) {
      onHitPlayer?.call(other);
      removeFromParent();
    } else if (other is AntisepticBullet) {
      // Peluru antiseptik dokter bisa menembak jatuh peluru virus!
      other.removeFromParent();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);

    // 1. Glow aura
    final glowPaint = Paint()..color = glowColor;
    canvas.drawCircle(center, radius + 4 + sin(animTimer) * 2, glowPaint);

    // 2. Core bola virus
    final corePaint = Paint()..color = coreColor;
    canvas.drawCircle(center, radius, corePaint);

    // 3. Spikes kecil melingkar berputar
    final spikePaint = Paint()..color = coreColor.withValues(alpha: 0.9);
    const int spikes = 6;
    for (int i = 0; i < spikes; i++) {
      final angle = animTimer + (i * 2 * pi / spikes);
      final spikeX = center.dx + cos(angle) * (radius + 3);
      final spikeY = center.dy + sin(angle) * (radius + 3);
      canvas.drawCircle(Offset(spikeX, spikeY), 2.5, spikePaint);
    }

    // 4. Titik inti membara
    final centerCorePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(center, radius * 0.35, centerCorePaint);
  }
}
