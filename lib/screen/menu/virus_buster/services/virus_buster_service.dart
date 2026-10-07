import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';

class VirusBusterService {
  static const String _prefHighScoreKey = 'virus_buster_local_high_score';
  static const String _prefMaxStageKey = 'virus_buster_local_max_stage';
  static const String _prefTotalVirusesKey = 'virus_buster_total_viruses_defeated';

  /// Simpan skor terbaik & rekor secara lokal
  static Future<void> saveLocalBest(int score, int stage, int defeated) async {
    final box = GetStorage();
    final currentHigh = box.read<int>(_prefHighScoreKey) ?? 0;
    if (score > currentHigh) {
      await box.write(_prefHighScoreKey, score);
    }
    final currentMaxStage = box.read<int>(_prefMaxStageKey) ?? 1;
    if (stage > currentMaxStage) {
      await box.write(_prefMaxStageKey, stage);
    }
    final currentTotal = box.read<int>(_prefTotalVirusesKey) ?? 0;
    await box.write(_prefTotalVirusesKey, currentTotal + defeated);
  }

  /// Ambil data rekor lokal
  static Future<Map<String, int>> getLocalBest() async {
    final box = GetStorage();
    return {
      'high_score': box.read<int>(_prefHighScoreKey) ?? 0,
      'max_stage': box.read<int>(_prefMaxStageKey) ?? 1,
      'total_viruses': box.read<int>(_prefTotalVirusesKey) ?? 0,
    };
  }

  /// Submit score ke API (jika tersedia endpoint, fallback graceful)
  static Future<Map<String, dynamic>> submitScore({
    required int score,
    required int stage,
    required int virusesDefeated,
  }) async {
    await saveLocalBest(score, stage, virusesDefeated);

    try {
      final body = {
        'score': score,
        'stage': stage,
        'viruses_defeated': virusesDefeated,
      };

      final response = await Api().postData(body, '/virus-buster/submit');
      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['success'] == true) {
          return {
            'success': true,
            'message': resJson['message'] ?? 'Rekor berhasil dicatat!',
          };
        }
      }
      return {
        'success': true,
        'message': 'Rekor tersimpan di perangkat lokal!',
      };
    } catch (_) {
      return {
        'success': true,
        'message': 'Mode offline: Rekor tersimpan di perangkat lokal',
      };
    }
  }
}
