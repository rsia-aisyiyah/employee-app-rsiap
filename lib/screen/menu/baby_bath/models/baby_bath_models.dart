import 'package:flutter/material.dart';

/// Tahapan (Fase) Memandikan Bayi sesuai SOP Medis RSIA
enum BathPhase {
  waterPrep,  // 1. Mengatur suhu air hangat & mengecek termometer
  faceAndHair,// 2. Membersihkan wajah dengan kapas & keramas sampo bayi
  bodyScrub,  // 3. Menggosok sabun & bermain bebek air di bak mandi
  rinsing,    // 4. Membilas seluruh badan dengan air bersih
  dryingCare, // 5. Mengeringkan dengan handuk, mengoles minyak telon & bedak
  completed,  // Mandi selesai dengan hasil bintang 1-3
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
