import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rsia_employee_app/screen/menu/emergency_rush/game/lane_config.dart';

class AmbulancePlayer extends PositionComponent with HasGameRef, CollisionCallbacks {
  Lane currentLane = Lane.center;
  double targetX = 0.0;
  double currentTilt = 0.0; // In radians for steering visual effect
  double sirenTimer = 0.0;

  // RSIA Logo
  ui.Image? rsiaLogoImage;

  // Invincibility after hit
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 1.8;

  // Siren Boost mode (energy active)
  bool isSirenBoostActive = false;
  double sirenBoostTimer = 0.0;

  // Paints
  final Paint bodyPaint = Paint()..color = const Color(0xFFFAFAFA);
  final Paint shadowPaint = Paint()..color = const Color(0x55000000);
  final Paint windshieldPaint = Paint()..color = const Color(0xFF263238);
  final Paint rearWindowPaint = Paint()..color = const Color(0xFF37474F);
  final Paint tealStripePaint = Paint()..color = const Color(0xFF00A896); // RSIA primary teal
  final Paint redCrossPaint = Paint()..color = const Color(0xFFE53935);
  final Paint headlightPaint = Paint()
    ..color = const Color(0x33FFF59D)
    ..style = PaintingStyle.fill;
  final Paint sirenRedPaint = Paint()..color = const Color(0xFFFF1744);
  final Paint sirenBluePaint = Paint()..color = const Color(0xFF2979FF);
  final Paint tirePaint = Paint()..color = const Color(0xFF212121);
  final Paint bumperPaint = Paint()..color = const Color(0xFF90A4AE);

  late RectangleHitbox hitbox;

  AmbulancePlayer() : super(size: Vector2(52, 92), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load RSIA official logo asset
    try {
      final byteData = await rootBundle.load('assets/images/logo.png');
      final bytes = byteData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
      final frame = await codec.getNextFrame();
      rsiaLogoImage = frame.image;
    } catch (_) {
      // Fallback to vector cross
    }

    // Hitbox slightly narrower than visual size for forgiving arcade feel
    hitbox = RectangleHitbox(
      size: Vector2(size.x * 0.8, size.y * 0.85),
      position: Vector2(size.x * 0.1, size.y * 0.075),
    );
    add(hitbox);
  }

  void setupInitialPosition({
    required double roadWidth,
    required double roadStartX,
    required double screenHeight,
  }) {
    currentLane = Lane.center;
    targetX = RoadConfig.getLaneCenterX(
      lane: currentLane,
      roadWidth: roadWidth,
      roadStartX: roadStartX,
    );
    final targetY = (screenHeight - 160.0).clamp(100.0, screenHeight - 100.0);
    position = Vector2(targetX, targetY);
  }

  void switchLane(Lane newLane, double roadWidth, double roadStartX) {
    if (currentLane == newLane) return;
    currentLane = newLane;
    targetX = RoadConfig.getLaneCenterX(
      lane: newLane,
      roadWidth: roadWidth,
      roadStartX: roadStartX,
    );
  }

  void moveLeft(double roadWidth, double roadStartX) {
    switchLane(currentLane.toLeft, roadWidth, roadStartX);
  }

  void moveRight(double roadWidth, double roadStartX) {
    switchLane(currentLane.toRight, roadWidth, roadStartX);
  }

  void triggerHit() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }

  void activateSirenBoost(double duration) {
    isSirenBoostActive = true;
    sirenBoostTimer = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    sirenTimer += dt;

    // Smooth horizontal position lerp
    final dx = targetX - position.x;
    position.x += dx * min(1.0, dt * 14.0);

    // Dynamic lean / tilt angle while changing lane
    final targetTilt = (dx.clamp(-40.0, 40.0) / 40.0) * 0.12; // ~7 degrees max
    currentTilt += (targetTilt - currentTilt) * min(1.0, dt * 12.0);

    // Invincibility countdown
    if (isInvincible) {
      invincibilityTimer -= dt;
      if (invincibilityTimer <= 0) {
        isInvincible = false;
      }
    }

    // Siren Boost countdown
    if (isSirenBoostActive) {
      sirenBoostTimer -= dt;
      if (sirenBoostTimer <= 0) {
        isSirenBoostActive = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // If invincible, flash visibility
    if (isInvincible && (sin(sirenTimer * 28) > 0)) {
      return; // Skip rendering frame for flashing effect
    }

    canvas.save();

    // Pivot at center for tilt
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(currentTilt);
    canvas.translate(-size.x / 2, -size.y / 2);

    final w = size.x;
    final h = size.y;

    // 1. Headlight beam cones (draw in front of vehicle)
    _drawHeadlights(canvas, w, h);

    // 2. Drop Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 6, w, h),
        const Radius.circular(8),
      ),
      shadowPaint,
    );

    // 3. 4 Wheels/Tires
    const tireW = 6.0;
    const tireH = 16.0;
    // Front tires
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-2, 14, tireW, tireH), const Radius.circular(2)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 4, 14, tireW, tireH), const Radius.circular(2)), tirePaint);
    // Rear tires
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-2, h - 26, tireW, tireH), const Radius.circular(2)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 4, h - 26, tireW, tireH), const Radius.circular(2)), tirePaint);

    // 4. Main Ambulance Body
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(9),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // 5. Front & Rear Bumpers
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, 0, w - 8, 4), const Radius.circular(2)), bumperPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, h - 4, w - 8, 4), const Radius.circular(2)), bumperPaint);

    // 6. Dual RSIA Teal Stripes (left and right sides)
    canvas.drawRect(Rect.fromLTWH(2, 6, 4, h - 12), tealStripePaint);
    canvas.drawRect(Rect.fromLTWH(w - 6, 6, 4, h - 12), tealStripePaint);

    // 7. Windshield & Windows
    // Front Windshield
    final frontWindshield = Path()
      ..moveTo(8, 20)
      ..lineTo(w - 8, 20)
      ..lineTo(w - 10, 32)
      ..lineTo(10, 32)
      ..close();
    canvas.drawPath(frontWindshield, windshieldPaint);

    // Side windows
    canvas.drawRect(Rect.fromLTWH(5, 36, 4, 18), windshieldPaint);
    canvas.drawRect(Rect.fromLTWH(w - 9, 36, 4, 18), windshieldPaint);

    // Rear Window
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(10, h - 14, w - 20, 6), const Radius.circular(2)),
      rearWindowPaint,
    );

    // Front Hood Text: "RSIA"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'RSIA',
        style: TextStyle(
          color: Color(0xFF00A896),
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((w - textPainter.width) / 2, 8));

    // 8. RSIA Official Logo Emblem on the roof
    final centerX = w / 2;
    final centerY = h * 0.58;

    if (rsiaLogoImage != null) {
      const emblemRadius = 14.0;

      // Circular white emblem background with subtle drop shadow
      final emblemBgPaint = Paint()..color = const Color(0xFFFFFFFF);
      final emblemBorderPaint = Paint()
        ..color = const Color(0xFF00A896)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.drawCircle(Offset(centerX, centerY), emblemRadius, emblemBgPaint);
      canvas.drawCircle(Offset(centerX, centerY), emblemRadius, emblemBorderPaint);

      // Clip circle and draw RSIA logo
      canvas.save();
      final clipPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: emblemRadius - 1.2));
      canvas.clipPath(clipPath);

      final srcRect = Rect.fromLTWH(
        0,
        0,
        rsiaLogoImage!.width.toDouble(),
        rsiaLogoImage!.height.toDouble(),
      );
      final dstRect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: emblemRadius - 1.2,
      );
      canvas.drawImageRect(
        rsiaLogoImage!,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    } else {
      // Fallback Medical Red Cross
      const crossThickness = 5.0;
      const crossArm = 16.0;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(centerX, centerY), width: crossArm, height: crossThickness),
        redCrossPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(centerX, centerY), width: crossThickness, height: crossArm),
        redCrossPaint,
      );
    }

    // 9. Siren Bar on roof (front top)
    final sirenY = 14.0;
    final sirenBarW = 24.0;
    final sirenBarH = 6.0;
    final sirenStartX = (w - sirenBarW) / 2;

    // Siren mount bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(sirenStartX, sirenY, sirenBarW, sirenBarH),
        const Radius.circular(2),
      ),
      bumperPaint,
    );

    // Strobing lights: Alternating Red (Left) and Blue (Right)
    final isRedActive = sin(sirenTimer * 20) > 0;
    final leftSirenPaint = isRedActive ? sirenRedPaint : Paint()..color = const Color(0x66FF1744);
    final rightSirenPaint = !isRedActive ? sirenBluePaint : Paint()..color = const Color(0x662979FF);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(sirenStartX + 1, sirenY + 1, 10, 4), const Radius.circular(1.5)),
      leftSirenPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(sirenStartX + 13, sirenY + 1, 10, 4), const Radius.circular(1.5)),
      rightSirenPaint,
    );

    // Strobing halo aura
    if (isSirenBoostActive || true) {
      final glowPaint = Paint()
        ..color = isRedActive ? const Color(0x33FF1744) : const Color(0x332979FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(centerX, sirenY + 3), 16, glowPaint);
    }

    // 10. Siren Boost Aura (Golden / Cyan shield when boost is active)
    if (isSirenBoostActive) {
      final shieldPaint = Paint()
        ..color = const Color(0x5500E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-6, -6, w + 12, h + 12), const Radius.circular(16)),
        shieldPaint,
      );
    }

    canvas.restore();
  }

  void _drawHeadlights(Canvas canvas, double w, double h) {
    // Left beam
    final leftBeam = Path()
      ..moveTo(6, 4)
      ..lineTo(-18, -110)
      ..lineTo(14, -110)
      ..close();
    canvas.drawPath(leftBeam, headlightPaint);

    // Right beam
    final rightBeam = Path()
      ..moveTo(w - 6, 4)
      ..lineTo(w - 14, -110)
      ..lineTo(w + 18, -110)
      ..close();
    canvas.drawPath(rightBeam, headlightPaint);
  }
}
