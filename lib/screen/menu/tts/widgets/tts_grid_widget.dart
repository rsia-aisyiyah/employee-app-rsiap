import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rsia_employee_app/screen/menu/tts/models/tts_model.dart';

class TtsGridWidget extends StatelessWidget {
  final List<List<TtsCell>> grid;
  final int selectedRow;
  final int selectedCol;
  final ClueDirection activeDirection;
  final TtsClue? activeClue;
  final Function(int row, int col) onCellTapped;

  const TtsGridWidget({
    super.key,
    required this.grid,
    required this.selectedRow,
    required this.selectedCol,
    required this.activeDirection,
    required this.activeClue,
    required this.onCellTapped,
  });

  bool _isCellInActiveWord(int r, int c) {
    if (activeClue == null) return false;
    final clue = activeClue!;
    int len = clue.answer.length;

    if (clue.direction == ClueDirection.across) {
      return r == clue.startRow && c >= clue.startCol && c < clue.startCol + len;
    } else {
      return c == clue.startCol && r >= clue.startRow && r < clue.startRow + len;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int rows = grid.length;
    final int cols = grid.isNotEmpty ? grid[0].length : rows;
    final double ratio = cols / (rows > 0 ? rows : 1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: ratio,
          child: Column(
            children: List.generate(rows, (r) {
              return Expanded(
                child: Row(
                  children: List.generate(cols, (c) {
                    return Expanded(
                      child: _buildCell(context, r, c),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int r, int c) {
    final cell = grid[r][c];

    // Inactive space outside the crossword shape -> completely transparent
    if (cell.isBlocked) {
      return const SizedBox.shrink();
    }

    final bool isSelected = r == selectedRow && c == selectedCol;
    final bool isInWord = _isCellInActiveWord(r, c);

    // Dynamic cell styling
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFCBD5E1);
    double borderWidth = 1.2;

    if (isSelected) {
      bgColor = const Color(0xFFE0F2FE);
      borderColor = const Color(0xFF0284C7);
      borderWidth = 2.4;
    } else if (isInWord) {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF34D399);
      borderWidth = 1.8;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onCellTapped(r, c);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  )
                ],
        ),
        child: Stack(
          children: [
            // Clue Number in top-left
            if (cell.clueNumber != null)
              Positioned(
                top: 2,
                left: 3,
                child: Text(
                  '${cell.clueNumber}',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF0284C7)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),

            // Hint Indicator Icon
            if (cell.isRevealed)
              const Positioned(
                bottom: 2,
                right: 2,
                child: Icon(
                  Icons.lock_open_rounded,
                  size: 9,
                  color: Color(0xFF10B981),
                ),
              ),

            // Letter in Center
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.elasticOut,
                  ),
                  child: child,
                ),
                child: Text(
                  cell.currentLetter,
                  key: ValueKey('${r}_${c}_${cell.currentLetter}'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cell.isRevealed
                        ? const Color(0xFF15803D)
                        : (isSelected
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF334155)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
