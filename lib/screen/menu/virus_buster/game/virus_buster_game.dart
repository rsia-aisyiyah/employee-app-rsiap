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
  final HeroConfig heroConfig;
  final GameDifficulty difficulty;
  final void Function(VirusBusterStats stats)? onStatsUpdated;
  final void Function(int finalScore, int stage, int defeated)? onGameOverCallback;
  final void Function(int clearedStage, int currentScore)? onStageClearedCallback;

  late PlayerDoctor player;
  late StageScenery scenery;

  int currentStage = 1;
  int loopCount = 1;
  int score = 0;
  int stageScore = 0; // Skor khusus yang dikumpulkan di stage berjalan
  int virusesDefeated = 0;
  late int lives;
  late int maxLives;

  double groundY = 0.0;
  bool isBossSpawned = false;
  bool isStageCleared = false;
  bool isGameOver = false;

  // Spawner timers
  double enemySpawnTimer = 0.0;
  double powerupSpawnTimer = 0.0;
  final Random random = Random();

  VirusBusterGame({
    HeroConfig? heroConfig,
    this.difficulty = GameDifficulty.medium,
    this.onStatsUpdated,
    this.onGameOverCallback,
    this.onStageClearedCallback,
  }) : heroConfig = heroConfig ?? HeroConfig.heroes.first {
    maxLives = difficulty.baseLives + this.heroConfig.bonusLives;
    lives = maxLives;
  }

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

    // Tambah Karakter Hero Nakes yang Dipilih
    player = PlayerDoctor(heroConfig: heroConfig);
    player.setupGround(groundY);
    add(player);

    _notifyStats();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    groundY = size.y * 0.77;
    if (isLoaded) {
      player.setupGround(groundY);
    }
  }

  void _notifyStats() {
    final stageConfig = StageConfig.stages[currentStage - 1];
    // Progress stage dihitung dari pencapaian skor musuh di stage saat ini
    final progress = (stageScore / stageConfig.targetScoreToBoss).clamp(0.0, 1.0);

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

    // Parallax scrolling scenery seirama dengan langkah gerak kaki hero
    if (player.isMoving) {
      final delta = player.velocityX * dt;
      scenery.scroll(delta);
    }

    // Cek target Boss Stage (Berdasarkan stageScore yang dikumpulkan di stage ini)
    final stageConfig = StageConfig.stages[currentStage - 1];
    if (stageScore >= stageConfig.targetScoreToBoss && !isBossSpawned) {
      _spawnBoss();
    }

    // Spawn Musuh Biasa jika Boss belum muncul
    if (!isBossSpawned) {
      enemySpawnTimer += dt;
      final loopSpeedBonus = (loopCount - 1) * 0.15;
      final baseInterval = max(0.8, 2.6 - (currentStage * 0.4) - loopSpeedBonus);
      final spawnInterval = max(0.65, baseInterval + difficulty.spawnIntervalDelta);
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

    switch (currentStage) {
      case 1:
        // STAGE 1: Drop-Off IGD 24 Jam
        if (r < 0.45) {
          type = VirusType.fluGoo; // Lendir merayap di tanah (bisa diinjak)
          spawnY = groundY - 22;
        } else if (r < 0.78) {
          type = VirusType.dustMite; // Partikel debu/alergen melayang
          spawnY = groundY - 75 - random.nextDouble() * 50;
        } else {
          type = VirusType.mosquito; // Nyamuk Aedes menukik cepat
          spawnY = groundY - 125 - random.nextDouble() * 45;
        }
        break;

      case 2:
        // STAGE 2: Lobi & Ruang Tunggu Poliklinik
        if (r < 0.40) {
          type = VirusType.spikeCorona; // Virus duri berputar sinusoidal
          spawnY = groundY - 85 - random.nextDouble() * 55;
        } else if (r < 0.74) {
          type = VirusType.bacillus; // Bakteri batang melompat di darat
          spawnY = groundY - 35;
        } else {
          type = VirusType.toxicDroplet; // Droplet batuk meluncur diagonal
          spawnY = groundY - 105 - random.nextDouble() * 50;
        }
        break;

      case 3:
      default:
        // STAGE 3: Nurse Station & Koridor Rawat
        if (r < 0.38) {
          type = VirusType.superbugMrsa; // Bakteri lapis baja kebal antibiotik
          spawnY = groundY - 28;
        } else if (r < 0.72) {
          type = VirusType.fungalSpore; // Spora jamur candida melayang
          spawnY = groundY - 95 - random.nextDouble() * 50;
        } else {
          type = VirusType.shadowPathogen; // Patogen bayangan melesat cepat
          spawnY = groundY - 120 - random.nextDouble() * 45;
        }
        break;
    }

    final enemy = VirusEnemy(
      type: type,
      position: Vector2(size.x + 40, spawnY),
      initialGroundY: groundY,
      moveSpeed: (75.0 + (currentStage * 22.0)) * difficulty.enemySpeedMultiplier,
      onDefeated: _handleEnemyDefeated,
      onHitPlayer: _handlePlayerHit,
    );
    add(enemy);
  }

  void _spawnBoss() {
    isBossSpawned = true;
    VirusType bossType;
    switch (currentStage) {
      case 1:
        bossType = VirusType.bossStage1;
        break;
      case 2:
        bossType = VirusType.bossStage2;
        break;
      case 3:
      default:
        bossType = VirusType.bossStage3;
        break;
    }

    final boss = VirusEnemy(
      type: bossType,
      position: Vector2(size.x + 80, groundY - 110),
      initialGroundY: groundY,
      moveSpeed: 30.0 * difficulty.enemySpeedMultiplier,
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
    final adjustedScore = (scoreAwarded * difficulty.scoreMultiplier).round();
    score += adjustedScore;
    stageScore += adjustedScore;
    virusesDefeated++;
    _notifyStats();
  }

  void _handleBossDefeated(VirusEnemy boss, int scoreAwarded) {
    final adjustedScore = (scoreAwarded * difficulty.scoreMultiplier).round();
    score += adjustedScore;
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
      player.stopMoving();
      player.standUp();
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
          if (!e.isBoss) {
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

  void playerCrouch() {
    player.crouch();
  }

  void playerStandUp() {
    player.standUp();
  }

  void playerJump() {
    player.jump();
  }

  void playerShoot() {
    if (isGameOver || isStageCleared) return;

    final muzzle = player.muzzlePosition;
    final dirX = player.facingDirection.toDouble();
    final bulletSpeed = 560.0 * heroConfig.bulletSpeedMultiplier;
    final maxDist = heroConfig.profession == HeroProfession.farmasi ? 1100.0 : 850.0;

    if (player.isSpreadShotActive) {
      // Contra Spread Shot: 3 Peluru menyebar
      add(AntisepticBullet(
        startPosition: muzzle,
        speed: bulletSpeed,
        directionX: dirX,
        directionY: 0.0,
        isEnhanced: true,
        maxDistance: maxDist,
        customBulletColor: heroConfig.bulletColor,
        customGlowColor: heroConfig.bulletGlowColor,
      ));
      add(AntisepticBullet(
        startPosition: muzzle,
        speed: bulletSpeed,
        directionX: dirX,
        directionY: -0.28,
        isEnhanced: true,
        maxDistance: maxDist,
        customBulletColor: heroConfig.bulletColor,
        customGlowColor: heroConfig.bulletGlowColor,
      ));
      add(AntisepticBullet(
        startPosition: muzzle,
        speed: bulletSpeed,
        directionX: dirX,
        directionY: 0.28,
        isEnhanced: true,
        maxDistance: maxDist,
        customBulletColor: heroConfig.bulletColor,
        customGlowColor: heroConfig.bulletGlowColor,
      ));
    } else {
      // Single Shot Sesuai Karakter Hero
      add(AntisepticBullet(
        startPosition: muzzle,
        speed: bulletSpeed,
        directionX: dirX,
        directionY: 0.0,
        isEnhanced: false,
        maxDistance: maxDist,
        customBulletColor: heroConfig.bulletColor,
        customGlowColor: heroConfig.bulletGlowColor,
      ));
    }
  }

  /// Pindah ke stage berikutnya setelah menang
  void nextStage() {
    if (currentStage < StageConfig.stages.length) {
      currentStage++;
    } else {
      // Loop kembali dengan tingkat kesulitan lebih tinggi (Mode Endless)
      loopCount++;
      currentStage = 1;
    }
    stageScore = 0;
    isStageCleared = false;
    isBossSpawned = false;

    // Reset scenery
    scenery.removeFromParent();
    scenery = StageScenery(stageNumber: currentStage, groundY: groundY);
    add(scenery);

    // Hapus semua musuh, proyektil musuh, bullet, & powerup lama
    children.whereType<VirusEnemy>().forEach((e) => e.removeFromParent());
    children.whereType<VirusProjectile>().forEach((vp) => vp.removeFromParent());
    children.whereType<AntisepticBullet>().forEach((b) => b.removeFromParent());
    children.whereType<PowerupItem>().forEach((p) => p.removeFromParent());

    // Reset posisi hero
    player.setupGround(groundY);

    _notifyStats();
  }

  /// Restart dari awal
  void restartGame() {
    score = 0;
    stageScore = 0;
    virusesDefeated = 0;
    maxLives = difficulty.baseLives + heroConfig.bonusLives;
    lives = maxLives;
    currentStage = 1;
    loopCount = 1;
    isGameOver = false;
    isBossSpawned = false;
    isStageCleared = false;

    // Reset scenery
    scenery.removeFromParent();
    scenery = StageScenery(stageNumber: currentStage, groundY: groundY);
    add(scenery);

    // Bersihkan entitas
    children.whereType<VirusEnemy>().forEach((e) => e.removeFromParent());
    children.whereType<VirusProjectile>().forEach((vp) => vp.removeFromParent());
    children.whereType<AntisepticBullet>().forEach((b) => b.removeFromParent());
    children.whereType<PowerupItem>().forEach((p) => p.removeFromParent());

    player.setupGround(groundY);
    player.isShieldActive = false;
    player.isSpreadShotActive = false;

    _notifyStats();
  }
}
