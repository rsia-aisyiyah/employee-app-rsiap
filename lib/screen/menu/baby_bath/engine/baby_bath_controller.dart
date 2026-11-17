import 'dart:async';
import 'package:flutter/material.dart';
import '../models/baby_bath_models.dart';
import 'foam_particle_system.dart';

/// Controller Utama Game Memandikan Bayi (State Machine, SOP Engine & Eye Sensitivity)
class BabyBathController extends ChangeNotifier {
  BathPhase phase = BathPhase.waterPrep;
  BathTool activeTool = BathTool.waterTap;
  BabyMood mood = BabyMood.neutral;

  // Antrean Bayi di Ruang Perinatologi
  final List<BabyProfile> babyQueue = const [
    BabyProfile(id: 1, motherName: "Bayi Ny. Annisa", gender: "P", initialTemp: 32.0, swaddleColor: Color(0xFFFBCFE8)),
    BabyProfile(id: 2, motherName: "Bayi Ny. Fatimah", gender: "L", initialTemp: 31.0, swaddleColor: Color(0xFFBAE6FD)),
    BabyProfile(id: 3, motherName: "Bayi Ny. Khadijah", gender: "P", initialTemp: 33.5, swaddleColor: Color(0xFFDDD6FE)),
    BabyProfile(id: 4, motherName: "Bayi Ny. Zahra", gender: "P", initialTemp: 30.5, swaddleColor: Color(0xFFFEF08A)),
    BabyProfile(id: 5, motherName: "Bayi Ny. Maryam", gender: "L", initialTemp: 32.5, swaddleColor: Color(0xFFA7F3D0)),
  ];

  int currentBabyIndex = 0;
  BabyProfile get currentBaby => babyQueue[currentBabyIndex % babyQueue.length];

  // Parameter Fisika & Status
  double waterLevel = 0.2; // 0.0 - 1.0
  double waterTemp = 32.0; // Suhu air ideal: 36.5 - 37.5 °C
  double cleanlinessProgress = 0.0; // 0.0 - 1.0
  double comfortMeter = 85.0; // 0 - 100
  int score = 0;
  int completedBabiesCount = 0;
  bool isBabyInCrib = false;
  double shiftSecondsRemaining = 120.0; // 2 Menit Shift Challenge
  bool isCompleted = false;

  // Posisi Mainan Bebek Karet
  Offset duckPosition = const Offset(80, 240);
  bool isDuckSqueaking = false;

  // Notifikasi Teks Mengambang (Floating Feedback Toasts)
  final List<BabyFloatingToast> floatingToasts = [];

  final FoamParticleSystem particleSystem = FoamParticleSystem();
  Timer? _gameLoopTimer;
  Timer? _duckSqueakTimer;
  Timer? _moodResetTimer;

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
    currentBabyIndex = 0;
    completedBabiesCount = 0;
    isBabyInCrib = false;
    shiftSecondsRemaining = 120.0;
    phase = BathPhase.waterPrep;
    activeTool = BathTool.waterTap;
    mood = currentBaby.initialMood;
    waterLevel = 0.2;
    waterTemp = currentBaby.initialTemp;
    cleanlinessProgress = 0.0;
    comfortMeter = 85.0;
    score = 0;
    isCompleted = false;
    floatingToasts.clear();
    particleSystem.clear();
    start();
    notifyListeners();
  }

  /// Memilih alat dari palet bawah
  void selectTool(BathTool tool) {
    activeTool = tool;
    notifyListeners();
  }

  /// Tampilkan notifikasi floating di atas canvas
  void addFloatingToast(String text, {bool isWarning = false, required Offset position}) {
    // Batasi maksimal 4 toast aktif bersamaan
    if (floatingToasts.length >= 4) {
      floatingToasts.removeAt(0);
    }
    floatingToasts.add(BabyFloatingToast(
      text: text,
      isWarning: isWarning,
      position: position,
    ));
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
    if (waterTemp >= 36.5 && waterTemp <= 37.5) {
      mood = BabyMood.happy;
      comfortMeter = (comfortMeter + 2).clamp(0, 100);
      addFloatingToast("✨ Suhu air ideal 37°C!", position: const Offset(160, 220));
    } else if (waterTemp > 38.5) {
      mood = BabyMood.crying;
      comfortMeter = (comfortMeter - 5).clamp(0, 100);
      addFloatingToast("🔥 Terlalu panas! Tambah air dingin!", isWarning: true, position: const Offset(160, 220));
    } else if (waterTemp < 34.0) {
      mood = BabyMood.crying;
      comfortMeter = (comfortMeter - 5).clamp(0, 100);
      addFloatingToast("❄️ Terlalu dingin! Tambah air hangat!", isWarning: true, position: const Offset(160, 220));
    } else {
      mood = BabyMood.neutral;
    }
  }

  /// Interaksi Sentuh pada Karakter / Bak Mandi dengan Deteksi Area Sensitif Mata & SOP
  void onTouch(Offset localPos, [Size screenSize = const Size(360, 640)]) {
    final cx = screenSize.width / 2;
    final cy = screenSize.height * 0.46;
    final babyY = cy - 25;

    // Koordinat anatomis mata bayi
    final leftEye = Offset(cx - 24, babyY - 1);
    final rightEye = Offset(cx + 24, babyY - 1);
    final distLeftEye = (localPos - leftEye).distance;
    final distRightEye = (localPos - rightEye).distance;
    final isEyeContact = distLeftEye < 18 || distRightEye < 18;

    switch (phase) {
      case BathPhase.waterPrep:
        _handleDuckTouch(localPos);
        break;

      case BathPhase.faceAndHair:
        if (isEyeContact) {
          // ── KENA MATA BAYI (PENALTI SOP) ──
          if (activeTool == BathTool.shampoo || activeTool == BathTool.soapSponge) {
            mood = BabyMood.crying;
            comfortMeter = (comfortMeter - 10).clamp(0, 100);
            score = (score - 20).clamp(0, 99999);
            particleSystem.spawnWaterSplash(localPos.dx, localPos.dy, count: 4);
            addFloatingToast("⚠️ Pedih! Sabun masuk ke mata bayi! (-20)", isWarning: true, position: localPos);
            _scheduleMoodReset();
          } else if (activeTool == BathTool.cottonPad) {
            mood = BabyMood.crying;
            comfortMeter = (comfortMeter - 4).clamp(0, 100);
            score = (score - 10).clamp(0, 99999);
            addFloatingToast("⚠️ Usap kelopak mata lembut dari arah dalam ke luar! (-10)", isWarning: true, position: localPos);
            _scheduleMoodReset();
          }
        } else {
          // ── USAPAN AMAN PADA WAJAH / RAMBUT ──
          if (activeTool == BathTool.cottonPad) {
            // Usap pipi, dahi, dagu
            cleanlinessProgress = (cleanlinessProgress + 0.045).clamp(0.0, 1.0);
            score += 15;
            comfortMeter = (comfortMeter + 1.2).clamp(0, 100);
            mood = BabyMood.happy;
            particleSystem.spawnFoam(localPos.dx, localPos.dy, count: 2);
            addFloatingToast("✨ Usapan Wajah Lembut (+15)", position: localPos);

            if (cleanlinessProgress >= 1.0) {
              _advanceToNextPhase();
            }
          } else if (activeTool == BathTool.shampoo) {
            // Keramas rambut di atas dahi
            if (localPos.dy < babyY + 5) {
              cleanlinessProgress = (cleanlinessProgress + 0.04).clamp(0.0, 1.0);
              score += 20;
              comfortMeter = (comfortMeter + 1.5).clamp(0, 100);
              mood = BabyMood.happy;
              particleSystem.spawnFoam(localPos.dx, localPos.dy, count: 4);
              addFloatingToast("🫧 Keramas rambut harum (+20)", position: localPos);

              if (cleanlinessProgress >= 1.0) {
                _advanceToNextPhase();
              }
            } else {
              addFloatingToast("Sampo khusus untuk rambut kepala!", isWarning: true, position: localPos);
            }
          }
        }
        break;

      case BathPhase.bodyScrub:
        _handleDuckTouch(localPos);
        if (isEyeContact && activeTool == BathTool.soapSponge) {
          // Sabun badan mengenai mata
          mood = BabyMood.crying;
          comfortMeter = (comfortMeter - 8).clamp(0, 100);
          score = (score - 15).clamp(0, 99999);
          addFloatingToast("⚠️ Jangan gunakan spons sabun badan ke area mata!", isWarning: true, position: localPos);
          _scheduleMoodReset();
        } else if (activeTool == BathTool.soapSponge) {
          cleanlinessProgress = (cleanlinessProgress + 0.035).clamp(0.0, 1.0);
          score += 20;
          particleSystem.spawnFoam(localPos.dx, localPos.dy, count: 4);
          mood = BabyMood.giggling;
          addFloatingToast("🧼 Gosok ketiak & lipatan badan (+20)", position: localPos);

          if (cleanlinessProgress >= 1.0) {
            _advanceToNextPhase();
          }
        }
        break;

      case BathPhase.rinsing:
        _handleDuckTouch(localPos);
        if (activeTool == BathTool.showerSpray) {
          if (isEyeContact) {
            addFloatingToast("⚠️ Lindungi dahi bayi saat menyiram air!", isWarning: true, position: localPos);
            comfortMeter = (comfortMeter - 4).clamp(0, 100);
            mood = BabyMood.crying;
            _scheduleMoodReset();
          } else {
            final removed = particleSystem.rinseNear(localPos.dx, localPos.dy, 45);
            particleSystem.spawnWaterSplash(localPos.dx, localPos.dy, count: 3);
            cleanlinessProgress = (cleanlinessProgress + 0.04).clamp(0.0, 1.0);
            score += (removed * 10) + 15;
            comfortMeter = (comfortMeter + 1.0).clamp(0, 100);
            mood = BabyMood.happy;
            addFloatingToast("🚿 Pembilasan air hangat segar (+15)", position: localPos);

            if (cleanlinessProgress >= 1.0 && particleSystem.bubbles.isEmpty) {
              _advanceToNextPhase();
            }
          }
        }
        break;

      case BathPhase.dryingCare:
        if (activeTool == BathTool.softTowel) {
          cleanlinessProgress = (cleanlinessProgress + 0.05).clamp(0.0, 1.0);
          score += 25;
          comfortMeter = (comfortMeter + 2.0).clamp(0, 100);
          mood = BabyMood.happy;
          addFloatingToast("🧸 Keringkan dengan handuk lembut (+25)", position: localPos);

          if (cleanlinessProgress >= 1.0) {
            _advanceToNextPhase();
          }
        } else if (activeTool == BathTool.babyOil) {
          cleanlinessProgress = (cleanlinessProgress + 0.06).clamp(0.0, 1.0);
          score += 30;
          comfortMeter = (comfortMeter + 3.0).clamp(0, 100);
          mood = BabyMood.giggling;
          addFloatingToast("🌿 Oleskan minyak telon wangi & hangat (+30)", position: localPos);

          if (cleanlinessProgress >= 1.0) {
            _advanceToNextPhase();
          }
        }
        break;

      case BathPhase.returnToCrib:
        if (!isBabyInCrib) {
          putBabyInCrib();
        }
        break;

      case BathPhase.completed:
        break;
    }

    notifyListeners();
  }

  void _scheduleMoodReset() {
    _moodResetTimer?.cancel();
    _moodResetTimer = Timer(const Duration(milliseconds: 1400), () {
      if (comfortMeter > 60) {
        mood = BabyMood.neutral;
      } else if (comfortMeter < 40) {
        mood = BabyMood.crying;
      }
      notifyListeners();
    });
  }

  /// Cek interaksi menekan bebek karet mainan
  void _handleDuckTouch(Offset localPos) {
    final dist = (localPos - duckPosition).distance;
    if (dist < 45) {
      isDuckSqueaking = true;
      mood = BabyMood.giggling;
      comfortMeter = (comfortMeter + 6).clamp(0, 100);
      score += 35;
      particleSystem.spawnWaterSplash(duckPosition.dx, duckPosition.dy, count: 6);
      addFloatingToast("🦆 Kwek kwek! Bayi senang (+35)", position: duckPosition);

      _duckSqueakTimer?.cancel();
      _duckSqueakTimer = Timer(const Duration(milliseconds: 350), () {
        isDuckSqueaking = false;
        notifyListeners();
      });
    }
  }

  /// Menaruh Bayi ke Tempat Tidur Bayi (Baby Crib)
  void putBabyInCrib() {
    if (isBabyInCrib) return;
    isBabyInCrib = true;
    completedBabiesCount++;
    score += 150;
    comfortMeter = 100.0;
    mood = BabyMood.happy;
    addFloatingToast("✨ ${currentBaby.motherName} aman & nyaman di boks! (+150)", position: const Offset(160, 200));
    notifyListeners();

    // Beri jeda 2.2 detik untuk animasi tidur damai, lalu panggil bayi berikutnya
    Timer(const Duration(milliseconds: 2200), () {
      if (!isCompleted) {
        if (completedBabiesCount >= babyQueue.length || shiftSecondsRemaining <= 0) {
          _finishGame();
        } else {
          loadNextBaby();
        }
      }
    });
  }

  /// Memuat Bayi Berikutnya dalam Antrean Shift
  void loadNextBaby() {
    currentBabyIndex++;
    isBabyInCrib = false;
    phase = BathPhase.waterPrep;
    activeTool = BathTool.waterTap;
    cleanlinessProgress = 0.0;
    comfortMeter = 85.0;
    waterTemp = currentBaby.initialTemp;
    mood = currentBaby.initialMood;
    particleSystem.clear();
    addFloatingToast("👶 Menyambut ${currentBaby.motherName}! Cek suhu air dahulu.", position: const Offset(160, 180));
    notifyListeners();
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
        addFloatingToast("Fase 2: Bersihkan wajah & keramas!", position: const Offset(150, 150));
        break;
      case BathPhase.faceAndHair:
        phase = BathPhase.bodyScrub;
        activeTool = BathTool.soapSponge;
        addFloatingToast("Fase 3: Gosok badan dengan spons sabun!", position: const Offset(150, 150));
        break;
      case BathPhase.bodyScrub:
        phase = BathPhase.rinsing;
        activeTool = BathTool.showerSpray;
        addFloatingToast("Fase 4: Bilas busa hingga bersih!", position: const Offset(150, 150));
        break;
      case BathPhase.rinsing:
        phase = BathPhase.dryingCare;
        activeTool = BathTool.softTowel;
        addFloatingToast("Fase 5: Keringkan handuk & telon!", position: const Offset(150, 150));
        break;
      case BathPhase.dryingCare:
        phase = BathPhase.returnToCrib;
        activeTool = BathTool.cribAction;
        addFloatingToast("Fase 6: Pindahkan ${currentBaby.motherName} ke tempat tidur boks!", position: const Offset(150, 150));
        break;
      case BathPhase.returnToCrib:
        if (!isBabyInCrib) {
          putBabyInCrib();
        }
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
    if (!isCompleted) {
      shiftSecondsRemaining -= dt;
      if (shiftSecondsRemaining <= 0) {
        shiftSecondsRemaining = 0;
        _finishGame();
      }

      // Comfort meter sedikit berkurang perlahan jika didiamkan
      if (comfortMeter > 10) {
        comfortMeter = (comfortMeter - 0.2 * dt).clamp(0, 100);
      }
    }

    // Update floating toasts
    for (final toast in floatingToasts) {
      toast.lifeTime -= dt;
      toast.yOffset -= 22 * dt;
    }
    floatingToasts.removeWhere((t) => t.lifeTime <= 0);
  }

  /// Menghitung Bintang Prestasi (Berdasarkan jumlah bayi selesai & kenyamanan)
  int calculateStars() {
    if (completedBabiesCount >= 3 && comfortMeter >= 65) {
      return 3;
    } else if (completedBabiesCount >= 2) {
      return 2;
    } else if (completedBabiesCount >= 1) {
      return 1;
    }
    return 1;
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _duckSqueakTimer?.cancel();
    _moodResetTimer?.cancel();
    super.dispose();
  }
}
