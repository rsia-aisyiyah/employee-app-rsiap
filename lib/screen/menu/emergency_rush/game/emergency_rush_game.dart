import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/game/ambulance_player.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/game/item_pickup.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/game/lane_config.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/game/obstacle_vehicle.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/game/road_background.dart';

class EmergencyRushGame extends FlameGame with HasCollisionDetection {
  // Game Configuration & State
  int score = 0;
  double distanceMeters = 0.0;
  double currentSpeedKmH = 60.0;
  int lives = 3;
  double sirenEnergy = 0.0; // 0.0 to 1.0 (100%)
  bool isGameOver = false;
  bool isGamePaused = false;
  int itemsCollected = 0;
  int topSpeedAchieved = 60;

  // Spawning logic
  double spawnTimer = 0.0;
  double itemSpawnTimer = 0.0;
  final Random _rng = Random();

  // Child Components (initialized eagerly to prevent LateInitializationError on early onGameResize)
  final RoadBackground roadBackground = RoadBackground();
  final AmbulancePlayer player = AmbulancePlayer();

  // External Callbacks to Flutter UI
  final void Function(int score, int distance, int speed, int lives, double energy, bool isSirenActive)? onStatsUpdated;
  final void Function(int score, int distance, int itemsCollected, int maxSpeed)? onGameOverCallback;

  EmergencyRushGame({
    this.onStatsUpdated,
    this.onGameOverCallback,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Road Background
    if (!children.contains(roadBackground)) {
      add(roadBackground);
    }

    // 2. Ambulance Player
    if (!children.contains(player)) {
      add(player);
    }

    _resetGame();
    _syncPositions();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _syncPositions(size);
  }

  void _syncPositions([Vector2? targetSize]) {
    final effectiveSize = targetSize ?? size;
    if (effectiveSize.x > 0 && effectiveSize.y > 0) {
      roadBackground.updateDimensions(effectiveSize);
      player.setupInitialPosition(
        roadWidth: roadBackground.roadWidth,
        roadStartX: roadBackground.roadStartX,
        screenHeight: effectiveSize.y,
      );
    }
  }

  void _resetGame() {
    score = 0;
    distanceMeters = 0.0;
    currentSpeedKmH = 60.0;
    lives = 3;
    sirenEnergy = 0.0;
    isGameOver = false;
    isGamePaused = false;
    itemsCollected = 0;
    topSpeedAchieved = 60;
    spawnTimer = 0.0;
    itemSpawnTimer = 0.0;

    // Clear existing obstacles and pickups
    children.whereType<ObstacleVehicle>().forEach((c) => c.removeFromParent());
    children.whereType<ItemPickup>().forEach((c) => c.removeFromParent());

    _syncPositions();
  }

  void restart() {
    _resetGame();
    resumeEngine();
  }

  void pause() {
    isGamePaused = true;
    pauseEngine();
  }

  void resume() {
    isGamePaused = false;
    resumeEngine();
  }

  void movePlayerLeft() {
    if (isGameOver || isGamePaused) return;
    HapticFeedback.selectionClick();
    player.moveLeft(roadBackground.roadWidth, roadBackground.roadStartX);
  }

  void movePlayerRight() {
    if (isGameOver || isGamePaused) return;
    HapticFeedback.selectionClick();
    player.moveRight(roadBackground.roadWidth, roadBackground.roadStartX);
  }

  void activateSirenRush() {
    if (sirenEnergy >= 0.8 && !player.isSirenBoostActive && !isGameOver) {
      HapticFeedback.heavyImpact();
      sirenEnergy = 0.0;
      player.activateSirenBoost(5.0); // 5 seconds invincible rush
    }
  }

  @override
  void update(double dt) {
    if (isGameOver || isGamePaused) return;
    super.update(dt);

    // Fallback sync if viewport size was resolved late
    if (player.position.y <= 0 && size.y > 0) {
      _syncPositions();
    }

    // 1. Calculate Pixels per second from km/h
    // Speed increases gradually: +5 km/h for every 100 meters, capped at 160 km/h (or 180 km/h during boost)
    final baseSpeed = (60.0 + (distanceMeters / 100.0) * 4.0).clamp(60.0, 150.0);
    currentSpeedKmH = player.isSirenBoostActive ? baseSpeed + 35.0 : baseSpeed;

    if (currentSpeedKmH.toInt() > topSpeedAchieved) {
      topSpeedAchieved = currentSpeedKmH.toInt();
    }

    final pixelsPerSecond = currentSpeedKmH * 6.2;
    final deltaPixels = pixelsPerSecond * dt;

    // 2. Road scrolling
    roadBackground.updateScroll(deltaPixels);

    // 3. Move obstacles down
    for (final obs in children.whereType<ObstacleVehicle>()) {
      obs.position.y += deltaPixels * 0.95; // Obstacles travel forward relative to road
    }

    // 4. Move items down
    for (final item in children.whereType<ItemPickup>()) {
      item.position.y += deltaPixels;
    }

    // 5. Update Distance & Base Score
    final distanceIncrement = (currentSpeedKmH * 1000 / 3600) * dt;
    distanceMeters += distanceIncrement;
    final multiplier = player.isSirenBoostActive ? 2 : 1;
    score += (distanceIncrement * multiplier).round();

    // 6. Handle Obstacle Collision with Player
    _checkCollisions();

    // 7. Spawn Obstacles
    _handleObstacleSpawning(dt);

    // 8. Spawn Collectibles
    _handleItemSpawning(dt);

    // 9. Notify Flutter UI HUD
    onStatsUpdated?.call(
      score,
      distanceMeters.toInt(),
      currentSpeedKmH.toInt(),
      lives,
      sirenEnergy,
      player.isSirenBoostActive,
    );
  }

  void _checkCollisions() {
    if (player.isInvincible) return;

    final playerRect = player.toAbsoluteRect();

    // Collision with Obstacles
    for (final obs in children.whereType<ObstacleVehicle>().toList()) {
      final obsRect = obs.toAbsoluteRect();
      if (playerRect.overlaps(obsRect)) {
        if (player.isSirenBoostActive) {
          // Sirens active: smash obstacle for bonus combo points!
          HapticFeedback.mediumImpact();
          score += 200;
          obs.removeFromParent();
        } else {
          // Normal: Hit obstacle
          _onPlayerHit(obs);
          break;
        }
      }
    }

    // Collision with Pickups
    for (final item in children.whereType<ItemPickup>().toList()) {
      final itemRect = item.toAbsoluteRect();
      if (playerRect.overlaps(itemRect)) {
        _onItemCollected(item);
      }
    }
  }

  void _onPlayerHit(ObstacleVehicle obstacle) {
    HapticFeedback.heavyImpact();
    lives--;
    player.triggerHit();

    if (lives <= 0) {
      lives = 0;
      isGameOver = true;
      pauseEngine();
      onGameOverCallback?.call(
        score,
        distanceMeters.toInt(),
        itemsCollected,
        topSpeedAchieved,
      );
    }
  }

  void _onItemCollected(ItemPickup item) {
    HapticFeedback.lightImpact();
    itemsCollected++;

    switch (item.type) {
      case ItemType.firstAidKit:
        score += 120;
        if (lives < 3) lives++;
        break;
      case ItemType.energyCapsule:
        score += 150;
        sirenEnergy = (sirenEnergy + 0.35).clamp(0.0, 1.0);
        break;
      case ItemType.goldenStar:
        score += 250;
        sirenEnergy = (sirenEnergy + 0.15).clamp(0.0, 1.0);
        break;
    }

    item.removeFromParent();
  }

  void _handleObstacleSpawning(double dt) {
    spawnTimer += dt;

    // Spawn interval gets shorter as speed increases (from 2.4s at start down to 1.1s)
    final spawnInterval = (2.4 - (currentSpeedKmH / 140.0) * 1.1).clamp(1.1, 2.4);

    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0.0;
      _spawnObstaclePattern();
    }
  }

  void _spawnObstaclePattern() {
    // Pick 1 or 2 lanes (NEVER all 3, ensuring at least 1 lane is always open)
    final lanes = [Lane.left, Lane.center, Lane.right]..shuffle(_rng);

    // Pick how many lanes to block: 75% 1 lane, 25% 2 lanes (if speed > 85 km/h)
    final blockCount = (currentSpeedKmH > 85.0 && _rng.nextDouble() < 0.35) ? 2 : 1;

    for (int i = 0; i < blockCount; i++) {
      final lane = lanes[i];
      final laneCenterX = RoadConfig.getLaneCenterX(
        lane: lane,
        roadWidth: roadBackground.roadWidth,
        roadStartX: roadBackground.roadStartX,
      );

      // Random vehicle type
      final randVal = _rng.nextDouble();
      ObstacleType type;
      if (randVal < 0.35) {
        type = ObstacleType.sedanRed;
      } else if (randVal < 0.60) {
        type = ObstacleType.sedanBlue;
      } else if (randVal < 0.80) {
        type = ObstacleType.taxiYellow;
      } else if (randVal < 0.92) {
        type = ObstacleType.truckBox;
      } else {
        type = ObstacleType.trafficCone;
      }

      final obstacle = ObstacleVehicle(
        type: type,
        lane: lane,
        initialPosition: Vector2(laneCenterX, -120),
      );

      add(obstacle);
    }
  }

  void _handleItemSpawning(double dt) {
    itemSpawnTimer += dt;

    // Spawn an item roughly every 4.0 - 5.5 seconds
    if (itemSpawnTimer >= 4.5) {
      itemSpawnTimer = 0.0;

      // Pick random lane
      final lane = Lane.values[_rng.nextInt(Lane.values.length)];
      final laneCenterX = RoadConfig.getLaneCenterX(
        lane: lane,
        roadWidth: roadBackground.roadWidth,
        roadStartX: roadBackground.roadStartX,
      );

      // Pick item type:
      // If lives < 3, higher chance for First Aid Kit
      ItemType type;
      final rand = _rng.nextDouble();
      if (lives < 3 && rand < 0.45) {
        type = ItemType.firstAidKit;
      } else if (rand < 0.65) {
        type = ItemType.energyCapsule;
      } else {
        type = ItemType.goldenStar;
      }

      final pickup = ItemPickup(
        type: type,
        lane: lane,
        initialPosition: Vector2(laneCenterX, -80),
      );

      add(pickup);
    }
  }
}
