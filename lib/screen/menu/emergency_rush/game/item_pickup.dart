import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/game/lane_config.dart';

enum ItemType {
  firstAidKit,
  energyCapsule,
  goldenStar,
}

class ItemPickup extends PositionComponent with HasGameRef, CollisionCallbacks {
  final ItemType type;
  final Lane lane;
  double pulseTimer = 0.0;

  late CircleHitbox hitbox;

  ItemPickup({
    required this.type,
    required this.lane,
    required Vector2 initialPosition,
  }) : super(
          position: initialPosition,
          size: Vector2(36, 36),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    hitbox = CircleHitbox(
      radius: size.x * 0.45,
      position: Vector2(size.x * 0.05, size.y * 0.05),
    );
    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    pulseTimer += dt;

    final screenSize = (gameRef as dynamic).size as Vector2;
    if (position.y > screenSize.y + 80) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final center = Offset(w / 2, h / 2);

    // Subtle pulsing scale
    final pulseScale = 1.0 + (sin(pulseTimer * 8) * 0.08);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulseScale, pulseScale);
    canvas.translate(-center.dx, -center.dy);

    switch (type) {
      case ItemType.firstAidKit:
        _renderFirstAidKit(canvas, w, h);
        break;
      case ItemType.energyCapsule:
        _renderEnergyCapsule(canvas, w, h);
        break;
      case ItemType.goldenStar:
        _renderGoldenStar(canvas, w, h);
        break;
    }

    canvas.restore();
  }

  void _renderFirstAidKit(Canvas canvas, double w, double h) {
    // Aura glow
    final glowPaint = Paint()
      ..color = const Color(0x5500A896)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(w / 2, h / 2), 16, glowPaint);

    // Box body
    final boxPaint = Paint()..color = const Color(0xFFFFFFFF);
    final borderPaint = Paint()
      ..color = const Color(0xFF00A896)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, w - 8, h - 8), const Radius.circular(6));
    canvas.drawRRect(rect, boxPaint);
    canvas.drawRRect(rect, borderPaint);

    // Red Cross inside
    final crossPaint = Paint()..color = const Color(0xFFE53935);
    const arm = 14.0;
    const thick = 4.0;
    canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: arm, height: thick), crossPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: thick, height: arm), crossPaint);
  }

  void _renderEnergyCapsule(Canvas canvas, double w, double h) {
    // Glow
    final glowPaint = Paint()
      ..color = const Color(0x6600E5FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(w / 2, h / 2), 16, glowPaint);

    final center = Offset(w / 2, h / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.5); // tilted capsule
    canvas.translate(-center.dx, -center.dy);

    const capW = 14.0;
    const capH = 24.0;
    final capX = (w - capW) / 2;
    final capY = (h - capH) / 2;

    // Top half (Cyan)
    final topPaint = Paint()..color = const Color(0xFF00E5FF);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(capX, capY, capW, capH / 2),
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      ),
      topPaint,
    );

    // Bottom half (Yellow)
    final bottomPaint = Paint()..color = const Color(0xFFFFEA00);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(capX, capY + capH / 2, capW, capH / 2),
        bottomLeft: const Radius.circular(7),
        bottomRight: const Radius.circular(7),
      ),
      bottomPaint,
    );

    // Shine reflection
    final shinePaint = Paint()..color = const Color(0x99FFFFFF);
    canvas.drawRect(Rect.fromLTWH(capX + 2, capY + 4, 2, capH - 8), shinePaint);

    canvas.restore();
  }

  void _renderGoldenStar(Canvas canvas, double w, double h) {
    final glowPaint = Paint()
      ..color = const Color(0x88FFD700)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(w / 2, h / 2), 16, glowPaint);

    final starPaint = Paint()..color = const Color(0xFFFFD700);
    final borderPaint = Paint()
      ..color = const Color(0xFFFF6F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final center = Offset(w / 2, h / 2);
    const outerR = 14.0;
    const innerR = 6.0;
    const points = 5;

    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? outerR : innerR;
      final angle = (i * pi / points) - (pi / 2);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, starPaint);
    canvas.drawPath(path, borderPaint);
  }
}
