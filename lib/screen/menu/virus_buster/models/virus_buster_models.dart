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
  fluGoo, // Slime hijau merayap
  spikeCorona, // Duri merah melayang/memantul
  mosquito, // Nyamuk melayang menukik
  bossMega, // Virus raksasa berputar di akhir stage
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
      targetScoreToBoss: 350,
    ),
    StageConfig(
      stageNumber: 2,
      name: 'Lobi & Ruang Tunggu Poliklinik',
      subtitle: 'Basmi virus di deretan kursi tunggu & antrean pasien',
      locationTag: 'Lobi & Poliklinik RSIA',
      targetScoreToBoss: 500,
    ),
    StageConfig(
      stageNumber: 3,
      name: 'Nurse Station & Koridor Rawat',
      subtitle: 'Lindungi pos perawat dan ruang konsultasi dokter',
      locationTag: 'Nurse Station RSIA',
      targetScoreToBoss: 700,
    ),
  ];
}
