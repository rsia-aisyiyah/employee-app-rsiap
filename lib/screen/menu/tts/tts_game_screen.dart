import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rsia_employee_app/screen/menu/tts/models/tts_model.dart';
import 'package:rsia_employee_app/screen/menu/tts/widgets/tts_confetti_painter.dart';
import 'package:rsia_employee_app/screen/menu/tts/widgets/tts_grid_widget.dart';
import 'package:rsia_employee_app/screen/menu/tts/widgets/tts_keyboard.dart';
import 'package:rsia_employee_app/screen/menu/tts/tts_leaderboard_screen.dart';
import 'package:rsia_employee_app/screen/menu/tts/services/tts_service.dart';

class TtsGameScreen extends StatefulWidget {
  final TtsLevel level;

  const TtsGameScreen({super.key, required this.level});

  @override
  State<TtsGameScreen> createState() => _TtsGameScreenState();
}

class _TtsGameScreenState extends State<TtsGameScreen>
    with SingleTickerProviderStateMixin {
  late TtsLevel _currentLevel;
  late List<List<TtsCell>> _grid;
  int _selectedRow = 0;
  int _selectedCol = 0;
  ClueDirection _activeDirection = ClueDirection.across;

  int _seconds = 0;
  Timer? _timer;
  final bool _isPlaying = true;
  bool _isWon = false;

  int _hintQuota = 3;
  int _hintsUsed = 0;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.level;
    _grid = _currentLevel.buildGrid();
    _findFirstPlayableCell();
    _startTimer();
  }

  Future<void> _shuffleLevel() async {
    final newLevel = await TtsService.getRandomLevel();
    if (!mounted) return;
    setState(() {
      _currentLevel = newLevel;
      _grid = newLevel.buildGrid();
      _seconds = 0;
      _isWon = false;
      _hintsUsed = 0;
      _findFirstPlayableCell();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎲 Papan diacak: ${_currentLevel.title}'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isPlaying && !_isWon) {
        setState(() => _seconds++);
      }
    });
  }

  void _findFirstPlayableCell() {
    for (int r = 0; r < _grid.length; r++) {
      for (int c = 0; c < _grid[r].length; c++) {
        if (!_grid[r][c].isBlocked) {
          _selectedRow = r;
          _selectedCol = c;
          _activeDirection = _getAvailableDirection(r, c) ?? ClueDirection.across;
          return;
        }
      }
    }
  }

  bool _cellHasAcross(int r, int c) {
    return _currentLevel.clues.any(
      (clue) =>
          clue.direction == ClueDirection.across &&
          clue.startRow == r &&
          c >= clue.startCol &&
          c < clue.startCol + clue.answer.length,
    );
  }

  bool _cellHasDown(int r, int c) {
    return _currentLevel.clues.any(
      (clue) =>
          clue.direction == ClueDirection.down &&
          clue.startCol == c &&
          r >= clue.startRow &&
          r < clue.startRow + clue.answer.length,
    );
  }

  ClueDirection? _getAvailableDirection(int r, int c) {
    if (_cellHasAcross(r, c)) return ClueDirection.across;
    if (_cellHasDown(r, c)) return ClueDirection.down;
    return null;
  }

  TtsClue? get _activeClue {
    // 1. Prioritize clue with current active direction
    for (var clue in _currentLevel.clues) {
      if (clue.direction == _activeDirection) {
        if (clue.direction == ClueDirection.across) {
          if (_selectedRow == clue.startRow &&
              _selectedCol >= clue.startCol &&
              _selectedCol < clue.startCol + clue.answer.length) {
            return clue;
          }
        } else {
          if (_selectedCol == clue.startCol &&
              _selectedRow >= clue.startRow &&
              _selectedRow < clue.startRow + clue.answer.length) {
            return clue;
          }
        }
      }
    }

    // 2. Fallback: clue touching current cell in the other direction
    for (var clue in _currentLevel.clues) {
      if (clue.direction == ClueDirection.across) {
        if (_selectedRow == clue.startRow &&
            _selectedCol >= clue.startCol &&
            _selectedCol < clue.startCol + clue.answer.length) {
          return clue;
        }
      } else {
        if (_selectedCol == clue.startCol &&
            _selectedRow >= clue.startRow &&
            _selectedRow < clue.startRow + clue.answer.length) {
          return clue;
        }
      }
    }

    return _currentLevel.clues.isNotEmpty ? _currentLevel.clues.first : null;
  }

  void _onCellTapped(int r, int c) {
    if (_grid[r][c].isBlocked) return;

    final bool hasAcross = _cellHasAcross(r, c);
    final bool hasDown = _cellHasDown(r, c);

    if (_selectedRow == r && _selectedCol == c) {
      // Toggle direction if cell supports both across and down
      if (hasAcross && hasDown) {
        setState(() {
          _activeDirection = _activeDirection == ClueDirection.across
              ? ClueDirection.down
              : ClueDirection.across;
        });
      }
    } else {
      setState(() {
        _selectedRow = r;
        _selectedCol = c;
        if (hasAcross && !hasDown) {
          _activeDirection = ClueDirection.across;
        } else if (!hasAcross && hasDown) {
          _activeDirection = ClueDirection.down;
        }
      });
    }
  }

  void _onKeyPressed(String letter) {
    if (_isWon) return;

    setState(() {
      _grid[_selectedRow][_selectedCol].currentLetter = letter;
    });

    _moveToNextCell();
    _checkWinCondition();
  }

  void _onDeletePressed() {
    if (_isWon) return;

    setState(() {
      if (_grid[_selectedRow][_selectedCol].currentLetter.isNotEmpty) {
        _grid[_selectedRow][_selectedCol].currentLetter = '';
      } else {
        _moveToPreviousCell();
        _grid[_selectedRow][_selectedCol].currentLetter = '';
      }
    });
  }

  void _moveToNextCell() {
    final clue = _activeClue;
    if (clue == null) return;

    if (_activeDirection == ClueDirection.across) {
      int nextCol = _selectedCol + 1;
      if (nextCol < clue.startCol + clue.answer.length &&
          nextCol < _currentLevel.numCols) {
        if (!_grid[_selectedRow][nextCol].isBlocked) {
          setState(() => _selectedCol = nextCol);
        }
      }
    } else {
      int nextRow = _selectedRow + 1;
      if (nextRow < clue.startRow + clue.answer.length &&
          nextRow < _currentLevel.numRows) {
        if (!_grid[nextRow][_selectedCol].isBlocked) {
          setState(() => _selectedRow = nextRow);
        }
      }
    }
  }

  void _moveToPreviousCell() {
    final clue = _activeClue;
    if (clue == null) return;

    if (_activeDirection == ClueDirection.across) {
      int prevCol = _selectedCol - 1;
      if (prevCol >= clue.startCol) {
        if (!_grid[_selectedRow][prevCol].isBlocked) {
          setState(() => _selectedCol = prevCol);
        }
      }
    } else {
      int prevRow = _selectedRow - 1;
      if (prevRow >= clue.startRow) {
        if (!_grid[prevRow][_selectedCol].isBlocked) {
          setState(() => _selectedRow = prevRow);
        }
      }
    }
  }

  void _onHintPressed() {
    if (_hintQuota <= 0 || _isWon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Anda telah menggunakan seluruh bantuan hint untuk level ini.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.amber.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final cell = _grid[_selectedRow][_selectedCol];
    if (cell.isBlocked) return;

    setState(() {
      cell.currentLetter = cell.correctLetter;
      cell.isRevealed = true;
      _hintQuota--;
      _hintsUsed++;
    });

    _moveToNextCell();
    _checkWinCondition();
  }

  void _stepClue(int delta) {
    final clues = _currentLevel.clues;
    if (clues.isEmpty) return;

    final current = _activeClue;
    int curIdx = clues.indexOf(current ?? clues.first);
    int nextIdx = (curIdx + delta) % clues.length;
    if (nextIdx < 0) nextIdx = clues.length - 1;

    final nextClue = clues[nextIdx];
    setState(() {
      _activeDirection = nextClue.direction;
      _selectedRow = nextClue.startRow;
      _selectedCol = nextClue.startCol;
    });
  }

  void _checkWinCondition() {
    bool allFilledAndCorrect = true;

    for (int r = 0; r < _grid.length; r++) {
      for (int c = 0; c < _grid[r].length; c++) {
        final cell = _grid[r][c];
        if (!cell.isBlocked) {
          if (cell.currentLetter.isEmpty ||
              cell.currentLetter.toUpperCase() != cell.correctLetter.toUpperCase()) {
            allFilledAndCorrect = false;
            break;
          }
        }
      }
      if (!allFilledAndCorrect) break;
    }

    if (allFilledAndCorrect && !_isWon) {
      _triggerWin();
    }
  }

  void _triggerWin() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() => _isWon = true);

    // Save score to local storage
    int baseScore = 1000;
    int timePenalty = _seconds * 3;
    int hintPenalty = _hintsUsed * 100;
    int finalScore = (baseScore - timePenalty - hintPenalty).clamp(100, 1000);

    // Mark level completed & sync score with backend database
    TtsService.submitScore(
      levelId: _currentLevel.id,
      timeSeconds: _seconds,
      hintsUsed: _hintsUsed,
      score: finalScore,
    );

    // Show Victory Bottom Sheet
    Future.delayed(const Duration(milliseconds: 350), () {
      _showVictoryDialog(finalScore);
    });
  }

  void _showVictoryDialog(int score) {
    int m = _seconds ~/ 60;
    int s = _seconds % 60;
    String timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🎉 LUAR BIASA! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Teka-Teki Silang "${widget.level.title}" Berhasil Diselesaikan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Stat Cards Row
            Row(
              children: [
                _buildStatBadge(
                  icon: Icons.timer_rounded,
                  label: 'Waktu',
                  value: timeStr,
                  color: const Color(0xFF0EA5E9),
                ),
                const SizedBox(width: 12),
                _buildStatBadge(
                  icon: Icons.stars_rounded,
                  label: 'Skor Akhir',
                  value: '$score',
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 12),
                _buildStatBadge(
                  icon: Icons.lightbulb_rounded,
                  label: 'Bantuan',
                  value: '$_hintsUsed dipakai',
                  color: const Color(0xFF10B981),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TtsLeaderboardScreen()),
                      );
                    },
                    icon: const Icon(Icons.leaderboard_rounded, size: 18),
                    label: const Text('Peringkat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx); // Close dialog
                      Navigator.pop(context); // Back to TTS Home
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Selesai'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3BC8ED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    int m = _seconds ~/ 60;
    int s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final clue = _activeClue;

    return TtsConfettiWidget(
      play: _isWon,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentLevel.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                _currentLevel.category,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          actions: [
            // Shuffle / Acak Papan Baru Button
            IconButton(
              icon: const Icon(Icons.shuffle_rounded, color: Color(0xFF0284C7)),
              tooltip: 'Acak Papan Baru',
              onPressed: _shuffleLevel,
            ),

            // Timer Badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7DD3FC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 15, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),

            // Leaderboard shortcut icon
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined, color: Color(0xFFF59E0B)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TtsLeaderboardScreen()),
              ),
              tooltip: 'Peringkat',
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),

            // Crossword 5x5 Grid
            Expanded(
              child: Center(
                child: TtsGridWidget(
                  grid: _grid,
                  selectedRow: _selectedRow,
                  selectedCol: _selectedCol,
                  activeDirection: _activeDirection,
                  activeClue: clue,
                  onCellTapped: _onCellTapped,
                ),
              ),
            ),

            // Clue Card Banner (Swipeable / Navigable)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous Clue Button
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: const Color(0xFF64748B),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _stepClue(-1),
                  ),
                  const SizedBox(width: 8),

                  // Clue Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(
                          builder: (context) {
                            final displayDir = clue?.direction ?? _activeDirection;
                            final bool isAcross = displayDir == ClueDirection.across;

                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAcross
                                        ? const Color(0xFFDFF8FF)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAcross
                                            ? Icons.swap_horiz_rounded
                                            : Icons.swap_vert_rounded,
                                        size: 13,
                                        color: isAcross
                                            ? const Color(0xFF0284C7)
                                            : const Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${clue?.number ?? 1} ${isAcross ? 'Mendatar' : 'Menurun'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isAcross
                                              ? const Color(0xFF0284C7)
                                              : const Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${clue?.answer.length ?? 0} Huruf',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          clue?.clueText ?? 'Pilih kotak untuk melihat petunjuk...',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Next Clue Button
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    color: const Color(0xFF64748B),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _stepClue(1),
                  ),
                ],
              ),
            ),

            // In-Game Custom Keyboard
            TtsKeyboard(
              onKeyPressed: _onKeyPressed,
              onDeletePressed: _onDeletePressed,
              onHintPressed: _onHintPressed,
              hintQuota: _hintQuota,
            ),
          ],
        ),
      ),
    );
  }
}
