import 'dart:async';
import 'package:flutter/material.dart';
import '../models/baby_bath_models.dart';
import 'foam_particle_system.dart';

/// Controller Utama Game Memandikan Bayi (State Machine & SOP Engine)
class BabyBathController extends ChangeNotifier {
  BathPhase phase = BathPhase.waterPrep;
  BathTool activeTool = BathTool.waterTap;
  BabyMood mood = BabyMood.neutral;

  // Parameter Fisika & Status
  double waterLevel = 0.2; // 0.0 - 1.0
  double waterTemp = 32.0; // Suhu air ideal: 36.5 - 37.5 °C
  double cleanlinessProgress = 0.0; // 0.0 - 1.0
  double comfortMeter = 85.0; // 0 - 100
  int score = 0;
  int elapsedSeconds = 0;
  bool isCompleted = false;

  // Posisi Mainan Bebek Karet
  Offset duckPosition = const Offset(80, 240);
  bool isDuckSqueaking = false;

  final FoamParticleSystem particleSystem = FoamParticleSystem();
  Timer? _gameLoopTimer;
  Timer? _duckSqueakTimer;

  void start() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      particleSystem.update(0.033);
      _updateGameLoop(0.033);
      notifyListeners();
    });
  }

  void stop() {
    _gameLoopTimer?.cancel();
  }

  void restart() {
    phase = BathPhase.waterPrep;
    activeTool = BathTool.waterTap;
    mood = BabyMood.neutral;
    waterLevel = 0.2;
    waterTemp = 32.0;
    cleanlinessProgress = 0.0;
    comfortMeter = 85.0;
    score = 0;
    elapsedSeconds = 0;
    isCompleted = false;
    particleSystem.clear();
    start();
    notifyListeners();
  }

  /// Memilih alat dari palet bawah
  void selectTool(BathTool tool) {
    activeTool = tool;
    notifyListeners();
  }

  /// Tambah air hangat (menaikkan suhu dan volume)
  void addHotWater() {
    if (waterLevel < 0.95) waterLevel += 0.05;
    waterTemp = (waterTemp + 1.2).clamp(25.0, 45.0);
    _checkWaterTempMood();
    notifyListeners();
  }

  /// Tambah air dingin (menurunkan suhu dan volume)
  void addColdWater() {
    if (waterLevel < 0.95) waterLevel += 0.05;
    waterTemp = (waterTemp - 1.2).clamp(25.0, 45.0);
    _checkWaterTempMood();
    notifyListeners();
  }

  void _checkWaterTempMood() {
    if (waterTemp >= 36.0 && waterTemp <= 38.0) {
      mood = BabyMood.happy;
      comfortMeter = (comfortMeter + 2).clamp(0, 100);
    } else if (waterTemp > 39.0 || waterTemp < 33.0) {
      mood = BabyMood.crying;
      comfortMeter = (comfortMeter - 4).clamp(0, 100);
    } else {
      mood = BabyMood.neutral;
    }
  }

  /// Interaksi Sentuh pada Karakter / Bak Mandi
  void onTouch(Offset localPos) {
    switch (phase) {
      case BathPhase.waterPrep:
        // Cek interaksi bebek atau termometer
        _handleDuckTouch(localPos);
        break;

      case BathPhase.faceAndHair:
        if (activeTool == BathTool.cottonPad || activeTool == BathTool.shampoo) {
          cleanlinessProgress = (cleanlinessProgress + 0.035).clamp(0.0, 1.0);
          score += 15;
          particleSystem.spawnFoam(localPos.dx, localPos.dy, count: 2);
          mood = BabyMood.happy;

          if (cleanlinessProgress >= 1.0) {
            _advanceToNextPhase();
          }
        }
        break;

      case BathPhase.bodyScrub:
        _handleDuckTouch(localPos);
        if (activeTool == BathTool.soapSponge) {
          cleanlinessProgress = (cleanlinessProgress + 0.025).clamp(0.0, 1.0);
          score += 20;
          particleSystem.spawnFoam(localPos.dx, localPos.dy, count: 4);
          mood = BabyMood.giggling;

          if (cleanlinessProgress >= 1.0) {
            _advanceToNextPhase();
          }
        }
        break;

      case BathPhase.rinsing:
        _handleDuckTouch(localPos);
        if (activeTool == BathTool.showerSpray) {
          final removed = particleSystem.rinseNear(localPos.dx, localPos.dy, 45);
          cleanlinessProgress = (cleanlinessProgress + 0.035).clamp(0.0, 1.0);
          score += (removed * 10) + 15;
          mood = BabyMood.happy;

          if (cleanlinessProgress >= 1.0 && particleSystem.bubbles.isEmpty) {
            _advanceToNextPhase();
          }
        }
        break;

      case BathPhase.dryingCare:
        if (activeTool == BathTool.softTowel || activeTool == BathTool.babyOil) {
          cleanlinessProgress = (cleanlinessProgress + 0.035).clamp(0.0, 1.0);
          score += 25;
          mood = BabyMood.happy;

          if (cleanlinessProgress >= 1.0) {
            _finishGame();
          }
        }
        break;

      case BathPhase.completed:
        break;
    }

    notifyListeners();
  }

  /// Cek interaksi menekan bebek karet mainan
  void _handleDuckTouch(Offset localPos) {
    final dist = (localPos - duckPosition).distance;
    if (dist < 40) {
      isDuckSqueaking = true;
      mood = BabyMood.giggling;
      comfortMeter = (comfortMeter + 5).clamp(0, 100);
      score += 30;
      particleSystem.spawnWaterSplash(duckPosition.dx, duckPosition.dy, count: 5);

      _duckSqueakTimer?.cancel();
      _duckSqueakTimer = Timer(const Duration(milliseconds: 350), () {
        isDuckSqueaking = false;
        notifyListeners();
      });
    }
  }

  /// Melangkah ke Fase Berikutnya
  void advancePhaseManually() {
    _advanceToNextPhase();
  }

  void _advanceToNextPhase() {
    cleanlinessProgress = 0.0;

    switch (phase) {
      case BathPhase.waterPrep:
        phase = BathPhase.faceAndHair;
        activeTool = BathTool.cottonPad;
        break;
      case BathPhase.faceAndHair:
        phase = BathPhase.bodyScrub;
        activeTool = BathTool.soapSponge;
        break;
      case BathPhase.bodyScrub:
        phase = BathPhase.rinsing;
        activeTool = BathTool.showerSpray;
        break;
      case BathPhase.rinsing:
        phase = BathPhase.dryingCare;
        activeTool = BathTool.softTowel;
        break;
      case BathPhase.dryingCare:
        _finishGame();
        break;
      case BathPhase.completed:
        break;
    }
    notifyListeners();
  }

  void _finishGame() {
    phase = BathPhase.completed;
    isCompleted = true;
    _gameLoopTimer?.cancel();
    notifyListeners();
  }

  void _updateGameLoop(double dt) {
    // Comfort meter sedikit berkurang perlahan jika didiamkan
    if (!isCompleted && comfortMeter > 10) {
      comfortMeter = (comfortMeter - 0.2 * dt).clamp(0, 100);
    }
  }

  /// Menghitung Bintang Prestasi (1 - 3 Bintang)
  int calculateStars() {
    if (comfortMeter >= 80 && waterTemp >= 36.0 && waterTemp <= 38.0) {
      return 3;
    } else if (comfortMeter >= 50) {
      return 2;
    }
    return 1;
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _duckSqueakTimer?.cancel();
    super.dispose();
  }
}
