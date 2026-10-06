import 'dart:math';
import 'package:flutter/material.dart';

class TtsConfettiWidget extends StatefulWidget {
  final Widget child;
  final bool play;

  const TtsConfettiWidget({
    super.key,
    required this.child,
    this.play = false,
  });

  @override
  State<TtsConfettiWidget> createState() => _TtsConfettiWidgetState();
}

class _TtsConfettiWidgetState extends State<TtsConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addListener(() {
        for (var p in _particles) {
          p.update();
        }
        setState(() {});
      });

    if (widget.play) {
      _startConfetti();
    }
  }

  @override
  void didUpdateWidget(covariant TtsConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _particles.clear();
    const colors = [
      Color(0xFF3BC8ED), // RSIA Blue
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber Gold
      Color(0xFFEC4899), // Pink
      Color(0xFF8B5CF6), // Purple
      Color(0xFF06B6D4), // Cyan
    ];

    for (int i = 0; i < 90; i++) {
      _particles.add(
        _ConfettiParticle(
          x: 0.1 + _rnd.nextDouble() * 0.8,
          y: -0.1 - _rnd.nextDouble() * 0.3,
          vx: (_rnd.nextDouble() - 0.5) * 0.012,
          vy: 0.006 + _rnd.nextDouble() * 0.016,
          size: 6.0 + _rnd.nextDouble() * 8.0,
          color: colors[_rnd.nextInt(colors.length)],
          rotation: _rnd.nextDouble() * 2 * pi,
          rotationSpeed: (_rnd.nextDouble() - 0.5) * 0.2,
          isCircle: _rnd.nextBool(),
        ),
      );
    }
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(particles: _particles),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.0003; // gravity
    rotation += rotationSpeed;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      if (p.y > 1.2 || p.y < -0.3) continue;

      final paint = Paint()..color = p.color;
      final px = p.x * size.width;
      final py = p.y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
