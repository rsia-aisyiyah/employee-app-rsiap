import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/player_doctor.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/models/virus_buster_models.dart';

class PowerupItem extends PositionComponent with HasGameRef, CollisionCallbacks {
  final PowerupType type;
  final double groundY;
  final void Function(PowerupType type)? onCollected;

  double floatTimer = 0.0;
  double baseY = 0.0;
  late RectangleHitbox hitbox;

  PowerupItem({
    required this.type,
    required Vector2 position,
    required this.groundY,
    this.onCollected,
  }) : super(
          position: position,
          size: Vector2(28, 28),
          anchor: Anchor.center,
        ) {
    baseY = position.y;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    hitbox = RectangleHitbox();
    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    floatTimer += dt * 3.5;

    // Gerak melayang perlahan & scrolling ke kiri
    position.x -= 40 * dt;
    position.y = baseY + sin(floatTimer) * 6;

    if (position.x < -40) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerDoctor) {
      onCollected?.call(type);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // Glow aura lingkaran luar
    final glowPaint = Paint()..color = _getColor().withOpacity(0.3);
    canvas.drawCircle(Offset.zero, 16, glowPaint);

    switch (type) {
      case PowerupType.firstAid:
        _drawFirstAid(canvas);
        break;
      case PowerupType.spreadShot:
        _drawVitaminCapsule(canvas);
        break;
      case PowerupType.hazmatShield:
        _drawHazmatShield(canvas);
        break;
      case PowerupType.sanitizerBomb:
        _drawSanitizer(canvas);
        break;
    }

    canvas.restore();
  }

  Color _getColor() {
    switch (type) {
      case PowerupType.firstAid:
        return const Color(0xFFEF4444);
      case PowerupType.spreadShot:
        return const Color(0xFFFF9100);
      case PowerupType.hazmatShield:
        return const Color(0xFFEAB308);
      case PowerupType.sanitizerBomb:
        return const Color(0xFF00E5FF);
    }
  }

  void _drawFirstAid(Canvas canvas) {
    // Kotak putih
    final boxPaint = Paint()..color = Colors.white;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 22),
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect, boxPaint);

    // Border merah
    final borderPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);

    // Palang Merah
    final crossPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 4.5, height: 14), crossPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14, height: 4.5), crossPaint);
  }

  void _drawVitaminCapsule(Canvas canvas) {
    canvas.rotate(pi / 4);
    // Kapsul dua warna: Kuning & Putih
    final yellowPaint = Paint()..color = const Color(0xFFFF9100);
    final whitePaint = Paint()..color = Colors.white;

    final capsuleRect = Rect.fromCenter(center: Offset.zero, width: 22, height: 11);
    final rrect = RRect.fromRectAndRadius(capsuleRect, const Radius.circular(5.5));
    canvas.drawRRect(rrect, yellowPaint);

    // Separuh putih
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(-11, -5.5, 11, 11));
    canvas.drawRRect(rrect, whitePaint);
    canvas.restore();

    // Garis tengah
    canvas.drawLine(const Offset(0, -5.5), const Offset(0, 5.5), Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1.2);
  }

  void _drawHazmatShield(Canvas canvas) {
    // Tameng Emas Pelindung APD
    final shieldPaint = Paint()..color = const Color(0xFFEAB308);
    final path = Path();
    path.moveTo(0, -11);
    path.lineTo(10, -7);
    path.lineTo(8, 5);
    path.lineTo(0, 11);
    path.lineTo(-8, 5);
    path.lineTo(-10, -7);
    path.close();
    canvas.drawPath(path, shieldPaint);

    // Simbol Biohazard / Bintang di dalam
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, 3.5, innerPaint);
  }

  void _drawSanitizer(Canvas canvas) {
    // Botol Hand Sanitizer Toska
    final bottlePaint = Paint()..color = const Color(0xFF00E5FF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -4, 12, 14), const Radius.circular(2)),
      bottlePaint,
    );
    // Pompa dispenser atas
    final pumpPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(-2, -9, 4, 5), pumpPaint);
    canvas.drawRect(const Rect.fromLTWH(-5, -11, 7, 2.5), pumpPaint);
  }
}
