import 'package:flutter/material.dart';

/// Tahapan (Fase) Memandikan Bayi sesuai SOP Medis RSIA
enum BathPhase {
  waterPrep,   // 1. Mengatur suhu air hangat & mengecek termometer
  faceAndHair, // 2. Membersihkan wajah dengan kapas & keramas sampo bayi
  bodyScrub,   // 3. Menggosok sabun & bermain bebek air di bak mandi
  rinsing,     // 4. Membilas seluruh badan dengan air bersih
  dryingCare,  // 5. Mengeringkan dengan handuk, mengoles minyak telon & bedong
  returnToCrib,// 6. Mengembalikan bayi ke tempat tidur boks bayi (Baby Crib)
  completed,   // Shift selesai dengan evaluasi multi-bayi
}

/// Tipe alat yang sedang aktif digunakan
enum BathTool {
  none,
  waterTap,     // Kran pengisi air panas / dingin
  thermometer,  // Termometer air bebek
  cottonPad,    // Kapas basah steril untuk wajah
  shampoo,      // Sampo bayi anti-pedih
  soapSponge,   // Spons lembut sabun
  showerSpray,  // Shower / gayung bilas air hangat
  rubberDuck,   // Bebek karet mainan (mood booster)
  softTowel,    // Handuk lembut penghangat
  babyOil,      // Minyak telon harum
  cribAction,   // Aksi meletakkan bayi ke tempat tidur boks
}

/// Profil Bayi dalam Antrean Shift Perinatologi
class BabyProfile {
  final int id;
  final String motherName; // misal "Ny. Annisa", "Ny. Fatimah"
  final String gender;     // "L" / "P"
  final double initialTemp;
  final BabyMood initialMood;
  final Color swaddleColor;

  const BabyProfile({
    required this.id,
    required this.motherName,
    required this.gender,
    this.initialTemp = 32.0,
    this.initialMood = BabyMood.neutral,
    this.swaddleColor = const Color(0xFFBAE6FD),
  });
}

/// Ekspresi emosi bayi
enum BabyMood {
  happy,   // Senang, tersenyum riang
  giggling,// Tertawa geli (misal saat ditepuk bebek / digosok lembut)
  neutral, // Tenang melihat sekitar
  crying,  // Menangis (air terlalu panas/dingin atau sabun kena mata)
}

/// Model partikel busa sabun
class FoamBubble {
  double x;
  double y;
  double radius;
  double alpha;
  double vx;
  double vy;
  Color color;
  bool isPopping;

  FoamBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
    this.vx = 0,
    this.vy = 0,
    required this.color,
    this.isPopping = false,
  });
}

/// Model partikel percikan air
class WaterSplashParticle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double alpha;
  Color color;

  WaterSplashParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.alpha,
    required this.color,
  });
}

/// Model teks notifikasi melayang (Floating Feedback Toast)
class BabyFloatingToast {
  final String text;
  final bool isWarning;
  final Offset position;
  double lifeTime; // in seconds
  double yOffset;

  BabyFloatingToast({
    required this.text,
    required this.isWarning,
    required this.position,
    this.lifeTime = 1.2,
    this.yOffset = 0.0,
  });
}

/// Model Titik Noda Visual & Area Pembersihan Anatomi Bayi
class BabyDirtSpot {
  final String id;
  final String name;
  final double dxOffset; // relatif thd cx
  final double dyOffset; // relatif thd babyY
  final BathPhase phase;
  final BathTool requiredTool;
  final double radius;
  final Color spotColor;

  double cleanliness; // 0.0 (kotor) s/d 1.0 (bersih)
  bool isFoamed;      // apakah tertutup busa
  bool isRinsed;      // apakah busa sudah dibilas

  BabyDirtSpot({
    required this.id,
    required this.name,
    required this.dxOffset,
    required this.dyOffset,
    required this.phase,
    required this.requiredTool,
    this.radius = 16.0,
    this.spotColor = const Color(0xFFD97706),
    this.cleanliness = 0.0,
    this.isFoamed = false,
    this.isRinsed = false,
  });

  bool get isClean => cleanliness >= 1.0;

  void reset() {
    cleanliness = 0.0;
    isFoamed = false;
    isRinsed = false;
  }
}

