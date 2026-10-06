import 'dart:ui';
import 'package:flame/components.dart';

class RoadBackground extends Component with HasGameRef {
  double scrollOffset = 0.0;
  double curbOffset = 0.0;

  // Road geometry computed dynamically based on gameRef size
  double roadWidth = 0.0;
  double roadStartX = 0.0;
  double laneWidth = 0.0;

  final Paint asphaltPaint = Paint()..color = const Color(0xFF1E242B);
  final Paint shoulderPaint = Paint()..color = const Color(0xFF111418);
  final Paint curbRedPaint = Paint()..color = const Color(0xFFE53935);
  final Paint curbWhitePaint = Paint()..color = const Color(0xFFF5F5F5);
  final Paint laneDashPaint = Paint()
    ..color = const Color(0xCCFFD54F) // Amber-gold dashed lines
    ..strokeWidth = 3.5
    ..style = PaintingStyle.stroke;
  final Paint roadEdgePaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = 4.0
    ..style = PaintingStyle.stroke;

  @override
  void update(double dt) {
    super.update(dt);
    // Road speed is updated by the main game loop
  }

  void updateScroll(double deltaSpeed) {
    scrollOffset = (scrollOffset + deltaSpeed) % 80.0;
    curbOffset = (curbOffset + deltaSpeed) % 40.0;
  }

  void updateDimensions(Vector2 screenSize) {
    // Road occupies around 82% of screen width on phones, capped at 380px on tablets
    roadWidth = (screenSize.x * 0.88).clamp(260.0, 420.0);
    roadStartX = (screenSize.x - roadWidth) / 2;
    laneWidth = roadWidth / 3;
  }

  @override
  void render(Canvas canvas) {
    final screenSize = (gameRef as dynamic).size as Vector2;
    updateDimensions(screenSize);

    final height = screenSize.y;
    final width = screenSize.x;

    // 1. Draw outer shoulder/grass
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), shoulderPaint);

    // 2. Draw asphalt roadway
    canvas.drawRect(Rect.fromLTWH(roadStartX, 0, roadWidth, height), asphaltPaint);

    // 3. Draw Red/White Curbs on left and right borders (retro arcade feel)
    const curbWidth = 10.0;
    const curbBlockH = 20.0;
    final numCurbs = (height / curbBlockH).ceil() + 2;

    for (int i = -1; i < numCurbs; i++) {
      final y = (i * curbBlockH) + curbOffset;
      final paint = (i % 2 == 0) ? curbRedPaint : curbWhitePaint;

      // Left curb
      canvas.drawRect(
        Rect.fromLTWH(roadStartX - curbWidth, y, curbWidth, curbBlockH),
        paint,
      );
      // Right curb
      canvas.drawRect(
        Rect.fromLTWH(roadStartX + roadWidth, y, curbWidth, curbBlockH),
        paint,
      );
    }

    // 4. Solid white edge lines
    canvas.drawLine(
      Offset(roadStartX, 0),
      Offset(roadStartX, height),
      roadEdgePaint,
    );
    canvas.drawLine(
      Offset(roadStartX + roadWidth, 0),
      Offset(roadStartX + roadWidth, height),
      roadEdgePaint,
    );

    // 5. Dashed lines separating the 3 lanes
    const dashLength = 32.0;
    const dashSpace = 24.0;
    final totalCycle = dashLength + dashSpace;
    final numDashes = (height / totalCycle).ceil() + 2;

    for (int laneDivider = 1; laneDivider <= 2; laneDivider++) {
      final lineX = roadStartX + (laneDivider * laneWidth);

      for (int i = -1; i < numDashes; i++) {
        final startY = (i * totalCycle) + scrollOffset;
        final endY = startY + dashLength;

        if (endY > 0 && startY < height) {
          canvas.drawLine(
            Offset(lineX, startY),
            Offset(lineX, endY),
            laneDashPaint,
          );
        }
      }
    }
  }
}
