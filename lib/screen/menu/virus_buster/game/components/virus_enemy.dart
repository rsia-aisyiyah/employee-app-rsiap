import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/bullet.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/player_doctor.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/models/virus_buster_models.dart';

class VirusEnemy extends PositionComponent with HasGameRef, CollisionCallbacks {
  final VirusType type;
  final double moveSpeed;
  final double initialGroundY;
  int currentHp;
  final int maxHp;

  double animTimer = 0.0;
  double hitFlashTimer = 0.0;

  // Gerakan khusus
  double bounceBaseY = 0.0;
  double bouncePhase = 0.0;
  bool hasEnteredScreen = false;
  double bossAttackTimer = 0.0;

  final void Function(VirusEnemy enemy, int scoreAwarded)? onDefeated;
  final void Function(PlayerDoctor player)? onHitPlayer;

  late CircleHitbox hitbox;

  VirusEnemy({
    required this.type,
    required Vector2 position,
    required this.initialGroundY,
    this.moveSpeed = 90.0,
    this.onDefeated,
    this.onHitPlayer,
  })  : maxHp = _calcMaxHp(type),
        currentHp = _calcMaxHp(type),
        super(
          position: position,
          size: _calcSize(type),
          anchor: Anchor.center,
        ) {
    bounceBaseY = position.y;
    bouncePhase = Random().nextDouble() * pi * 2;
  }

  bool get isBoss =>
      type == VirusType.bossMega ||
      type == VirusType.bossStage1 ||
      type == VirusType.bossStage2 ||
      type == VirusType.bossStage3;

  static int _calcMaxHp(VirusType type) {
    switch (type) {
      case VirusType.fluGoo:
      case VirusType.dustMite:
      case VirusType.mosquito:
      case VirusType.toxicDroplet:
        return 1;
      case VirusType.spikeCorona:
      case VirusType.bacillus:
      case VirusType.fungalSpore:
        return 2;
      case VirusType.superbugMrsa:
      case VirusType.shadowPathogen:
        return 3;
      case VirusType.bossStage1:
        return 14;
      case VirusType.bossStage2:
        return 20;
      case VirusType.bossStage3:
      case VirusType.bossMega:
        return 26;
    }
  }

  static Vector2 _calcSize(VirusType type) {
    switch (type) {
      case VirusType.fluGoo:
        return Vector2(68, 59);
      case VirusType.dustMite:
        return Vector2(65, 57);
      case VirusType.mosquito:
        return Vector2(65, 51);
      case VirusType.spikeCorona:
        return Vector2(78, 78);
      case VirusType.bacillus:
        return Vector2(76, 49);
      case VirusType.toxicDroplet:
        return Vector2(59, 65);
      case VirusType.superbugMrsa:
        return Vector2(84, 76);
      case VirusType.fungalSpore:
        return Vector2(76, 76);
      case VirusType.shadowPathogen:
        return Vector2(73, 59);
      case VirusType.bossStage1:
        return Vector2(148, 148);
      case VirusType.bossStage2:
        return Vector2(162, 162);
      case VirusType.bossStage3:
      case VirusType.bossMega:
        return Vector2(178, 178);
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    hitbox = CircleHitbox(radius: size.x * 0.45, position: Vector2(size.x * 0.05, size.y * 0.05));
    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    animTimer += dt * 6;

    if (hitFlashTimer > 0) {
      hitFlashTimer -= dt;
    }

    // Gerakan Musuh
    if (isBoss) {
      // Pertarungan Boss: masuk ke layar dan melayang nyaman di posisi on-screen
      final double arenaTargetX = min(gameRef.size.x * 0.72, gameRef.size.x - 110);
      if (!hasEnteredScreen) {
        position.x -= 140 * dt;
        if (position.x <= arenaTargetX) {
          position.x = arenaTargetX;
          hasEnteredScreen = true;
        }
      } else {
        // Berada di on-screen arena yang nyaman dan dinamis
        position.x = arenaTargetX + sin(animTimer * 0.7) * 18;
        position.y = bounceBaseY + sin(animTimer * 1.4) * 26;

        // Serangan Kekuatan Boss ke Arah Player!
        _handleBossAttack(dt);
      }
    } else {
      switch (type) {
        case VirusType.fluGoo:
          // Slime merayap di tanah
          position.x -= moveSpeed * dt;
          position.y = initialGroundY - (size.y / 2);
          break;

        case VirusType.dustMite:
          // Partikel alergen debu melayang zigzag
          position.x -= moveSpeed * dt;
          position.y = bounceBaseY + sin(animTimer * 2.2) * 18;
          break;

        case VirusType.mosquito:
          // Nyamuk Aedes terbang menukik cepat
          position.x -= (moveSpeed + 35) * dt;
          position.y = bounceBaseY + cos(animTimer * 1.8) * 32;
          break;

        case VirusType.spikeCorona:
          // Corona berputar melayang bergelombang
          position.x -= moveSpeed * dt;
          position.y = bounceBaseY + sin(animTimer + bouncePhase) * 35;
          break;

        case VirusType.bacillus:
          // Bakteri batang meloncat-loncat di darat
          position.x -= (moveSpeed + 15) * dt;
          position.y = initialGroundY - (size.y / 2) - (sin(animTimer * 2.6).abs() * 22);
          break;

        case VirusType.toxicDroplet:
          // Tetesan batuk meluncur diagonal
          position.x -= (moveSpeed + 30) * dt;
          position.y = bounceBaseY + sin(animTimer * 1.3) * 28;
          break;

        case VirusType.superbugMrsa:
          // Bakteri lapis baja bergerak mantap di tanah
          position.x -= (moveSpeed - 12) * dt;
          position.y = initialGroundY - (size.y / 2);
          break;

        case VirusType.fungalSpore:
          // Spora jamur melayang berayun
          position.x -= (moveSpeed - 5) * dt;
          position.y = bounceBaseY + sin(animTimer * 1.1) * 36;
          break;

        case VirusType.shadowPathogen:
          // Patogen bayangan melesat cepat
          position.x -= (moveSpeed + 45) * dt;
          position.y = bounceBaseY + cos(animTimer * 2.6) * 26;
          break;

        default:
          position.x -= moveSpeed * dt;
          break;
      }
    }

    // Keluar layar ke kiri
    if (position.x < -100) {
      removeFromParent();
    }
  }

  /// Serangan kekuatan Boss sesuai jenis Virus / Tahapan Stage
  void _handleBossAttack(double dt) {
    bossAttackTimer += dt;

    switch (type) {
      case VirusType.bossStage1:
        // STAGE 1 BOSS (Titan Flu Goo):
        // Memuntahkan bola lendir beracun kuning keemasan tiap 2.8 detik
        if (bossAttackTimer >= 2.8) {
          bossAttackTimer = 0.0;
          final proj = VirusProjectile(
            startPosition: Vector2(position.x - size.x * 0.45, position.y + 12),
            speed: 185.0,
            directionX: -1.0,
            directionY: 0.0,
            radius: 13.0,
            coreColor: const Color(0xFFEAB308),
            glowColor: const Color(0x66EAB308),
            onHitPlayer: (player) => onHitPlayer?.call(player),
          );
          gameRef.add(proj);
        }
        break;

      case VirusType.bossStage2:
        // STAGE 2 BOSS (Apex Delta Corona):
        // Menyemburkan duri spike tajam merah membara tiap 2.5 detik!
        // - Duri Tengah: setinggi dada hero (BISA DIHINDARI DENGAN JONGKOK!)
        // - Duri Atas: melengkung ke atas
        if (bossAttackTimer >= 2.5) {
          bossAttackTimer = 0.0;

          // 1. Duri Tengah (Bisa dihindari dengan menekan tombol JONGKOK!)
          final projMid = VirusProjectile(
            startPosition: Vector2(position.x - size.x * 0.45, position.y + 4),
            speed: 215.0,
            directionX: -1.0,
            directionY: 0.0,
            radius: 14.0,
            coreColor: const Color(0xFFEF4444),
            glowColor: const Color(0x66EF4444),
            onHitPlayer: (player) => onHitPlayer?.call(player),
          );
          gameRef.add(projMid);

          // 2. Duri Atas (Melengkung ke atas)
          final projHigh = VirusProjectile(
            startPosition: Vector2(position.x - size.x * 0.45, position.y - 28),
            speed: 195.0,
            directionX: -1.0,
            directionY: -0.16,
            radius: 12.0,
            coreColor: const Color(0xFFDC2626),
            glowColor: const Color(0x66DC2626),
            onHitPlayer: (player) => onHitPlayer?.call(player),
          );
          gameRef.add(projHigh);
        }
        break;

      case VirusType.bossStage3:
      case VirusType.bossMega:
        // STAGE 3 FINAL BOSS (Superbug Chimera):
        // Semburan 3 spora mematikan ungu tiap 2.1 detik!
        if (bossAttackTimer >= 2.1) {
          bossAttackTimer = 0.0;
          const spreads = [-0.22, 0.0, 0.22];
          for (final dirY in spreads) {
            final proj = VirusProjectile(
              startPosition: Vector2(position.x - size.x * 0.45, position.y),
              speed: 225.0,
              directionX: -1.0,
              directionY: dirY,
              radius: 13.0,
              coreColor: const Color(0xFFA855F7),
              glowColor: const Color(0x66A855F7),
              onHitPlayer: (player) => onHitPlayer?.call(player),
            );
            gameRef.add(proj);
          }
        }
        break;

      default:
        break;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is AntisepticBullet) {
      other.removeFromParent();
      takeDamage(1);
    } else if (other is PlayerDoctor) {
      if (other.isShieldActive) {
        // Pelindung APD aktif: langsung hancurkan musuh
        takeDamage(currentHp);
      } else {
        // Mario Stomp: musuh darat bisa diinjak saat dokter melompat turun
        final bool isGroundEnemy = type == VirusType.fluGoo ||
            type == VirusType.superbugMrsa ||
            type == VirusType.bacillus;

        if (isGroundEnemy && other.velocityY > 0 && other.position.y <= position.y + 10) {
          takeDamage(2);
          other.bounceAfterStomp();
        } else {
          onHitPlayer?.call(other);
        }
      }
    }
  }

  void takeDamage(int damage) {
    currentHp -= damage;
    hitFlashTimer = 0.12;

    if (currentHp <= 0) {
      int score;
      if (isBoss) {
        if (type == VirusType.bossStage3 || type == VirusType.bossMega) {
          score = 350;
        } else if (type == VirusType.bossStage2) {
          score = 300;
        } else {
          score = 250;
        }
      } else {
        if (type == VirusType.superbugMrsa) {
          score = 50;
        } else if (type == VirusType.spikeCorona || type == VirusType.bacillus) {
          score = 35;
        } else {
          score = 25;
        }
      }

      onDefeated?.call(this, score);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // Skala 1.85x agar proporsional dan gagah di latar belakang rumah sakit
    const double enemyScale = 1.85;
    canvas.scale(enemyScale, enemyScale);

    final bool isFlash = hitFlashTimer > 0;

    switch (type) {
      // Stage 1
      case VirusType.fluGoo:
        _drawFluGoo(canvas, isFlash);
        break;
      case VirusType.dustMite:
        _drawDustMite(canvas, isFlash);
        break;
      case VirusType.mosquito:
        _drawMosquito(canvas, isFlash);
        break;
      case VirusType.bossStage1:
        _drawBossStage1(canvas, isFlash);
        break;

      // Stage 2
      case VirusType.spikeCorona:
        _drawSpikeCorona(canvas, isFlash);
        break;
      case VirusType.bacillus:
        _drawBacillus(canvas, isFlash);
        break;
      case VirusType.toxicDroplet:
        _drawToxicDroplet(canvas, isFlash);
        break;
      case VirusType.bossStage2:
        _drawBossStage2(canvas, isFlash);
        break;

      // Stage 3
      case VirusType.superbugMrsa:
        _drawSuperbugMrsa(canvas, isFlash);
        break;
      case VirusType.fungalSpore:
        _drawFungalSpore(canvas, isFlash);
        break;
      case VirusType.shadowPathogen:
        _drawShadowPathogen(canvas, isFlash);
        break;
      case VirusType.bossStage3:
      case VirusType.bossMega:
        _drawBossStage3(canvas, isFlash);
        break;
    }

    // Gambar HP Bar jika Boss
    if (isBoss) {
      _drawBossHpBar(canvas);
    }

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 1 ENEMIES (DROP-OFF IGD & AREA LUAR)
  // ─────────────────────────────────────────────────────────────────────────────
  void _drawFluGoo(Canvas canvas, bool isFlash) {
    final wobble = sin(animTimer) * 2.5;
    final bodyPaint = Paint()
      ..color = isFlash ? Colors.white : const Color(0xFF22C55E); // Hijau lendir

    final path = Path();
    path.moveTo(-14, 12);
    path.quadraticBezierTo(-18 - wobble, -2, -10, -12);
    path.quadraticBezierTo(0, -16 + wobble, 10, -12);
    path.quadraticBezierTo(18 + wobble, -2, 14, 12);
    path.close();

    canvas.drawPath(path, bodyPaint);

    final eyeWhite = Paint()..color = Colors.white;
    final eyePupil = Paint()..color = const Color(0xFF0F172A);

    canvas.drawCircle(const Offset(-5, -4), 4, eyeWhite);
    canvas.drawCircle(const Offset(-6, -4), 2, eyePupil);
    canvas.drawCircle(const Offset(5, -4), 4, eyeWhite);
    canvas.drawCircle(const Offset(4, -4), 2, eyePupil);

    final browPaint = Paint()
      ..color = const Color(0xFF052E16)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(-8, -9), const Offset(-2, -7), browPaint);
    canvas.drawLine(const Offset(2, -7), const Offset(8, -9), browPaint);
  }

  void _drawDustMite(Canvas canvas, bool isFlash) {
    final twitch = sin(animTimer * 3) * 1.5;
    final bodyPaint = Paint()
      ..color = isFlash ? Colors.white : const Color(0xFFD97706); // Coklat-oranye alergen

    // Badan tungau bulat berkerut
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, twitch), width: 22, height: 18),
      bodyPaint,
    );

    // Kaki-kaki kecil di sisi
    final legPaint = Paint()
      ..color = isFlash ? Colors.white : const Color(0xFF92400E)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-8, 6), Offset(-13, 11 + twitch), legPaint);
    canvas.drawLine(const Offset(0, 8), Offset(0, 13 - twitch), legPaint);
    canvas.drawLine(const Offset(8, 6), Offset(13, 11 + twitch), legPaint);

    // Antena di depan
    canvas.drawLine(const Offset(-5, -8), Offset(-9, -13 + twitch), legPaint);
    canvas.drawLine(const Offset(5, -8), Offset(9, -13 - twitch), legPaint);

    // Mata bulat kecil
    canvas.drawCircle(const Offset(-4, -2), 2.2, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(4, -2), 2.2, Paint()..color = Colors.black);
  }

  void _drawMosquito(Canvas canvas, bool isFlash) {
    final wingFlap = sin(animTimer * 4) * 6;

    // Sayap Kiri & Kanan (Transparan)
    final wingPaint = Paint()..color = const Color(0x9993C5FD);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-10, -10 + wingFlap), width: 14, height: 6),
      wingPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-2, -12 - wingFlap), width: 14, height: 6),
      wingPaint,
    );

    // Badan serangga bergaris
    final bodyPaint = Paint()..color = isFlash ? Colors.white : const Color(0xFF475569);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 18, height: 11),
      bodyPaint,
    );

    // Garis loreng Aedes
    final stripePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(-2, -5), const Offset(-2, 5), stripePaint);
    canvas.drawLine(const Offset(3, -5), const Offset(3, 5), stripePaint);

    // Moncong runcing penusuk
    final proboscisPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-8, 2), const Offset(-17, 7), proboscisPaint);

    // Mata merah menyala
    canvas.drawCircle(const Offset(-5, -2), 2.5, Paint()..color = const Color(0xFFEF4444));
  }

  void _drawBossStage1(Canvas canvas, bool isFlash) {
    // Boss Titan Flu: Raksasa lendir kuning-keemasan dengan pendar oranye
    final spin = animTimer * 0.35;
    canvas.save();
    canvas.rotate(spin);

    const auraColor = Color(0x33FBBF24);
    canvas.drawCircle(Offset.zero, 42, Paint()..color = auraColor);

    // 8 Gelembung Lendir Luar
    for (int i = 0; i < 8; i++) {
      final angle = i * (pi / 4);
      final dx = cos(angle);
      final dy = sin(angle);

      final stemPaint = Paint()
        ..color = isFlash ? Colors.white : const Color(0xFFF59E0B)
        ..strokeWidth = 3.5;
      canvas.drawLine(Offset(dx * 22, dy * 22), Offset(dx * 34, dy * 34), stemPaint);
      canvas.drawCircle(
        Offset(dx * 35, dy * 35),
        6.0,
        Paint()..color = isFlash ? Colors.white : const Color(0xFFF97316),
      );
    }

    // Inti Monster
    canvas.drawCircle(
      Offset.zero,
      27,
      Paint()..color = isFlash ? Colors.white : const Color(0xFFEAB308),
    );
    canvas.restore();

    // Wajah jahat
    canvas.drawCircle(const Offset(-8, -5), 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(8, -5), 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(-8, -5), 2.5, Paint()..color = const Color(0xFF78350F));
    canvas.drawCircle(const Offset(8, -5), 2.5, Paint()..color = const Color(0xFF78350F));

    // Mulut lebar tertawa
    final mouthPath = Path();
    mouthPath.moveTo(-10, 8);
    mouthPath.quadraticBezierTo(0, 18, 10, 8);
    mouthPath.close();
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF451A03));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 2 ENEMIES (LOBI & RUANG TUNGGU POLIKLINIK)
  // ─────────────────────────────────────────────────────────────────────────────
  void _drawSpikeCorona(Canvas canvas, bool isFlash) {
    final spin = animTimer * 0.8;
    canvas.rotate(spin);

    final coronaColor = isFlash ? Colors.white : const Color(0xFFEF4444); // Merah Corona
    final spikeColor = isFlash ? Colors.white : const Color(0xFFB91C1C);

    // 8 Duri Spike berputar
    for (int i = 0; i < 8; i++) {
      final angle = i * (pi / 4);
      final dx = cos(angle);
      final dy = sin(angle);

      final spikeStem = Paint()
        ..color = spikeColor
        ..strokeWidth = 2.5;
      canvas.drawLine(Offset(dx * 12, dy * 12), Offset(dx * 18, dy * 18), spikeStem);
      canvas.drawCircle(Offset(dx * 19, dy * 19), 3.0, Paint()..color = spikeColor);
    }

    // Bola tengah
    canvas.drawCircle(Offset.zero, 13, Paint()..color = coronaColor);
    canvas.drawCircle(
      const Offset(-3, -3),
      11,
      Paint()..color = isFlash ? Colors.white : const Color(0xFFDC2626),
    );

    // Mata merah menyala
    canvas.drawCircle(const Offset(-4, -1), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(4, -1), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(-4, -1), 1.2, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(4, -1), 1.2, Paint()..color = Colors.black);
  }

  void _drawBacillus(Canvas canvas, bool isFlash) {
    // Bakteri batang kapsul ungu neon berotasi
    final roll = sin(animTimer * 1.5) * 0.3;
    canvas.rotate(roll);

    final bodyColor = isFlash ? Colors.white : const Color(0xFF8B5CF6);
    final coreColor = isFlash ? Colors.white : const Color(0xFFA78BFA);

    // Bentuk kapsul rounded
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 28, height: 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, Paint()..color = bodyColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-2, -2), width: 24, height: 12),
        const Radius.circular(6),
      ),
      Paint()..color = coreColor,
    );

    // Rambut getar silia di keliling
    final ciliaPaint = Paint()
      ..color = const Color(0xFF6D28D9)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(-14, 0), const Offset(-18, 0), ciliaPaint);
    canvas.drawLine(const Offset(14, 0), const Offset(18, 0), ciliaPaint);
    canvas.drawLine(const Offset(-7, -8), const Offset(-7, -12), ciliaPaint);
    canvas.drawLine(const Offset(7, -8), const Offset(7, -12), ciliaPaint);

    // Mata neon hijau
    canvas.drawCircle(const Offset(-5, -1), 2.5, Paint()..color = const Color(0xFF22C55E));
    canvas.drawCircle(const Offset(4, -1), 2.5, Paint()..color = const Color(0xFF22C55E));
  }

  void _drawToxicDroplet(Canvas canvas, bool isFlash) {
    // Droplet bersin toska mengkilap
    final bodyPaint = Paint()
      ..color = isFlash ? Colors.white : const Color(0xFF06B6D4);

    final path = Path();
    path.moveTo(0, -16);
    path.quadraticBezierTo(14, 0, 12, 12);
    path.quadraticBezierTo(0, 18, -12, 12);
    path.quadraticBezierTo(-14, 0, 0, -16);
    path.close();

    canvas.drawPath(path, bodyPaint);

    // Kilap droplet
    final glowPaint = Paint()..color = const Color(0x9967E8F9);
    canvas.drawCircle(const Offset(-4, 0), 4, glowPaint);

    // Mata jahat
    canvas.drawCircle(const Offset(-3, 4), 2.0, Paint()..color = const Color(0xFF083344));
    canvas.drawCircle(const Offset(4, 4), 2.0, Paint()..color = const Color(0xFF083344));
  }

  void _drawBossStage2(Canvas canvas, bool isFlash) {
    // Boss Apex Delta Corona: Merah membara dengan 10 duri tajam mahkota
    final spin = animTimer * 0.45;
    canvas.save();
    canvas.rotate(spin);

    const auraColor = Color(0x44EF4444);
    canvas.drawCircle(Offset.zero, 44, Paint()..color = auraColor);

    // 10 Duri berputar
    for (int i = 0; i < 10; i++) {
      final angle = i * (pi / 5);
      final dx = cos(angle);
      final dy = sin(angle);

      final spikeStem = Paint()
        ..color = isFlash ? Colors.white : const Color(0xFFB91C1C)
        ..strokeWidth = 4.0;
      canvas.drawLine(Offset(dx * 24, dy * 24), Offset(dx * 36, dy * 36), spikeStem);
      canvas.drawCircle(
        Offset(dx * 37, dy * 37),
        5.5,
        Paint()..color = isFlash ? Colors.white : const Color(0xFFEF4444),
      );
    }

    // Inti Bola
    canvas.drawCircle(
      Offset.zero,
      28,
      Paint()..color = isFlash ? Colors.white : const Color(0xFF991B1B),
    );
    canvas.restore();

    // Mata merah membara dengan pupil hitam tajam
    canvas.drawCircle(const Offset(-9, -6), 6.5, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(const Offset(9, -6), 6.5, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(const Offset(-9, -6), 3.0, Paint()..color = const Color(0xFF7F1D1D));
    canvas.drawCircle(const Offset(9, -6), 3.0, Paint()..color = const Color(0xFF7F1D1D));

    // Mulut taring
    final mouthPath = Path();
    mouthPath.moveTo(-11, 8);
    mouthPath.lineTo(-5, 14);
    mouthPath.lineTo(0, 9);
    mouthPath.lineTo(5, 14);
    mouthPath.lineTo(11, 8);
    mouthPath.close();
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF450A0A));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAGE 3 ENEMIES (NURSE STATION & KORIDOR RAWAT)
  // ─────────────────────────────────────────────────────────────────────────────
  void _drawSuperbugMrsa(Canvas canvas, bool isFlash) {
    // Bakteri kebal baja emas bersisik tebal
    final bodyPaint = Paint()
      ..color = isFlash ? Colors.white : const Color(0xFFEAB308); // Emas metalik
    final armorPaint = Paint()
      ..color = isFlash ? Colors.white : const Color(0xFFA16207);

    // Tubuh berlapis
    canvas.drawCircle(Offset.zero, 15, bodyPaint);

    // Cangkang perisai tebal di punggung
    final shieldPath = Path();
    shieldPath.addArc(Rect.fromCircle(center: Offset.zero, radius: 17), -pi * 0.8, pi * 0.8);
    final strokePaint = Paint()
      ..color = armorPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawPath(shieldPath, strokePaint);

    // Mata garang berpelindung
    canvas.drawCircle(const Offset(-4, 0), 3.0, Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(const Offset(4, 0), 3.0, Paint()..color = const Color(0xFFDC2626));
  }

  void _drawFungalSpore(Canvas canvas, bool isFlash) {
    // Spora jamur candida berdenyut mekar
    final pulse = sin(animTimer * 1.5) * 2.0;

    final petalColor = isFlash ? Colors.white : const Color(0xFFF472B6);
    final coreColor = isFlash ? Colors.white : const Color(0xFFDB2777);

    // 5 Gelembung spora melingkar
    for (int i = 0; i < 5; i++) {
      final angle = i * (pi * 2 / 5);
      final offset = Offset(cos(angle) * (11 + pulse), sin(angle) * (11 + pulse));
      canvas.drawCircle(offset, 6.0, Paint()..color = petalColor);
    }

    // Inti spora tengah
    canvas.drawCircle(Offset.zero, 9.0, Paint()..color = coreColor);

    // Bintik serbuk spora
    canvas.drawCircle(const Offset(-3, -2), 1.8, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(3, 2), 1.8, Paint()..color = Colors.white);
  }

  void _drawShadowPathogen(Canvas canvas, bool isFlash) {
    // Patogen bayangan hitam-keunguan
    final wave = sin(animTimer * 2) * 3;

    final bodyPaint = Paint()
      ..color = isFlash ? Colors.white : const Color(0xFF1E1B4B);

    // Ekor asap bergelombang ke kanan
    final tailPath = Path();
    tailPath.moveTo(0, -10);
    tailPath.quadraticBezierTo(16, -5 + wave, 20, wave);
    tailPath.quadraticBezierTo(14, 8 + wave, 0, 10);
    tailPath.close();
    canvas.drawPath(tailPath, Paint()..color = const Color(0x884338CA));

    // Kepala bayangan
    canvas.drawCircle(Offset.zero, 11, bodyPaint);

    // Mata iblis merah menyala
    canvas.drawCircle(const Offset(-3, -2), 2.8, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(const Offset(3, -2), 2.8, Paint()..color = const Color(0xFFEF4444));
  }

  void _drawBossStage3(Canvas canvas, bool isFlash) {
    // Final Mega Boss: Superbug Chimera Titan (Raksasa ungu gelap dengan 12 duri magenta menyala)
    final spin = animTimer * 0.4;
    canvas.save();
    canvas.rotate(spin);

    final bossColor = isFlash ? Colors.white : const Color(0xFF6B21A8); // Ungu mutasi
    const auraColor = Color(0x33A855F7);

    // Aura pendar boss
    canvas.drawCircle(Offset.zero, 46, Paint()..color = auraColor);

    // 12 Duri Mahkota Mutasi
    for (int i = 0; i < 12; i++) {
      final angle = i * (pi / 6);
      final dx = cos(angle);
      final dy = sin(angle);

      final spikeStem = Paint()
        ..color = isFlash ? Colors.white : const Color(0xFF581C87)
        ..strokeWidth = 4.0;
      canvas.drawLine(Offset(dx * 26, dy * 26), Offset(dx * 38, dy * 38), spikeStem);
      canvas.drawCircle(
        Offset(dx * 39, dy * 39),
        5.5,
        Paint()..color = const Color(0xFFF43F5E), // Ujung merah membara
      );
    }

    // Inti Monster Boss
    canvas.drawCircle(Offset.zero, 29, Paint()..color = bossColor);
    canvas.restore();

    // Wajah Boss Tetap Menghadap Depan
    final eyePaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(const Offset(-10, -7), 6, eyePaint);
    canvas.drawCircle(const Offset(10, -7), 6, eyePaint);
    canvas.drawCircle(const Offset(0, -11), 4.5, eyePaint); // Mata ketiga di dahi

    canvas.drawCircle(const Offset(-10, -7), 3, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(10, -7), 3, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(0, -11), 2, Paint()..color = Colors.black);

    // Mulut bergigi tajam
    final mouthPath = Path();
    mouthPath.moveTo(-12, 10);
    mouthPath.lineTo(-6, 16);
    mouthPath.lineTo(0, 11);
    mouthPath.lineTo(6, 16);
    mouthPath.lineTo(12, 10);
    mouthPath.close();
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF0F172A));
  }

  void _drawBossHpBar(Canvas canvas) {
    const double barWidth = 64.0;
    const double barHeight = 6.0;
    final barRect = Rect.fromCenter(center: const Offset(0, -48), width: barWidth, height: barHeight);

    // Background bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF1E293B),
    );

    // Progress bar
    final fillRatio = (currentHp / maxHp).clamp(0.0, 1.0);
    final fillRect = Rect.fromLTWH(
      barRect.left,
      barRect.top,
      barWidth * fillRatio,
      barHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFFEF4444),
    );
  }
}
