import 'dart:convert';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/screen/menu/tts/models/tts_model.dart';
import 'package:rsia_employee_app/screen/menu/tts/data/tts_levels.dart';

class TtsService {
  /// Fetch all active levels from API (with fallback to offline levels)
  static Future<List<TtsLevel>> getLevels() async {
    try {
      final response = await Api().getData('/tts/levels');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final List list = body['data'];
          List<TtsLevel> levels = [];

          for (var item in list) {
            int levelId = item['id'] ?? 0;
            List<TtsClue> parsedClues = [];

            if (item['clues'] is List && (item['clues'] as List).isNotEmpty) {
              parsedClues = (item['clues'] as List).map((c) {
                return TtsClue(
                  number: c['number'] ?? 1,
                  direction: (c['direction'] ?? 'across').toString().toLowerCase() == 'down'
                      ? ClueDirection.down
                      : ClueDirection.across,
                  clueText: c['clue_text'] ?? '',
                  answer: (c['answer'] ?? '').toString().toUpperCase(),
                  startRow: c['start_row'] ?? 0,
                  startCol: c['start_col'] ?? 0,
                );
              }).toList();
            }

            // If clues not returned in list payload, match with local verified bank soal
            if (parsedClues.isEmpty) {
              final localMatch = TtsLevelsData.getLevels().where((l) => l.id == levelId).toList();
              if (localMatch.isNotEmpty) {
                parsedClues = localMatch.first.clues;
              }
            }

            int? totalClues = item['total_clues'] ?? item['clues_count'];
            if (totalClues == null && parsedClues.isNotEmpty) {
              totalClues = parsedClues.length;
            }

            int? numRows = item['num_rows'];
            int? numCols = item['num_cols'];

            levels.add(
              TtsLevel(
                id: levelId,
                title: item['title'] ?? 'Level $levelId',
                category: item['category'] ?? 'Dasar RSIA',
                description: item['description'] ?? '',
                size: item['size'] ?? 5,
                clues: parsedClues,
                totalClues: totalClues,
                customRows: numRows,
                customCols: numCols,
                isCompleted: item['is_completed'] == true,
                userScore: item['user_score'] != null ? (item['user_score'] as num).toInt() : null,
                userTimeSeconds: item['user_time_seconds'] != null ? (item['user_time_seconds'] as num).toInt() : null,
              ),
            );
          }

          if (levels.isNotEmpty) {
            return levels;
          }
        }
      }
    } catch (_) {
      // Offline fallback
    }

    // Default offline levels fallback
    return TtsLevelsData.getLevels();
  }

  /// Fetch level detail including clues
  static Future<TtsLevel> getLevelDetail(int levelId) async {
    try {
      final response = await Api().getData('/tts/levels/$levelId');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final List rawClues = data['clues'] ?? [];

          List<TtsClue> clues = rawClues.map((c) {
            return TtsClue(
              number: c['number'] ?? 1,
              direction: (c['direction'] ?? 'across').toString().toLowerCase() == 'down'
                  ? ClueDirection.down
                  : ClueDirection.across,
              clueText: c['clue_text'] ?? '',
              answer: (c['answer'] ?? '').toString().toUpperCase(),
              startRow: c['start_row'] ?? 0,
              startCol: c['start_col'] ?? 0,
            );
          }).toList();

          if (clues.isEmpty) {
            final fallback = TtsLevelsData.getLevels().firstWhere(
              (l) => l.id == levelId,
              orElse: () => TtsLevelsData.getLevels().first,
            );
            clues = fallback.clues;
          }

          return TtsLevel(
            id: data['id'] ?? levelId,
            title: data['title'] ?? 'Level $levelId',
            category: data['category'] ?? 'Dasar RSIA',
            description: data['description'] ?? '',
            size: data['size'] ?? 5,
            clues: clues,
            totalClues: data['total_clues'] ?? clues.length,
            customRows: data['num_rows'],
            customCols: data['num_cols'],
          );
        }
      }
    } catch (_) {
      // Offline fallback
    }

    // Fallback to local
    final fallbackLevels = TtsLevelsData.getLevels();
    return fallbackLevels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => fallbackLevels.first,
    );
  }

  /// Fetch a random level from API or pick randomly from local bank
  static Future<TtsLevel> getRandomLevel() async {
    try {
      final response = await Api().getData('/tts/random');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final List rawClues = data['clues'] ?? [];

          List<TtsClue> clues = rawClues.map((c) {
            return TtsClue(
              number: c['number'] ?? 1,
              direction: (c['direction'] ?? 'across').toString().toLowerCase() == 'down'
                  ? ClueDirection.down
                  : ClueDirection.across,
              clueText: c['clue_text'] ?? '',
              answer: (c['answer'] ?? '').toString().toUpperCase(),
              startRow: c['start_row'] ?? 0,
              startCol: c['start_col'] ?? 0,
            );
          }).toList();

          if (clues.isNotEmpty) {
            return TtsLevel(
              id: data['id'] ?? 1,
              title: data['title'] ?? 'Tantangan Acak',
              category: 'Mode Campur',
              description: data['description'] ?? '',
              size: data['size'] ?? 5,
              clues: clues,
              totalClues: data['total_clues'] ?? clues.length,
              customRows: data['num_rows'],
              customCols: data['num_cols'],
              isCompleted: data['is_completed'] == true,
              userScore: data['user_score'] != null ? (data['user_score'] as num).toInt() : null,
              userTimeSeconds: data['user_time_seconds'] != null ? (data['user_time_seconds'] as num).toInt() : null,
            );
          }
        }
      }
    } catch (_) {}

    // Fallback: pick randomly from local 20 levels
    final localList = TtsLevelsData.getLevels();
    localList.shuffle();
    return localList.first;
  }

  /// Submit score to API
  static Future<Map<String, dynamic>?> submitScore({
    required int levelId,
    required int timeSeconds,
    required int hintsUsed,
    required int score,
  }) async {
    try {
      final payload = {
        'level_id': levelId,
        'time_seconds': timeSeconds,
        'hints_used': hintsUsed,
        'score': score,
      };

      final response = await Api().postData(payload, '/tts/submit');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (_) {
      // Network failure / offline
    }
    return null;
  }

  /// Fetch leaderboard data from API
  static Future<Map<String, dynamic>?> getLeaderboard() async {
    try {
      final response = await Api().getData('/tts/leaderboard');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return body['data'];
        }
      }
    } catch (_) {
      // Network failure / offline
    }
    return null;
  }
}
