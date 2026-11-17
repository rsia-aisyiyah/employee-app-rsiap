import 'package:flutter/material.dart';
import 'engine/baby_bath_controller.dart';
import 'engine/baby_character_painter.dart';
import 'widgets/baby_bath_hud.dart';
import 'widgets/bath_tool_palette.dart';
import 'widgets/baby_bath_complete_dialog.dart';

/// Layar Gameplay Interaktif Memandikan Bayi RSIA
class BabyBathGameScreen extends StatefulWidget {
  const BabyBathGameScreen({super.key});

  @override
  State<BabyBathGameScreen> createState() => _BabyBathGameScreenState();
}

class _BabyBathGameScreenState extends State<BabyBathGameScreen>
    with SingleTickerProviderStateMixin {
  late final BabyBathController _controller;
  late final AnimationController _animController;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _controller = BabyBathController();
    _controller.start();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _controller.addListener(_checkCompletion);
  }

  void _checkCompletion() {
    if (_controller.isCompleted && !_dialogShown && mounted) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => BabyBathCompleteDialog(
          controller: _controller,
          onPlayAgain: () {
            Navigator.pop(context);
            _dialogShown = false;
            _controller.restart();
          },
          onExit: () {
            Navigator.pop(context); // pop dialog
            Navigator.pop(context); // pop screen
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkCompletion);
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Stack(
        children: [
          // ── 1. Area Canvas Interaktif Mandi Bayi ──
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    _controller.onTouch(details.localPosition, screenSize);
                  },
                  onTapDown: (details) {
                    _controller.onTouch(details.localPosition, screenSize);
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_controller, _animController]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: BabyCharacterPainter(
                          phase: _controller.phase,
                          mood: _controller.mood,
                          animationTime: _animController.value * 10.0,
                          particleSystem: _controller.particleSystem,
                          cleanlinessProgress: _controller.cleanlinessProgress,
                          waterLevel: _controller.waterLevel,
                          waterTemp: _controller.waterTemp,
                          duckPosition: _controller.duckPosition,
                          isDuckSqueaking: _controller.isDuckSqueaking,
                          floatingToasts: _controller.floatingToasts,
                          isBabyInCrib: _controller.isBabyInCrib,
                          babyName: _controller.currentBaby.motherName,
                          swaddleColor: _controller.currentBaby.swaddleColor,
                        ),
                        child: Container(),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // ── 2. HUD Atas (Suhu Air, Meter Kebersihan & Kenyamanan) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return BabyBathHud(
                  controller: _controller,
                  onExit: () => Navigator.pop(context),
                );
              },
            ),
          ),

          // ── 3. Palet Alat Mandi di Bawah ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return BathToolPalette(controller: _controller);
              },
            ),
          ),
        ],
      ),
    );
  }
}
