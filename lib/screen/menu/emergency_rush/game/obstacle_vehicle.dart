import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/game/lane_config.dart';

enum ObstacleType {
  sedanRed,
  sedanBlue,
  truckBox,
  taxiYellow,
  trafficCone,
}

class ObstacleVehicle extends PositionComponent with HasGameRef, CollisionCallbacks {
  final ObstacleType type;
  final Lane lane;
  final double vehicleBaseSpeed; // Some vehicles move forward slightly, cones are stationary

  late RectangleHitbox hitbox;

  // Visual Paints
  late Paint bodyPaint;
  final Paint windshieldPaint = Paint()..color = const Color(0xFF212121);
  final Paint tirePaint = Paint()..color = const Color(0xFF263238);
  final Paint lightPaint = Paint()..color = const Color(0xFFFFD54F);
  final Paint taillightPaint = Paint()..color = const Color(0xFFD32F2F);

  ObstacleVehicle({
    required this.type,
    required this.lane,
    required Vector2 initialPosition,
    this.vehicleBaseSpeed = 0.0,
  }) : super(
          position: initialPosition,
          size: _getSizeForType(type),
          anchor: Anchor.center,
        );

  static Vector2 _getSizeForType(ObstacleType type) {
    switch (type) {
      case ObstacleType.truckBox:
        return Vector2(52, 116);
      case ObstacleType.trafficCone:
        return Vector2(36, 36);
      case ObstacleType.sedanRed:
      case ObstacleType.sedanBlue:
      case ObstacleType.taxiYellow:
        return Vector2(48, 84);
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Assign type color
    switch (type) {
      case ObstacleType.sedanRed:
        bodyPaint = Paint()..color = const Color(0xFFE53935);
        break;
      case ObstacleType.sedanBlue:
        bodyPaint = Paint()..color = const Color(0xFF1E88E5);
        break;
      case ObstacleType.taxiYellow:
        bodyPaint = Paint()..color = const Color(0xFFFBC02D);
        break;
      case ObstacleType.truckBox:
        bodyPaint = Paint()..color = const Color(0xFF546E7A);
        break;
      case ObstacleType.trafficCone:
        bodyPaint = Paint()..color = const Color(0xFFFF6D00);
        break;
    }

    // Precise hitbox for arcade fairness
    hitbox = RectangleHitbox(
      size: Vector2(size.x * 0.78, size.y * 0.82),
      position: Vector2(size.x * 0.11, size.y * 0.09),
    );
    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // If beyond screen bottom, remove safely
    final screenSize = (gameRef as dynamic).size as Vector2;
    if (position.y > screenSize.y + 120) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    if (type == ObstacleType.trafficCone) {
      _renderCone(canvas, w, h);
      return;
    }

    if (type == ObstacleType.truckBox) {
      _renderTruck(canvas, w, h);
      return;
    }

    // Default: Sedan / Taxi Car
    _renderCar(canvas, w, h);
  }

  void _renderCar(Canvas canvas, double w, double h) {
    // 4 Tires
    const tireW = 5.0;
    const tireH = 15.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-2, 12, tireW, tireH), const Radius.circular(2)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 3, 12, tireW, tireH), const Radius.circular(2)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-2, h - 24, tireW, tireH), const Radius.circular(2)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 3, h - 24, tireW, tireH), const Radius.circular(2)), tirePaint);

    // Car Body
    final bodyRRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(10));
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Front Windshield
    final windshield = Path()
      ..moveTo(6, 20)
      ..lineTo(w - 6, 20)
      ..lineTo(w - 9, 32)
      ..lineTo(9, 32)
      ..close();
    canvas.drawPath(windshield, windshieldPaint);

    // Roof
    final roofPaint = Paint()..color = const Color(0x33000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(7, 34, w - 14, 22), const Radius.circular(4)),
      roofPaint,
    );

    // Taxi sign if yellow
    if (type == ObstacleType.taxiYellow) {
      final taxiSign = Paint()..color = const Color(0xFF212121);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w / 2, 45), width: 18, height: 6), const Radius.circular(2)),
        taxiSign,
      );
    }

    // Rear Window
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, h - 18, w - 16, 6), const Radius.circular(2)),
      windshieldPaint,
    );

    // Taillights
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, h - 3, 8, 3), const Radius.circular(1)), taillightPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 12, h - 3, 8, 3), const Radius.circular(1)), taillightPaint);
  }

  void _renderTruck(Canvas canvas, double w, double h) {
    // Truck Cabin (front)
    final cabinPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2, 0, w - 4, 34), const Radius.circular(6)),
      cabinPaint,
    );

    // Cabin Windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(6, 6, w - 12, 10), const Radius.circular(2)),
      windshieldPaint,
    );

    // Cargo Box Container (rear)
    final boxPaint = Paint()..color = const Color(0xFFCFD8DC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 36, w, h - 36), const Radius.circular(4)),
      boxPaint,
    );

    // Container stripe detail
    final linePaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, 56), Offset(w, 56), linePaint);
    canvas.drawLine(Offset(0, 76), Offset(w, 76), linePaint);
    canvas.drawLine(Offset(0, 96), Offset(w, 96), linePaint);

    // Rear Taillights
    canvas.drawRect(Rect.fromLTWH(2, h - 4, 10, 4), taillightPaint);
    canvas.drawRect(Rect.fromLTWH(w - 12, h - 4, 10, 4), taillightPaint);
  }

  void _renderCone(Canvas canvas, double w, double h) {
    final coneBasePaint = Paint()..color = const Color(0xFF212121);
    final coneOrangePaint = Paint()..color = const Color(0xFFFF5722);
    final coneWhitePaint = Paint()..color = const Color(0xFFFFFFFF);

    // Square rubber base
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3, 3, w - 6, h - 6), const Radius.circular(4)),
      coneBasePaint,
    );

    // Concentric circles representing cone from top-down
    canvas.drawCircle(Offset(w / 2, h / 2), 12, coneOrangePaint);
    canvas.drawCircle(Offset(w / 2, h / 2), 8, coneWhitePaint);
    canvas.drawCircle(Offset(w / 2, h / 2), 4, coneOrangePaint);
  }
}
