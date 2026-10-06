class EmergencyRushScoreRecord {
  final int id;
  final String nik;
  final int score;
  final int distanceMeters;
  final int itemsCollected;
  final int maxSpeed;
  final DateTime playedAt;

  EmergencyRushScoreRecord({
    required this.id,
    required this.nik,
    required this.score,
    required this.distanceMeters,
    required this.itemsCollected,
    required this.maxSpeed,
    required this.playedAt,
  });

  factory EmergencyRushScoreRecord.fromJson(Map<String, dynamic> json) {
    return EmergencyRushScoreRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nik: json['nik']?.toString() ?? '',
      score: json['score'] is int ? json['score'] : int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      distanceMeters: json['distance_meters'] is int
          ? json['distance_meters']
          : int.tryParse(json['distance_meters']?.toString() ?? '0') ?? 0,
      itemsCollected: json['items_collected'] is int
          ? json['items_collected']
          : int.tryParse(json['items_collected']?.toString() ?? '0') ?? 0,
      maxSpeed: json['max_speed'] is int
          ? json['max_speed']
          : int.tryParse(json['max_speed']?.toString() ?? '60') ?? 60,
      playedAt: json['played_at'] != null
          ? DateTime.tryParse(json['played_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class EmergencyRushLeaderboardItem {
  final int rank;
  final String nik;
  final String nama;
  final String departemen;
  final int highScore;
  final int maxDistance;
  final int totalItems;
  final int totalRuns;
  final bool isCurrentUser;
  final String? lastPlayedAt;

  EmergencyRushLeaderboardItem({
    required this.rank,
    required this.nik,
    required this.nama,
    required this.departemen,
    required this.highScore,
    required this.maxDistance,
    required this.totalItems,
    required this.totalRuns,
    required this.isCurrentUser,
    this.lastPlayedAt,
  });

  factory EmergencyRushLeaderboardItem.fromJson(Map<String, dynamic> json) {
    return EmergencyRushLeaderboardItem(
      rank: json['rank'] is int ? json['rank'] : int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      nik: json['nik']?.toString() ?? '',
      nama: json['nama']?.toString() ?? 'Karyawan',
      departemen: json['departemen']?.toString() ?? '-',
      highScore: json['high_score'] is int
          ? json['high_score']
          : int.tryParse(json['high_score']?.toString() ?? '0') ?? 0,
      maxDistance: json['max_distance'] is int
          ? json['max_distance']
          : int.tryParse(json['max_distance']?.toString() ?? '0') ?? 0,
      totalItems: json['total_items'] is int
          ? json['total_items']
          : int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      totalRuns: json['total_runs'] is int
          ? json['total_runs']
          : int.tryParse(json['total_runs']?.toString() ?? '0') ?? 0,
      isCurrentUser: json['is_current_user'] == true,
      lastPlayedAt: json['last_played_at']?.toString(),
    );
  }
}

class EmergencyRushMyStats {
  final int rank;
  final int highScore;
  final int maxDistance;
  final int totalItems;
  final int totalRuns;

  EmergencyRushMyStats({
    required this.rank,
    required this.highScore,
    required this.maxDistance,
    required this.totalItems,
    required this.totalRuns,
  });

  factory EmergencyRushMyStats.fromJson(Map<String, dynamic> json) {
    return EmergencyRushMyStats(
      rank: json['rank'] is int ? json['rank'] : int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      highScore: json['high_score'] is int
          ? json['high_score']
          : int.tryParse(json['high_score']?.toString() ?? '0') ?? 0,
      maxDistance: json['max_distance'] is int
          ? json['max_distance']
          : int.tryParse(json['max_distance']?.toString() ?? '0') ?? 0,
      totalItems: json['total_items'] is int
          ? json['total_items']
          : int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      totalRuns: json['total_runs'] is int
          ? json['total_runs']
          : int.tryParse(json['total_runs']?.toString() ?? '0') ?? 0,
    );
  }
}
