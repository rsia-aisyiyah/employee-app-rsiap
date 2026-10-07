import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class StageScenery extends PositionComponent with HasGameRef {
  final int stageNumber;
  final double groundY;
  double scrollOffset = 0.0;

  ui.Image? _backdropImage;
  bool _isLoading = true;

  StageScenery({
    required this.stageNumber,
    required this.groundY,
  }) : super(priority: -10);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await _loadBackdrop();
  }

  Future<void> _loadBackdrop() async {
    String assetPath;
    switch (stageNumber) {
      case 1:
        assetPath = 'assets/images/virus_buster/stage1_ugd.jpg';
        break;
      case 2:
        assetPath = 'assets/images/virus_buster/stage2_lobi.jpg';
        break;
      case 3:
      default:
        assetPath = 'assets/images/virus_buster/stage3_nurse.jpg';
        break;
    }

    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _backdropImage = frame.image;
    } catch (_) {
      // Fallback graceful
    } finally {
      _isLoading = false;
    }
  }

  void scroll(double deltaX) {
    scrollOffset += deltaX;
  }

  @override
  void render(Canvas canvas) {
    final gameSize = gameRef.size;
    final w = gameSize.x;
    final h = gameSize.y;

    if (_backdropImage != null) {
      _renderImageBackdrop(canvas, w, h);
    } else {
      _renderFallbackBackdrop(canvas, w, h);
    }
  }

  void _renderImageBackdrop(Canvas canvas, double screenW, double screenH) {
    final img = _backdropImage!;
    final imgW = img.width.toDouble();
    final imgH = img.height.toDouble();

    // Gambar di-scale agar tingginya pas dengan tinggi layar
    final scale = screenH / imgH;
    final scaledImgW = imgW * scale;

    // Hitung posisi horizontal dengan scrolling parallax loop
    final currentScroll = scrollOffset * 0.7; // Kecepatan parallax backdrop
    final double normalizedOffset = currentScroll % scaledImgW;

    // Draw tile 1 & tile 2 bersebelahan agar looping seamless tanpa celah
    final double x1 = -normalizedOffset;
    final double x2 = x1 + scaledImgW;

    final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);

    final paint = Paint()..filterQuality = FilterQuality.medium;

    // Tile 1
    canvas.drawImageRect(
      img,
      srcRect,
      Rect.fromLTWH(x1, 0, scaledImgW, screenH),
      paint,
    );

    // Tile 2 (jika tile 1 bergeser ke kiri)
    if (x2 < screenW + 10) {
      canvas.drawImageRect(
        img,
        srcRect,
        Rect.fromLTWH(x2, 0, scaledImgW, screenH),
        paint,
      );
    }

    // Tile 3 (penjaga jika rasio layar sangat lebar)
    final double x3 = x2 + scaledImgW;
    if (x3 < screenW + 10) {
      canvas.drawImageRect(
        img,
        srcRect,
        Rect.fromLTWH(x3, 0, scaledImgW, screenH),
        paint,
      );
    }
  }

  void _renderFallbackBackdrop(Canvas canvas, double w, double h) {
    // Background gradient elegan rumah sakit jika gambar sedang dimuat
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: stageNumber == 1
            ? [const Color(0xFFBAE6FD), const Color(0xFFFEF3C7)]
            : (stageNumber == 2
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFF064E3B), const Color(0xFF0F766E)]),
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Lantai dasar
    final floorPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), floorPaint);
  }
}
