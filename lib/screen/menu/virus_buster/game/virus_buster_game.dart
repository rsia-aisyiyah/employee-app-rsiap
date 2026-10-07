import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/bullet.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/player_doctor.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/powerup_item.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/stage_scenery.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/components/virus_enemy.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/models/virus_buster_models.dart';

class VirusBusterGame extends FlameGame with HasCollisionDetection {
  final void Function(VirusBusterStats stats)? onStatsUpdated;
  final void Function(int finalScore, int stage, int defeated)? onGameOverCallback;
  final void Function(int clearedStage, int currentScore)? onStageClearedCallback;

  late PlayerDoctor player;
  late StageScenery scenery;

  int currentStage = 1;
  int score = 0;
  int virusesDefeated = 0;
  int lives = 3;
  static const int maxLives = 3;

  double groundY = 0.0;
  bool isBossSpawned = false;
  bool isStageCleared = false;
  bool isGameOver = false;

  // Spawner timers
  double enemySpawnTimer = 0.0;
  double powerupSpawnTimer = 0.0;
  final Random random = Random();

  VirusBusterGame({
    this.onStatsUpdated,
    this.onGameOverCallback,
    this.onStageClearedCallback,
  });

  @override
  Color backgroundColor() => const Color(0xFF0D1117);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Tinggi ground / lantai disesuaikan dengan garis lantai backdrop
    groundY = size.y * 0.77;

    // Tambah Scenery
    scenery = StageScenery(stageNumber: currentStage, groundY: groundY);
    add(scenery);

    // Tambah Player Doctor
    player = PlayerDoctor();
    player.setupGround(groundY);
    add(player);

    _notifyStats();
  }

  void _notifyStats() {
    final stageConfig = StageConfig.stages[currentStage - 1];
    final progress = (score / stageConfig.targetScoreToBoss).clamp(0.0, 1.0);

    String powerupName = '';
    double powerupRemaining = 0.0;
    if (player.isShieldActive) {
      powerupName = 'Aura APD';
      powerupRemaining = player.shieldTimer;
    } else if (player.isSpreadShotActive) {
      powerupName = 'Spread Vitamin';
      powerupRemaining = player.spreadShotTimer;
    }

    onStatsUpdated?.call(VirusBusterStats(
      score: score,
      virusesDefeated: virusesDefeated,
      stage: currentStage,
      lives: lives,
      maxLives: maxLives,
      powerupTimer: powerupRemaining,
      activePowerupName: powerupName,
      stageProgress: progress,
    ));
  }

  @override
  void update(double dt) {
    if (isGameOver || isStageCleared) return;
    super.update(dt);

    // Parallax scrolling scenery berdasarkan gerak player
    if (player.isMoving) {
      final delta = player.velocityX * dt;
      scenery.scroll(delta);
    } else {
      // Auto slow-scroll untuk memberi sensasi dinamis
      scenery.scroll(30 * dt);
    }

    // Cek target Boss Stage
    final stageConfig = StageConfig.stages[currentStage - 1];
    if (score >= stageConfig.targetScoreToBoss && !isBossSpawned) {
      _spawnBoss();
    }

    // Spawn Musuh Biasa jika Boss belum muncul
    if (!isBossSpawned) {
      enemySpawnTimer += dt;
      final spawnInterval = max(1.2, 2.6 - (currentStage * 0.4));
      if (enemySpawnTimer >= spawnInterval) {
        enemySpawnTimer = 0.0;
        _spawnEnemy();
      }
    }

    // Spawn Powerup berkala
    powerupSpawnTimer += dt;
    if (powerupSpawnTimer >= 14.0) {
      powerupSpawnTimer = 0.0;
      _spawnPowerup();
    }

    _notifyStats();
  }

  void _spawnEnemy() {
    final r = random.nextDouble();
    VirusType type;
    double spawnY;

    if (r < 0.45) {
      // Flu Goo (di lantai)
      type = VirusType.fluGoo;
      spawnY = groundY - 16;
    } else if (r < 0.78) {
      // Spike Corona (melayang agak tinggi)
      type = VirusType.spikeCorona;
      spawnY = groundY - 70 - random.nextDouble() * 50;
    } else {
      // Mosquito (terbang tinggi lalu menukik)
      type = VirusType.mosquito;
      spawnY = groundY - 110 - random.nextDouble() * 40;
    }

    final enemy = VirusEnemy(
      type: type,
      position: Vector2(size.x + 40, spawnY),
      initialGroundY: groundY,
      moveSpeed: 80.0 + (currentStage * 20.0),
      onDefeated: _handleEnemyDefeated,
      onHitPlayer: _handlePlayerHit,
    );
    add(enemy);
  }

  void _spawnBoss() {
    isBossSpawned = true;
    final boss = VirusEnemy(
      type: VirusType.bossMega,
      position: Vector2(size.x + 60, groundY - 80),
      initialGroundY: groundY,
      moveSpeed: 30.0,
      onDefeated: _handleBossDefeated,
      onHitPlayer: _handlePlayerHit,
    );
    add(boss);
  }

  void _spawnPowerup() {
    final types = [
      PowerupType.firstAid,
      PowerupType.spreadShot,
      PowerupType.hazmatShield,
      PowerupType.sanitizerBomb,
    ];
    final selected = types[random.nextInt(types.length)];
    final spawnY = groundY - 60 - random.nextDouble() * 50;

    final item = PowerupItem(
      type: selected,
      position: Vector2(size.x + 30, spawnY),
      groundY: groundY,
      onCollected: _handlePowerupCollected,
    );
    add(item);
  }

  void _handleEnemyDefeated(VirusEnemy enemy, int scoreAwarded) {
    score += scoreAwarded;
    virusesDefeated++;
    _notifyStats();
  }

  void _handleBossDefeated(VirusEnemy boss, int scoreAwarded) {
    score += scoreAwarded;
    virusesDefeated++;
    isStageCleared = true;
    _notifyStats();

    onStageClearedCallback?.call(currentStage, score);
  }

  void _handlePlayerHit(PlayerDoctor p) {
    if (p.isInvincible || p.isShieldActive) return;
    p.takeDamage();
    lives--;
    _notifyStats();

    if (lives <= 0) {
      isGameOver = true;
      onGameOverCallback?.call(score, currentStage, virusesDefeated);
    }
  }

  void _handlePowerupCollected(PowerupType type) {
    switch (type) {
      case PowerupType.firstAid:
        if (lives < maxLives) {
          lives++;
        }
        score += 30;
        break;
      case PowerupType.spreadShot:
        player.activateSpreadShot(12.0); // 12 Detik spread shot
        score += 40;
        break;
      case PowerupType.hazmatShield:
        player.activateShield(8.0); // 8 Detik kebal
        score += 40;
        break;
      case PowerupType.sanitizerBomb:
        // Bersihkan semua musuh di layar
        final enemies = children.whereType<VirusEnemy>().toList();
        for (var e in enemies) {
          if (e.type != VirusType.bossMega) {
            e.takeDamage(10);
          } else {
            e.takeDamage(4);
          }
        }
        score += 100;
        break;
    }
    _notifyStats();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PLAYER ACTIONS DARI GAMEPAD
  // ─────────────────────────────────────────────────────────────────────────────
  void playerMoveLeft() {
    player.moveLeft();
  }

  void playerMoveRight() {
    player.moveRight();
  }

  void playerStop() {
    player.stopMoving();
  }

  void playerJump() {
    player.jump();
  }

  void playerShoot() {
    final muzzle = player.muzzlePosition;
    final dirX = player.facingDirection.toDouble();

    if (player.isSpreadShotActive) {
      // Contra Spread Shot: 3 Peluru menyebar
      add(AntisepticBullet(
        startPosition: muzzle,
        directionX: dirX,
        directionY: 0.0,
        isEnhanced: true,
      ));
      add(AntisepticBullet(
        startPosition: muzzle,
        directionX: dirX,
        directionY: -0.28,
        isEnhanced: true,
      ));
      add(AntisepticBullet(
        startPosition: muzzle,
        directionX: dirX,
        directionY: 0.28,
        isEnhanced: true,
      ));
    } else {
      // Single Syringe Shot
      add(AntisepticBullet(
        startPosition: muzzle,
        directionX: dirX,
        directionY: 0.0,
        isEnhanced: false,
      ));
    }
  }

  /// Pindah ke stage berikutnya setelah menang
  void nextStage() {
    if (currentStage < StageConfig.stages.length) {
      currentStage++;
    } else {
      // Loop kembali dengan tingkat kesulitan lebih tinggi
      currentStage = 1;
    }
    isStageCleared = false;
    isBossSpawned = false;

    // Reset scenery
    scenery.removeFromParent();
    scenery = StageScenery(stageNumber: currentStage, groundY: groundY);
    add(scenery);

    // Hapus semua musuh & bullet lama
    children.whereType<VirusEnemy>().forEach((e) => e.removeFromParent());
    children.whereType<AntisepticBullet>().forEach((b) => b.removeFromParent());
    children.whereType<PowerupItem>().forEach((p) => p.removeFromParent());

    // Reset posisi dokter
    player.setupGround(groundY);

    _notifyStats();
  }

  /// Restart dari awal
  void restartGame() {
    score = 0;
    virusesDefeated = 0;
    lives = maxLives;
    currentStage = 1;
    isGameOver = false;
    isBossSpawned = false;
    isStageCleared = false;

    // Reset scenery
    scenery.removeFromParent();
    scenery = StageScenery(stageNumber: currentStage, groundY: groundY);
    add(scenery);

    // Bersihkan entitas
    children.whereType<VirusEnemy>().forEach((e) => e.removeFromParent());
    children.whereType<AntisepticBullet>().forEach((b) => b.removeFromParent());
    children.whereType<PowerupItem>().forEach((p) => p.removeFromParent());

    player.setupGround(groundY);
    player.isShieldActive = false;
    player.isSpreadShotActive = false;

    _notifyStats();
  }
}
