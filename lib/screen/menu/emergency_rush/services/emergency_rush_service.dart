import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/models/emergency_rush_model.dart';

class EmergencyRushService {
  static const String _prefHighScoreKey = 'emergency_rush_local_high_score';
  static const String _prefMaxDistanceKey = 'emergency_rush_local_max_distance';

  /// Submit score to API
  static Future<Map<String, dynamic>> submitScore({
    required int score,
    required int distanceMeters,
    required int itemsCollected,
    required int maxSpeed,
  }) async {
    // Always cache locally first
    await _saveLocalBest(score, distanceMeters);

    try {
      final body = {
        'score': score,
        'distance_meters': distanceMeters,
        'items_collected': itemsCollected,
        'max_speed': maxSpeed,
      };

      final response = await Api().postData(body, '/emergency-rush/submit');
      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['success'] == true) {
          return {
            'success': true,
            'data': resJson['data'],
            'message': resJson['message'] ?? 'Skor berhasil disimpan!',
          };
        }
      }
      return {
        'success': false,
        'message': 'Gagal mengirim skor ke server',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Mode offline: Skor tersimpan di perangkat lokal',
      };
    }
  }

  /// Get leaderboard from API
  static Future<Map<String, dynamic>> getLeaderboard({int limit = 20}) async {
    try {
      final response = await Api().getData('/emergency-rush/leaderboard?limit=$limit');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final List rawList = data['leaderboard'] ?? [];
          final items = rawList.map((e) => EmergencyRushLeaderboardItem.fromJson(e)).toList();

          EmergencyRushMyStats? myStats;
          if (data['my_stats'] != null) {
            myStats = EmergencyRushMyStats.fromJson(data['my_stats']);
          }

          return {
            'success': true,
            'leaderboard': items,
            'my_stats': myStats,
          };
        }
      }
    } catch (_) {
      // Offline fallback
    }

    // Return empty fallback
    return {
      'success': false,
      'leaderboard': <EmergencyRushLeaderboardItem>[],
      'my_stats': null,
    };
  }

  /// Save local personal best
  static Future<void> _saveLocalBest(int score, int distance) async {
    try {
      final box = GetStorage();
      int currentHigh = box.read<int>(_prefHighScoreKey) ?? 0;
      int currentDist = box.read<int>(_prefMaxDistanceKey) ?? 0;

      if (score > currentHigh) {
        await box.write(_prefHighScoreKey, score);
      }
      if (distance > currentDist) {
        await box.write(_prefMaxDistanceKey, distance);
      }
    } catch (_) {}
  }

  /// Get local personal best
  static Future<Map<String, int>> getLocalBest() async {
    try {
      final box = GetStorage();
      return {
        'high_score': box.read<int>(_prefHighScoreKey) ?? 0,
        'max_distance': box.read<int>(_prefMaxDistanceKey) ?? 0,
      };
    } catch (_) {
      return {'high_score': 0, 'max_distance': 0};
    }
  }
}

