class TtsCell {
  final int row;
  final int col;
  final String correctLetter;
  final bool isBlocked;
  final int? clueNumber;
  String currentLetter;
  bool isRevealed;

  TtsCell({
    required this.row,
    required this.col,
    required this.correctLetter,
    this.isBlocked = false,
    this.clueNumber,
    this.currentLetter = '',
    this.isRevealed = false,
  });

  bool get isCorrect =>
      isBlocked || currentLetter.toUpperCase() == correctLetter.toUpperCase();
}

enum ClueDirection { across, down }

class TtsClue {
  final int number;
  final ClueDirection direction;
  final String clueText;
  final String answer;
  final int startRow;
  final int startCol;

  TtsClue({
    required this.number,
    required this.direction,
    required this.clueText,
    required this.answer,
    required this.startRow,
    required this.startCol,
  });
}

class TtsLevel {
  final int id;
  final String title;
  final String category;
  final int size; // e.g. 5 for 5x5
  final List<TtsClue> clues;
  final String description;
  final bool isCompleted;
  final int? userScore;
  final int? userTimeSeconds;
  final int? totalClues;
  final int? customRows;
  final int? customCols;

  TtsLevel({
    required this.id,
    required this.title,
    required this.category,
    this.size = 5,
    required this.clues,
    this.description = '',
    this.isCompleted = false,
    this.userScore,
    this.userTimeSeconds,
    this.totalClues,
    this.customRows,
    this.customCols,
  });

  int get wordCount {
    if (clues.isNotEmpty) return clues.length;
    if (totalClues != null && totalClues! > 0) return totalClues!;
    return 4;
  }

  int get numRows {
    if (customRows != null && customRows! > 0) return customRows!;
    int maxR = 0;
    for (var clue in clues) {
      int endR = clue.direction == ClueDirection.across
          ? clue.startRow + 1
          : clue.startRow + clue.answer.length;
      if (endR > maxR) maxR = endR;
    }
    return maxR > 0 ? maxR : size;
  }

  int get numCols {
    if (customCols != null && customCols! > 0) return customCols!;
    int maxC = 0;
    for (var clue in clues) {
      int endC = clue.direction == ClueDirection.across
          ? clue.startCol + clue.answer.length
          : clue.startCol + 1;
      if (endC > maxC) maxC = endC;
    }
    return maxC > 0 ? maxC : size;
  }

  /// Build a 2D matrix of TtsCell from clues with dynamic dimensions
  List<List<TtsCell>> buildGrid() {
    final int rows = numRows;
    final int cols = numCols;

    // Start with all cells blocked (inactive outside puzzle shape)
    List<List<TtsCell>> grid = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => TtsCell(
          row: r,
          col: c,
          correctLetter: '',
          isBlocked: true,
        ),
      ),
    );

    // Populate active crossword cells from clues
    for (var clue in clues) {
      int r = clue.startRow;
      int c = clue.startCol;
      String ans = clue.answer.toUpperCase();

      for (int i = 0; i < ans.length; i++) {
        int curR = clue.direction == ClueDirection.across ? r : r + i;
        int curC = clue.direction == ClueDirection.across ? c + i : c;

        if (curR < rows && curC < cols) {
          int? number;
          if (i == 0) {
            number = clue.number;
          } else {
            number = grid[curR][curC].clueNumber;
          }

          grid[curR][curC] = TtsCell(
            row: curR,
            col: curC,
            correctLetter: ans[i],
            isBlocked: false,
            clueNumber: number,
          );
        }
      }
    }

    return grid;
  }
}

class TtsPlayerScore {
  final String name;
  final String department;
  final String? avatar;
  final int timeSeconds;
  final int hintsUsed;
  final int score;
  final DateTime playedAt;

  TtsPlayerScore({
    required this.name,
    required this.department,
    this.avatar,
    required this.timeSeconds,
    this.hintsUsed = 0,
    required this.score,
    required this.playedAt,
  });

  String get formattedTime {
    int m = timeSeconds ~/ 60;
    int s = timeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
