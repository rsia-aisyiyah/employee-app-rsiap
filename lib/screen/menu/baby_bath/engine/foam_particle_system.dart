import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/baby_bath_models.dart';

/// Sistem Simulasi Fisika Busa Sabun & Percikan Air (Fluid & Foam Engine)
class FoamParticleSystem {
  final List<FoamBubble> bubbles = [];
  final List<WaterSplashParticle> splashes = [];
  final math.Random _random = math.Random();

  static const int maxBubbles = 45;
  static const int maxSplashes = 35;

  /// Menambahkan busa sabun di posisi sentuhan (scrubbing)
  void spawnFoam(double x, double y, {int count = 3}) {
    for (int i = 0; i < count; i++) {
      if (bubbles.length >= maxBubbles) {
        bubbles.removeAt(0);
      }

      final offsetX = (_random.nextDouble() - 0.5) * 36;
      final offsetY = (_random.nextDouble() - 0.5) * 36;
      final radius = 7.0 + _random.nextDouble() * 11.0;

      final colors = [
        Colors.white.withValues(alpha: 0.90),
        const Color(0xFFE0F2FE).withValues(alpha: 0.85),
        const Color(0xFFF0FDF4).withValues(alpha: 0.85),
        const Color(0xFFFEF3C7).withValues(alpha: 0.80),
      ];

      bubbles.add(
        FoamBubble(
          x: x + offsetX,
          y: y + offsetY,
          radius: radius,
          alpha: 0.88,
          vx: (_random.nextDouble() - 0.5) * 0.4,
          vy: -0.2 - _random.nextDouble() * 0.3,
          color: colors[_random.nextInt(colors.length)],
        ),
      );
    }
  }

  /// Menambahkan percikan air dari shower atau tepukan bebek
  void spawnWaterSplash(double x, double y, {int count = 6, double force = 2.5}) {
    for (int i = 0; i < count; i++) {
      if (splashes.length >= maxSplashes) {
        splashes.removeAt(0);
      }

      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 1.0 + _random.nextDouble() * force;

      splashes.add(
        WaterSplashParticle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 1.2, // sedikut gravitasi ke atas lalu jatuh
          radius: 2.5 + _random.nextDouble() * 3.5,
          alpha: 0.80,
          color: const Color(0xFF38BDF8).withValues(alpha: 0.70),
        ),
      );
    }
  }

  /// Bilas busa di dekat area semprotan shower
  int rinseNear(double x, double y, double radius) {
    int removed = 0;
    bubbles.removeWhere((bubble) {
      final dist = math.sqrt(math.pow(bubble.x - x, 2) + math.pow(bubble.y - y, 2));
      if (dist <= radius) {
        removed++;
        return true;
      }
      return false;
    });

    if (removed > 0) {
      spawnWaterSplash(x, y, count: 4, force: 1.8);
    }
    return removed;
  }

  /// Update simulasi partikel per frame
  void update(double dt) {
    // 1. Update Busa
    for (int i = bubbles.length - 1; i >= 0; i--) {
      final b = bubbles[i];
      b.x += b.vx;
      b.y += b.vy;
      b.alpha -= dt * 0.04; // Perlahan memudar

      if (b.alpha <= 0.1 || b.y < 0) {
        bubbles.removeAt(i);
      }
    }

    // 2. Update Percikan Air
    for (int i = splashes.length - 1; i >= 0; i--) {
      final s = splashes[i];
      s.x += s.vx;
      s.y += s.vy;
      s.vy += 3.8 * dt; // Gravitasi air jatuh
      s.alpha -= dt * 1.4;

      if (s.alpha <= 0.05) {
        splashes.removeAt(i);
      }
    }
  }

  /// Hapus semua partikel
  void clear() {
    bubbles.clear;
    splashes.clear;
  }
}
