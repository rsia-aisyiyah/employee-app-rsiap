import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class AntisepticBullet extends PositionComponent with HasGameRef, CollisionCallbacks {
  final double speed;
  final double directionX;
  final double directionY;
  final bool isEnhanced; // Spread/Vitamin C shot
  final double maxDistance;
  double traveledDistance = 0.0;

  late RectangleHitbox hitbox;

  AntisepticBullet({
    required Vector2 startPosition,
    this.speed = 520.0,
    this.directionX = 1.0,
    this.directionY = 0.0,
    this.isEnhanced = false,
    this.maxDistance = 750.0,
  }) : super(
          position: startPosition,
          size: Vector2(18, 8),
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
    final bulletColor = isEnhanced ? const Color(0xFFFF9100) : const Color(0xFF00E5FF);
    final glowColor = isEnhanced ? const Color(0x66FF9100) : const Color(0x6600E5FF);

    // Cahaya pendar peluru
    final glowPaint = Paint()..color = glowColor;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 7, glowPaint);

    // Kapsul antiseptik
    final corePaint = Paint()..color = bulletColor;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 1, size.x, size.y - 2),
      const Radius.circular(3),
    );
    canvas.drawRRect(rrect, corePaint);

    // Ujung putih terang
    final tipPaint = Paint()..color = Colors.white;
    final tipX = directionX >= 0 ? size.x - 4 : 0.0;
    canvas.drawCircle(Offset(tipX + 2, size.y / 2), 2, tipPaint);
  }
}
