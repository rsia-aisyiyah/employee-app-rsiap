import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/screen/menu/tts/models/tts_model.dart';
import 'package:rsia_employee_app/screen/menu/tts/services/tts_service.dart';
import 'package:rsia_employee_app/screen/menu/tts/tts_game_screen.dart';
import 'package:rsia_employee_app/screen/menu/tts/tts_leaderboard_screen.dart';

class TtsHomeScreen extends StatefulWidget {
  const TtsHomeScreen({super.key});

  @override
  State<TtsHomeScreen> createState() => _TtsHomeScreenState();
}

class _TtsHomeScreenState extends State<TtsHomeScreen> {
  final GetStorage _storage = GetStorage();
  List<TtsLevel> _levels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Clear residual local test storage
    for (int i = 1; i <= 20; i++) {
      _storage.remove('tts_level_${i}_completed');
      _storage.remove('tts_level_${i}_score');
      _storage.remove('tts_level_${i}_time');
    }
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() => _isLoading = true);
    final levels = await TtsService.getLevels();
    if (mounted) {
      setState(() {
        _levels = levels;
        _isLoading = false;
      });
    }
  }

  int get _completedCount {
    return _levels.where((lvl) => lvl.isCompleted).length;
  }

  Future<void> _playLevel(TtsLevel level) async {
    TtsLevel playable = level;
    if (level.clues.isEmpty) {
      // Show loading indicator briefly
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3BC8ED)),
        ),
      );

      playable = await TtsService.getLevelDetail(level.id);

      if (mounted) {
        Navigator.pop(context); // close loader
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TtsGameScreen(level: playable)),
    ).then((_) => _loadLevels());
  }

  Future<void> _playRandomLevel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF3BC8ED)),
      ),
    );

    final randomLevel = await TtsService.getRandomLevel();

    if (mounted) {
      Navigator.pop(context); // close loader
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TtsGameScreen(level: randomLevel)),
    ).then((_) => _loadLevels());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TTS Mini RSIA',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TtsLeaderboardScreen()),
            ),
            tooltip: 'Papan Peringkat',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLevels,
        color: const Color(0xFF0284C7),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Hero Banner ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF3BC8ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Text('🧩', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 4),
                            Text(
                              'Rehat Cerdas RSIA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_completedCount / ${_levels.length} Selesai',
                          style: const TextStyle(
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Teka-Teki Silang Mini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Asah wawasan medis, PPI, dan keselamatan pasien sambil rehat di sela tugas shift.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons: Main Acak & Peringkat
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _playRandomLevel,
                        icon: const Icon(Icons.shuffle_rounded, size: 20),
                        label: const Text('Main Acak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0284C7),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _levels.isEmpty
                            ? null
                            : () {
                                final firstUncompleted = _levels.firstWhere(
                                  (l) => !l.isCompleted,
                                  orElse: () => _levels.first,
                                );
                                _playLevel(firstUncompleted);
                              },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Lanjut'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TtsLeaderboardScreen()),
                        ),
                        icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
                        tooltip: 'Papan Peringkat',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section Title ──
            Row(
              children: [
                const Text(
                  'Daftar Level TTS',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_levels.length} Level',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Loading state or Level Cards List ──
            if (_isLoading && _levels.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                ),
              )
            else
              ..._levels.map((level) {
                bool isDone = level.isCompleted;
                int? score = level.userScore;
                int? timeSec = level.userTimeSeconds;

                String timeText = '';
                if (timeSec != null && isDone) {
                  int m = timeSec ~/ 60;
                  int s = timeSec % 60;
                  timeText = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                      width: isDone ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDone
                            ? const Color(0xFF10B981).withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _playLevel(level),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Level Badge
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDone
                                      ? [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)]
                                      : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDone
                                        ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                                        : const Color(0xFF0284C7).withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF16A34A), size: 30)
                                    : Text(
                                        '0${level.id}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Level Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Dynamic metadata pills (no categories!)
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '🧩 ${level.wordCount} Kata',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Text(
                                          '📐 ${level.numRows}×${level.numCols}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      if (isDone && score != null) ...[
                                        const Spacer(),
                                        Text(
                                          '⭐ $score Pts',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    level.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    level.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Trailing Action Badge
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (isDone && timeText.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      timeText,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDone ? const Color(0xFFF1F5F9) : const Color(0xFFE0F2FE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDone ? Icons.replay_rounded : Icons.play_arrow_rounded,
                                    size: 16,
                                    color: isDone ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
