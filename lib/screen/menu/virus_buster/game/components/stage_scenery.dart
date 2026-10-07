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

    // Kecepatan parallax backdrop
    final currentScroll = scrollOffset * 0.7;

    // Hitung index tile dasar secara presisi
    final int baseTileIndex = (currentScroll / scaledImgW).floor();
    final double startX = (baseTileIndex * scaledImgW) - currentScroll;

    final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
    final paint = Paint()..filterQuality = FilterQuality.medium;

    // Gambar tile dengan alternating mirror horisontal agar looping 100% seamless tanpa garis terpotong
    for (int i = 0; i < 4; i++) {
      final tileIndex = baseTileIndex + i;
      final tileX = startX + (i * scaledImgW);

      if (tileX > screenW + 10) break;
      if (tileX + scaledImgW < -10) continue;

      final bool isFlipped = tileIndex % 2 != 0;

      canvas.save();
      if (isFlipped) {
        // Tile ganjil di-flip horisontal: tepi kanan bertemu tepi kanan secara kontinu
        canvas.translate(tileX + scaledImgW, 0);
        canvas.scale(-1, 1);
        canvas.drawImageRect(
          img,
          srcRect,
          Rect.fromLTWH(0, 0, scaledImgW, screenH),
          paint,
        );
      } else {
        // Tile genap digambar normal
        canvas.translate(tileX, 0);
        canvas.drawImageRect(
          img,
          srcRect,
          Rect.fromLTWH(0, 0, scaledImgW, screenH),
          paint,
        );
      }
      canvas.restore();
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
