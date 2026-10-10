import 'package:flutter/material.dart';

class VirusBusterStats {
  final int score;
  final int virusesDefeated;
  final int stage;
  final int lives;
  final int maxLives;
  final double powerupTimer;
  final String activePowerupName;
  final double stageProgress; // 0.0 to 1.0

  const VirusBusterStats({
    this.score = 0,
    this.virusesDefeated = 0,
    this.stage = 1,
    this.lives = 3,
    this.maxLives = 3,
    this.powerupTimer = 0.0,
    this.activePowerupName = '',
    this.stageProgress = 0.0,
  });

  VirusBusterStats copyWith({
    int? score,
    int? virusesDefeated,
    int? stage,
    int? lives,
    int? maxLives,
    double? powerupTimer,
    String? activePowerupName,
    double? stageProgress,
  }) {
    return VirusBusterStats(
      score: score ?? this.score,
      virusesDefeated: virusesDefeated ?? this.virusesDefeated,
      stage: stage ?? this.stage,
      lives: lives ?? this.lives,
      maxLives: maxLives ?? this.maxLives,
      powerupTimer: powerupTimer ?? this.powerupTimer,
      activePowerupName: activePowerupName ?? this.activePowerupName,
      stageProgress: stageProgress ?? this.stageProgress,
    );
  }
}

enum VirusType {
  // Stage 1 (Drop-Off IGD & Area Luar)
  fluGoo, // Slime hijau lendir merayap di tanah (bisa diinjak Mario Stomp)
  dustMite, // Partikel debu/alergen melayang zigzag
  mosquito, // Nyamuk Aedes bergaris loreng menukik cepat
  bossStage1, // Boss Titan Flu (raksasa kuning-keemasan lendir)

  // Stage 2 (Lobi & Ruang Tunggu Poliklinik)
  spikeCorona, // Duri merah aerosol berputar & melayang sinusoidal
  bacillus, // Bakteri batang kapsul ungu neon berotasi
  toxicDroplet, // Droplet batuk toska meluncur diagonal cepat
  bossStage2, // Boss Apex Delta Corona (raksasa merah membara dengan mahkota spike)

  // Stage 3 (Nurse Station & Koridor Rawat)
  superbugMrsa, // Bakteri kebal antibiotik berlapis baja emas (3 HP)
  fungalSpore, // Spora jamur candida berdenyut mekar
  shadowPathogen, // Patogen hitam keunguan meliuk-liuk cepat
  bossStage3, // Final Boss Superbug Chimera (raksasa ungu tua bermahkota magenta)

  // Legacy fallback
  bossMega,
}

enum PowerupType {
  firstAid, // Kotak P3K (+1 Live)
  spreadShot, // Vitamin C (Contra 3-way shot)
  hazmatShield, // APD (Invincible Shield)
  sanitizerBomb, // Hand Sanitizer (Clear all on screen)
}

class StageConfig {
  final int stageNumber;
  final String name;
  final String subtitle;
  final String locationTag;
  final int targetScoreToBoss;

  const StageConfig({
    required this.stageNumber,
    required this.name,
    required this.subtitle,
    required this.locationTag,
    required this.targetScoreToBoss,
  });

  static const List<StageConfig> stages = [
    StageConfig(
      stageNumber: 1,
      name: 'Drop-Off IGD 24 Jam',
      subtitle: 'Sterilisasi area depan & ambulans gawat darurat',
      locationTag: 'IGD & Ambulans RSIA',
      targetScoreToBoss: 300,
    ),
    StageConfig(
      stageNumber: 2,
      name: 'Lobi & Ruang Tunggu Poliklinik',
      subtitle: 'Sterilisasi area lobi, loket pendaftaran & poliklinik',
      locationTag: 'Lobi & Poliklinik RSIA',
      targetScoreToBoss: 450,
    ),
    StageConfig(
      stageNumber: 3,
      name: 'Nurse Station & Koridor Rawat',
      subtitle: 'Lindungi pos perawat dan ruang konsultasi dokter',
      locationTag: 'Nurse Station RSIA',
      targetScoreToBoss: 600,
    ),
  ];
}

enum GameDifficulty {
  easy,
  medium,
  hard,
}

extension GameDifficultyExt on GameDifficulty {
  String get label {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
    }
  }

  String get subtitle {
    switch (this) {
      case GameDifficulty.easy:
        return 'Santai & Ekstra 1 Nyawa (Skor 0.8x)';
      case GameDifficulty.medium:
        return 'Standar Patroli RSIA (Skor 1.0x)';
      case GameDifficulty.hard:
        return 'Tantangan Ekstrem! (Bonus Skor 1.5x)';
    }
  }

  Color get color {
    switch (this) {
      case GameDifficulty.easy:
        return const Color(0xFF10B981); // Hijau segar
      case GameDifficulty.medium:
        return const Color(0xFF00A896); // Toska RSIA
      case GameDifficulty.hard:
        return const Color(0xFFEF4444); // Merah membara
    }
  }

  double get scoreMultiplier {
    switch (this) {
      case GameDifficulty.easy:
        return 0.8;
      case GameDifficulty.medium:
        return 1.0;
      case GameDifficulty.hard:
        return 1.5;
    }
  }

  double get enemySpeedMultiplier {
    switch (this) {
      case GameDifficulty.easy:
        return 0.85;
      case GameDifficulty.medium:
        return 1.0;
      case GameDifficulty.hard:
        return 1.25;
    }
  }

  double get spawnIntervalDelta {
    switch (this) {
      case GameDifficulty.easy:
        return 0.4;
      case GameDifficulty.medium:
        return 0.0;
      case GameDifficulty.hard:
        return -0.35;
    }
  }

  int get baseLives {
    switch (this) {
      case GameDifficulty.easy:
        return 4;
      case GameDifficulty.medium:
        return 3;
      case GameDifficulty.hard:
        return 2;
    }
  }
}

enum HeroProfession {
  dokter,
  bidan,
  perawat,
  farmasi,
  analis,
  gizi,
  radiografer,
}

class HeroConfig {
  final HeroProfession profession;
  final String name;
  final String title;
  final String roleTag;
  final String description;
  final String uniformDesc;
  final String weaponName;
  final String skillName;
  final String skillDesc;

  // Warna Pakaian & Visual Hero
  final Color primaryColor;
  final Color coatColor;
  final Color coatBorderColor;
  final Color coatShadeColor;
  final Color shirtColor;
  final Color pantsColor;
  final Color shoesColor;
  final Color accentColor;
  final Color gloveColor;
  final Color gloveShadeColor;
  final Color bulletColor;
  final Color bulletGlowColor;
  final Color hairColor;

  // Aksesoris Pembeda Seragam
  final bool hasStethoscope;
  final bool hasLeadApron;
  final bool hasHeadCover; // Jilbab seragam medis nakes muslimah
  final Color? headCoverColor;
  final Color? headCoverBorderColor;
  final Color? headCoverShadeColor;
  final bool hasGlasses;
  final bool hasTie;
  final bool isScrubSuit; // Scrub V-neck vs Snelli

  Color get effectiveHeadCoverColor => headCoverColor ?? coatColor;
  Color get effectiveHeadCoverBorderColor => headCoverBorderColor ?? coatBorderColor;
  Color get effectiveHeadCoverShadeColor => headCoverShadeColor ?? coatShadeColor;

  // Stat Modifiers
  final double speedMultiplier;
  final double shootCooldownMultiplier;
  final double bulletSpeedMultiplier;
  final int bonusLives;

  const HeroConfig({
    required this.profession,
    required this.name,
    required this.title,
    required this.roleTag,
    required this.description,
    required this.uniformDesc,
    required this.weaponName,
    required this.skillName,
    required this.skillDesc,
    required this.primaryColor,
    required this.coatColor,
    required this.coatBorderColor,
    required this.coatShadeColor,
    required this.shirtColor,
    required this.pantsColor,
    required this.shoesColor,
    required this.accentColor,
    required this.gloveColor,
    required this.gloveShadeColor,
    required this.bulletColor,
    required this.bulletGlowColor,
    this.hairColor = const Color(0xFF0F172A),
    this.hasStethoscope = false,
    this.hasLeadApron = false,
    this.hasHeadCover = false,
    this.headCoverColor,
    this.headCoverBorderColor,
    this.headCoverShadeColor,
    this.hasGlasses = false,
    this.hasTie = false,
    this.isScrubSuit = false,
    this.speedMultiplier = 1.0,
    this.shootCooldownMultiplier = 1.0,
    this.bulletSpeedMultiplier = 1.0,
    this.bonusLives = 0,
  });

  static const List<HeroConfig> heroes = [
    // 1. DOKTER
    HeroConfig(
      profession: HeroProfession.dokter,
      name: 'dr. Satria',
      title: 'Dokter Umum',
      roleTag: 'Presisi & Stabil',
      description: 'Dokter garda depan dengan kemampuan diagnosis cepat dan tembakan jarum antiseptik presisi.',
      uniformDesc: 'Jas Snelli Putih Bersih, Kemeja Biru Muda, Dasi Biru RSIA & Celana Navy Formal.',
      weaponName: 'Syringe Antiseptik',
      skillName: 'Presisi Klinis',
      skillDesc: 'Statistik seimbang, akurasi tinggi dan stabilitas tembakan optimal.',
      primaryColor: Color(0xFF00A896),
      coatColor: Color(0xFFFFFFFF),
      coatBorderColor: Color(0xFF94A3B8),
      coatShadeColor: Color(0xFFF1F5F9),
      shirtColor: Color(0xFF38BDF8),
      pantsColor: Color(0xFF1E293B),
      shoesColor: Color(0xFF0F172A),
      accentColor: Color(0xFF0284C7),
      gloveColor: Color(0xFF38BDF8),
      gloveShadeColor: Color(0xFF0284C7),
      bulletColor: Color(0xFF00E5FF),
      bulletGlowColor: Color(0x6600E5FF),
      hasStethoscope: true,
      hasGlasses: true,
      hasTie: true,
      speedMultiplier: 1.0,
      bulletSpeedMultiplier: 1.0,
      shootCooldownMultiplier: 1.0,
    ),

    // 2. BIDAN
    HeroConfig(
      profession: HeroProfession.bidan,
      name: 'Bd. Amanda',
      title: 'Bidan',
      roleTag: 'Lincah & Sigap',
      description: 'Bidan tanggap darurat ibu & anak dengan kelincahan gerak tinggi dan semprotan kabut pelindung.',
      uniformDesc: 'Tunik Kebidanan Pink Pastel, Celana Putih Bersih, Jilbab Pink Lembut & Lencana Kebidanan Emas.',
      weaponName: 'Care Infusion Mist',
      skillName: 'Langkah Sigap',
      skillDesc: 'Kecepatan berlari & menghindar +15% lebih gesit dari hero lain.',
      primaryColor: Color(0xFFEC4899),
      coatColor: Color(0xFFFCE7F3),
      coatBorderColor: Color(0xFFF472B6),
      coatShadeColor: Color(0xFFFBCFE8),
      shirtColor: Color(0xFFBE185D),
      pantsColor: Color(0xFFF8FAFC),
      shoesColor: Color(0xFF9D174D),
      accentColor: Color(0xFFBE185D),
      gloveColor: Color(0xFFF472B6),
      gloveShadeColor: Color(0xFFBE185D),
      bulletColor: Color(0xFFFB7185),
      bulletGlowColor: Color(0x66FB7185),
      hasHeadCover: true,
      hasStethoscope: true,
      speedMultiplier: 1.15,
      bulletSpeedMultiplier: 1.05,
      shootCooldownMultiplier: 1.0,
    ),

    // 3. PERAWAT
    HeroConfig(
      profession: HeroProfession.perawat,
      name: 'Ns. Rizky',
      title: 'Perawat Kritis',
      roleTag: 'Rapid Fire',
      description: 'Perawat ruang rawat & IGD yang terlatih menangani pasien gawat darurat dengan aksi tembak beruntun cepat.',
      uniformDesc: 'Baju Jaga / Scrub Medis Toska Zamrud RSIA, Celana Scrub Senada & Jam Saku Dada.',
      weaponName: 'Rapid Infusion Jet',
      skillName: 'Aksi Beruntun',
      skillDesc: 'Laju tembakan otomatis 25% lebih cepat (Rapid Fire).',
      primaryColor: Color(0xFF0D9488),
      coatColor: Color(0xFF0D9488),
      coatBorderColor: Color(0xFF115E59),
      coatShadeColor: Color(0xFF0F766E),
      shirtColor: Color(0xFF042F2E),
      pantsColor: Color(0xFF0F766E),
      shoesColor: Color(0xFF042F2E),
      accentColor: Color(0xFF5EEAD4),
      gloveColor: Color(0xFF2DD4BF),
      gloveShadeColor: Color(0xFF0D9488),
      bulletColor: Color(0xFF10B981),
      bulletGlowColor: Color(0x6610B981),
      isScrubSuit: true,
      hasStethoscope: true,
      speedMultiplier: 1.0,
      bulletSpeedMultiplier: 1.0,
      shootCooldownMultiplier: 0.75,
    ),

    // 4. FARMASI
    HeroConfig(
      profession: HeroProfession.farmasi,
      name: 'Apt. Dimas',
      title: 'Apoteker Klinis',
      roleTag: 'Jangkauan Luas',
      description: 'Pakar formulasi obat yang meracik peluru kapsul vitamin pekat dengan jangkauan tembak terjauh.',
      uniformDesc: 'Jas Lab Farmasi Putih Gading, Kemeja Oranye Bata Apoteker & Lencana Mortar Emas.',
      weaponName: 'Capsule Blaster',
      skillName: 'Racikan Jarak Jauh',
      skillDesc: 'Jarak tempuh peluru kapsul +30% lebih jauh melintasi seluruh koridor.',
      primaryColor: Color(0xFFF59E0B),
      coatColor: Color(0xFFF8FAFC),
      coatBorderColor: Color(0xFFCBD5E1),
      coatShadeColor: Color(0xFFE2E8F0),
      shirtColor: Color(0xFFEA580C),
      pantsColor: Color(0xFF334155),
      shoesColor: Color(0xFF1E293B),
      accentColor: Color(0xFFF59E0B),
      gloveColor: Color(0xFFFCD34D),
      gloveShadeColor: Color(0xFFD97706),
      bulletColor: Color(0xFFF59E0B),
      bulletGlowColor: Color(0x66F59E0B),
      hasGlasses: true,
      speedMultiplier: 1.0,
      bulletSpeedMultiplier: 1.1,
      shootCooldownMultiplier: 1.0,
    ),

    // 5. ANALIS
    HeroConfig(
      profession: HeroProfession.analis,
      name: 'Maya, A.Md.AK',
      title: 'Analis Laboratorium',
      roleTag: 'Penetrasi Tinggi',
      description: 'Tenaga laboratorium yang menguasai analisis mikro-patogen dengan proyektil reagen berkecepatan tinggi.',
      uniformDesc: 'Jas Lab Putih, Jilbab Lavender Ungu Medis, Sarung Tangan Nitril & Kacamata Lab.',
      weaponName: 'Micro-Reagent Pipette',
      skillName: 'Analisis Akurat',
      skillDesc: 'Peluru melesat +25% lebih cepat menembus barisan mikroba.',
      primaryColor: Color(0xFF8B5CF6),
      coatColor: Color(0xFFFFFFFF),
      coatBorderColor: Color(0xFFC4B5FD),
      coatShadeColor: Color(0xFFEDE9FE),
      shirtColor: Color(0xFF7C3AED),
      pantsColor: Color(0xFF312E81),
      shoesColor: Color(0xFF1E1B4B),
      accentColor: Color(0xFFA78BFA),
      gloveColor: Color(0xFFA855F7),
      gloveShadeColor: Color(0xFF7C3AED),
      bulletColor: Color(0xFFC084FC),
      bulletGlowColor: Color(0x66C084FC),
      hasHeadCover: true,
      hasGlasses: true,
      headCoverColor: Color(0xFFEDE9FE),
      headCoverBorderColor: Color(0xFFA78BFA),
      headCoverShadeColor: Color(0xFFDDD6FE),
      speedMultiplier: 1.05,
      bulletSpeedMultiplier: 1.25,
      shootCooldownMultiplier: 0.95,
    ),

    // 6. GIZI
    HeroConfig(
      profession: HeroProfession.gizi,
      name: 'Nurul, S.Gz',
      title: 'Nutrisionis Klinis',
      roleTag: 'Daya Tahan Tinggi',
      description: 'Pakar nutrisi penunjang imunitas tubuh dengan ketahanan fisik luar biasa dan daya tahan ekstra.',
      uniformDesc: 'Seragam Hijau Mint Segar, Jilbab Mint Pastel, Celana Forest Green & Pin Apel Sehat.',
      weaponName: 'Nutri-Immune Pulse',
      skillName: 'Benteng Imunitas',
      skillDesc: 'Mendapatkan +1 Ekstra Nyawa dasar secara permanen.',
      primaryColor: Color(0xFF10B981),
      coatColor: Color(0xFF34D399),
      coatBorderColor: Color(0xFF059669),
      coatShadeColor: Color(0xFF10B981),
      shirtColor: Color(0xFFFEF3C7),
      pantsColor: Color(0xFF064E3B),
      shoesColor: Color(0xFF022C22),
      accentColor: Color(0xFFEF4444),
      gloveColor: Color(0xFFA7F3D0),
      gloveShadeColor: Color(0xFF059669),
      bulletColor: Color(0xFF84CC16),
      bulletGlowColor: Color(0x6684CC16),
      hasHeadCover: true,
      headCoverColor: Color(0xFFA7F3D0),
      headCoverBorderColor: Color(0xFF059669),
      headCoverShadeColor: Color(0xFF6EE7B7),
      bonusLives: 1,
      speedMultiplier: 1.0,
      bulletSpeedMultiplier: 1.0,
      shootCooldownMultiplier: 1.0,
    ),

    // 7. RADIOGRAFER
    HeroConfig(
      profession: HeroProfession.radiografer,
      name: 'Bagus, A.Md.Rad',
      title: 'Radiografer',
      roleTag: 'Laser Photonic',
      description: 'Pakar radiologi berperlengkapan apron timbal anti-radiasi dengan senjata foton sinar-X penetrasi kilat.',
      uniformDesc: 'Apron Timbal Abu Baja Pelindung Radiasi, Simbol Trefoil Kuning & Seragam Cobalt Blue.',
      weaponName: 'X-Ray Photonic Laser',
      skillName: 'Berkas Radiasi Foton',
      skillDesc: 'Peluru fotonik sinar-X terlaju (+35% kecepatan peluru) dan visual laser kilat.',
      primaryColor: Color(0xFF0284C7),
      coatColor: Color(0xFF334155),
      coatBorderColor: Color(0xFF1E293B),
      coatShadeColor: Color(0xFF475569),
      shirtColor: Color(0xFF1D4ED8),
      pantsColor: Color(0xFF0F172A),
      shoesColor: Color(0xFF020617),
      accentColor: Color(0xFFFACC15),
      gloveColor: Color(0xFF64748B),
      gloveShadeColor: Color(0xFF334155),
      bulletColor: Color(0xFF38BDF8),
      bulletGlowColor: Color(0x6638BDF8),
      hasLeadApron: true,
      hasGlasses: true,
      speedMultiplier: 0.96,
      bulletSpeedMultiplier: 1.35,
      shootCooldownMultiplier: 0.9,
    ),
  ];
}

