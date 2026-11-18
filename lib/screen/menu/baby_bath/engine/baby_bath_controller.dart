import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
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
  bool isSubmittingScore = false;
  bool isScoreSubmitted = false;
  String? scoreSubmitMessage;

  // Daftar Titik Noda Visual & Area Anatomi Pembersihan Medis
  List<BabyDirtSpot> dirtSpots = [];

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
    _initDirtSpots();
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

  void _initDirtSpots() {
    dirtSpots = [
      // ── Fase 2: Wajah & Rambut (Face & Scalp Care) ──
      BabyDirtSpot(
        id: 'spot_forehead',
        name: 'Dahi Bayi',
        dxOffset: 0,
        dyOffset: -24,
        phase: BathPhase.faceAndHair,
        requiredTool: BathTool.cottonPad,
        radius: 14,
        spotColor: const Color(0xFFD97706),
      ),
      BabyDirtSpot(
        id: 'spot_cheek_l',
        name: 'Pipi Kiri',
        dxOffset: -26,
        dyOffset: 10,
        phase: BathPhase.faceAndHair,
        requiredTool: BathTool.cottonPad,
        radius: 13,
        spotColor: const Color(0xFFD97706),
      ),
      BabyDirtSpot(
        id: 'spot_cheek_r',
        name: 'Pipi Kanan',
        dxOffset: 26,
        dyOffset: 10,
        phase: BathPhase.faceAndHair,
        requiredTool: BathTool.cottonPad,
        radius: 13,
        spotColor: const Color(0xFFD97706),
      ),
      BabyDirtSpot(
        id: 'spot_hair',
        name: 'Rambut Kepala',
        dxOffset: 0,
        dyOffset: -54,
        phase: BathPhase.faceAndHair,
        requiredTool: BathTool.shampoo,
        radius: 18,
        spotColor: const Color(0xFF78350F),
      ),

      // ── Fase 3: Gosok Sabun Tubuh (Body Scrub) ──
      BabyDirtSpot(
        id: 'spot_neck',
        name: 'Lipatan Leher',
        dxOffset: 0,
        dyOffset: 38,
        phase: BathPhase.bodyScrub,
        requiredTool: BathTool.soapSponge,
        radius: 15,
        spotColor: const Color(0xFFB45309),
      ),
      BabyDirtSpot(
        id: 'spot_chest',
        name: 'Dada & Perut',
        dxOffset: 0,
        dyOffset: 65,
        phase: BathPhase.bodyScrub,
        requiredTool: BathTool.soapSponge,
        radius: 18,
        spotColor: const Color(0xFFB45309),
      ),
      BabyDirtSpot(
        id: 'spot_arm_l',
        name: 'Ketiak & Lengan Kiri',
        dxOffset: -38,
        dyOffset: 52,
        phase: BathPhase.bodyScrub,
        requiredTool: BathTool.soapSponge,
        radius: 14,
        spotColor: const Color(0xFFB45309),
      ),
      BabyDirtSpot(
        id: 'spot_arm_r',
        name: 'Ketiak & Lengan Kanan',
        dxOffset: 38,
        dyOffset: 52,
        phase: BathPhase.bodyScrub,
        requiredTool: BathTool.soapSponge,
        radius: 14,
        spotColor: const Color(0xFFB45309),
      ),
      BabyDirtSpot(
        id: 'spot_groin',
        name: 'Lipatan Paha',
        dxOffset: 0,
        dyOffset: 95,
        phase: BathPhase.bodyScrub,
        requiredTool: BathTool.soapSponge,
        radius: 16,
        spotColor: const Color(0xFFB45309),
      ),

      // ── Fase 5: Keringkan & Telon (Drying Care) ──
      BabyDirtSpot(
        id: 'spot_dry_head',
        name: 'Keringkan Rambut',
        dxOffset: 0,
        dyOffset: -45,
        phase: BathPhase.dryingCare,
        requiredTool: BathTool.softTowel,
        radius: 18,
        spotColor: const Color(0xFF38BDF8),
      ),
      BabyDirtSpot(
        id: 'spot_dry_body',
        name: 'Keringkan Tubuh',
        dxOffset: 0,
        dyOffset: 55,
        phase: BathPhase.dryingCare,
        requiredTool: BathTool.softTowel,
        radius: 20,
        spotColor: const Color(0xFF38BDF8),
      ),
      BabyDirtSpot(
        id: 'spot_telon',
        name: 'Minyak Telon Hangat',
        dxOffset: 0,
        dyOffset: 68,
        phase: BathPhase.dryingCare,
        requiredTool: BathTool.babyOil,
        radius: 18,
        spotColor: const Color(0xFF10B981),
      ),
    ];
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
    isSubmittingScore = false;
    floatingToasts.clear();
    particleSystem.clear();
    _initDirtSpots();
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

  /// Handler Gestur Tap Langsung
  void onTapDown(Offset localPos, [Size screenSize = const Size(360, 640)]) {
    // Interaksi bebek mainan
    _handleDuckTouch(localPos);

    if (phase == BathPhase.returnToCrib && !isBabyInCrib) {
      putBabyInCrib();
      return;
    }

    // Jika di fase air, beri feedback
    if (phase == BathPhase.waterPrep) {
      if (waterTemp >= 36.5 && waterTemp <= 37.5) {
        _advanceToNextPhase();
      } else {
        addFloatingToast("Sesuaikan suhu air 36.5°C - 37.5°C terlebih dahulu!", isWarning: true, position: localPos);
      }
    }
  }

  /// Handler Gestur Usap / Pan Berirama (Deteksi Kecepatan & Area Titik Medis)
  void onPanUpdate(Offset localPos, Offset delta, [Size screenSize = const Size(360, 640)]) {
    final cx = screenSize.width / 2;
    final cy = screenSize.height * 0.46;
    final babyY = cy - 25;

    // 1. Cek Kecepatan Usapan (Roughness Detection)
    final speed = delta.distance;
    if (speed > 36.0) {
      // Usapan terlalu cepat/kasar: Bayi terkejut/menangis!
      mood = BabyMood.crying;
      comfortMeter = (comfortMeter - 1.2).clamp(0, 100);
      score = (score - 5).clamp(0, 99999);
      particleSystem.spawnWaterSplash(localPos.dx, localPos.dy, count: 2);
      addFloatingToast("⚠️ Terlalu kasar! Usap dengan lembut perlahan", isWarning: true, position: localPos);
      _scheduleMoodReset();
      notifyListeners();
      return;
    }

    // 2. Deteksi Area Mata Bayi (Sensitivitas Sabun/Sampo)
    final leftEye = Offset(cx - 24, babyY - 1);
    final rightEye = Offset(cx + 24, babyY - 1);
    final distLeftEye = (localPos - leftEye).distance;
    final distRightEye = (localPos - rightEye).distance;
    final isEyeContact = distLeftEye < 18 || distRightEye < 18;

    if (isEyeContact && (activeTool == BathTool.shampoo || activeTool == BathTool.soapSponge)) {
      mood = BabyMood.crying;
      comfortMeter = (comfortMeter - 4).clamp(0, 100);
      score = (score - 10).clamp(0, 99999);
      particleSystem.spawnWaterSplash(localPos.dx, localPos.dy, count: 3);
      addFloatingToast("⚠️ Pedih! Sabun masuk ke mata bayi! (-10)", isWarning: true, position: localPos);
      _scheduleMoodReset();
      notifyListeners();
      return;
    }

    // 3. Proses Titik Noda Medis Sesuai Fase Aktif
    switch (phase) {
      case BathPhase.waterPrep:
        _handleDuckTouch(localPos);
        break;

      case BathPhase.faceAndHair:
      case BathPhase.bodyScrub:
      case BathPhase.dryingCare:
        _processDirtSpotsCleaning(localPos, cx, babyY);
        break;

      case BathPhase.rinsing:
        _processRinsingFoam(localPos, cx, babyY);
        break;

      case BathPhase.returnToCrib:
        if (!isBabyInCrib) putBabyInCrib();
        break;

      case BathPhase.completed:
        break;
    }

    notifyListeners();
  }

  /// Backward-compatibility untuk onTouch (delegasi ke onPanUpdate)
  void onTouch(Offset localPos, [Size screenSize = const Size(360, 640)]) {
    onPanUpdate(localPos, const Offset(5, 5), screenSize);
  }

  /// Membersihkan titik noda visual dengan alat medis yang tepat
  void _processDirtSpotsCleaning(Offset localPos, double cx, double babyY) {
    // Ambil spot yang cocok dengan fase saat ini
    final currentSpots = dirtSpots.where((s) => s.phase == phase).toList();
    if (currentSpots.isEmpty) return;

    for (final spot in currentSpots) {
      final spotWorldPos = Offset(cx + spot.dxOffset, babyY + spot.dyOffset);
      final dist = (localPos - spotWorldPos).distance;

      // Jarak toleransi sentuh ke spot
      if (dist <= spot.radius + 20) {
        if (spot.requiredTool == activeTool) {
          // Alat tepat: bersihkan noda
          if (!spot.isClean) {
            spot.cleanliness = (spot.cleanliness + 0.05).clamp(0.0, 1.0);
            spot.isFoamed = true;
            score += 10;
            comfortMeter = (comfortMeter + 0.4).clamp(0, 100);
            mood = BabyMood.happy;

            if (activeTool == BathTool.shampoo || activeTool == BathTool.soapSponge) {
              particleSystem.spawnFoam(spotWorldPos.dx, spotWorldPos.dy, count: 2);
            } else if (activeTool == BathTool.babyOil) {
              particleSystem.spawnWaterSplash(spotWorldPos.dx, spotWorldPos.dy, count: 1);
            }

            if (spot.isClean) {
              addFloatingToast("✓ ${spot.name} Bersih!", position: spotWorldPos);
            }
          }
        } else {
          // Alat salah untuk spot ini
          final toolName = _getToolName(spot.requiredTool);
          addFloatingToast("Gunakan $toolName untuk ${spot.name}!", isWarning: true, position: localPos);
        }
      }
    }

    // Hitung persentase kebersihan akumulatif fase saat ini
    final cleanSpots = currentSpots.where((s) => s.isClean).length;
    cleanlinessProgress = cleanSpots / currentSpots.length;

    // Jika seluruh titik pada fase ini sudah bersih tuntas, lanjutkan fase otomatis!
    if (cleanlinessProgress >= 1.0) {
      score += 50;
      addFloatingToast("✨ Sempurna! Lanjut ke langkah berikutnya (+50)", position: Offset(cx, babyY));
      _advanceToNextPhase();
    }
  }

  /// Pembilasan Busa Sabun dengan Shower Air Hangat di Fase Rinsing
  void _processRinsingFoam(Offset localPos, double cx, double babyY) {
    _handleDuckTouch(localPos);

    if (activeTool != BathTool.showerSpray) {
      addFloatingToast("Gunakan Shower Air untuk membilas!", isWarning: true, position: localPos);
      return;
    }

    particleSystem.spawnWaterSplash(localPos.dx, localPos.dy, count: 3);
    particleSystem.rinseNear(localPos.dx, localPos.dy, 45);

    final foamedSpots = dirtSpots.where((s) => s.isFoamed && !s.isRinsed).toList();
    for (final spot in foamedSpots) {
      final spotWorldPos = Offset(cx + spot.dxOffset, babyY + spot.dyOffset);
      if ((localPos - spotWorldPos).distance <= spot.radius + 25) {
        spot.isRinsed = true;
        score += 20;
        comfortMeter = (comfortMeter + 0.8).clamp(0, 100);
        mood = BabyMood.happy;
        addFloatingToast("🫧 Busa di ${spot.name} terbilas!", position: spotWorldPos);
      }
    }

    // Progres pembilasan
    final totalFoamed = dirtSpots.where((s) => s.isFoamed).length;
    final rinsedCount = dirtSpots.where((s) => s.isFoamed && s.isRinsed).length;
    cleanlinessProgress = totalFoamed > 0 ? (rinsedCount / totalFoamed).clamp(0.0, 1.0) : 1.0;

    if (cleanlinessProgress >= 1.0) {
      score += 60;
      addFloatingToast("🚿 Seluruh busa dibilas tuntas! (+60)", position: Offset(cx, babyY));
      _advanceToNextPhase();
    }
  }

  String _getToolName(BathTool tool) {
    switch (tool) {
      case BathTool.waterTap:
        return "Kran Air";
      case BathTool.thermometer:
        return "Termometer Air";
      case BathTool.cottonPad:
        return "Kapas Wajah";
      case BathTool.shampoo:
        return "Sampo Bayi";
      case BathTool.soapSponge:
        return "Spons Sabun";
      case BathTool.showerSpray:
        return "Shower Bilas";
      case BathTool.rubberDuck:
        return "Bebek Karet";
      case BathTool.softTowel:
        return "Handuk Lembut";
      case BathTool.babyOil:
        return "Minyak Telon";
      case BathTool.cribAction:
        return "Tempat Tidur Bayi";
      case BathTool.none:
        return "Tangan Bersih";
    }
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
    submitScoreToBackend();
  }

  /// Kirim skor dan data shift ke database backend RSIA API
  Future<void> submitScoreToBackend() async {
    if (isSubmittingScore || isScoreSubmitted) return;

    isSubmittingScore = true;
    notifyListeners();

    try {
      final payload = {
        'score': score,
        'completed_babies': completedBabiesCount,
        'avg_comfort': comfortMeter.round(),
        'duration_seconds': (120 - shiftSecondsRemaining).round(),
        'stars': calculateStars(),
      };

      final res = await Api().postData(payload, '/game/baby-bath/submit');
      if (res.statusCode == 200 || res.statusCode == 201) {
        isScoreSubmitted = true;
        scoreSubmitMessage = "Skor berhasil disimpan di Leaderboard!";
      } else {
        scoreSubmitMessage = "Gagal menyimpan skor (${res.statusCode})";
      }
    } catch (e) {
      scoreSubmitMessage = "Gagal terhubung ke server untuk menyimpan skor";
    } finally {
      isSubmittingScore = false;
      notifyListeners();
    }
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
