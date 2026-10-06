import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/emergency_rush_leaderboard_screen.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/game/emergency_rush_game.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/services/emergency_rush_service.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/widgets/emergency_rush_hud.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/widgets/game_over_dialog.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/widgets/pause_dialog.dart';

class EmergencyRushHudStats {
  final int score;
  final int distance;
  final int speed;
  final int lives;
  final double sirenEnergy;
  final bool isSirenActive;

  const EmergencyRushHudStats({
    this.score = 0,
    this.distance = 0,
    this.speed = 60,
    this.lives = 3,
    this.sirenEnergy = 0.0,
    this.isSirenActive = false,
  });
}

class EmergencyRushScreen extends StatefulWidget {
  const EmergencyRushScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyRushScreen> createState() => _EmergencyRushScreenState();
}

class _EmergencyRushScreenState extends State<EmergencyRushScreen> {
  late EmergencyRushGame _game;

  // ValueNotifier to prevent triggering setState() during GameWidget build/layout phase
  final ValueNotifier<EmergencyRushHudStats> _statsNotifier =
      ValueNotifier<EmergencyRushHudStats>(const EmergencyRushHudStats());

  // Session state
  bool _isGameOver = false;
  bool _isPaused = false;
  bool _isSubmittingScore = false;
  bool _isPersonalBest = false;
  int? _globalRank;

  // Local best
  int _localBestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadLocalBest();
    _initGame();
  }

  Future<void> _loadLocalBest() async {
    final best = await EmergencyRushService.getLocalBest();
    _localBestScore = best['high_score'] ?? 0;
  }

  void _initGame() {
    _game = EmergencyRushGame(
      onStatsUpdated: (score, distance, speed, lives, energy, isSiren) {
        if (!_isGameOver && !_isPaused) {
          _statsNotifier.value = EmergencyRushHudStats(
            score: score,
            distance: distance,
            speed: speed,
            lives: lives,
            sirenEnergy: energy,
            isSirenActive: isSiren,
          );
        }
      },
      onGameOverCallback: _onGameOver,
    );
  }

  void _onGameOver(int finalScore, int distance, int items, int maxSpeed) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      setState(() {
        _isGameOver = true;
        _isSubmittingScore = true;
        _isPersonalBest = finalScore > _localBestScore;
      });

      if (_isPersonalBest) {
        _localBestScore = finalScore;
      }

      // Submit to API
      final result = await EmergencyRushService.submitScore(
        score: finalScore,
        distanceMeters: distance,
        itemsCollected: items,
        maxSpeed: maxSpeed,
      );

      if (mounted) {
        setState(() {
          _isSubmittingScore = false;
          if (result['success'] == true && result['data'] != null) {
            _globalRank = result['data']['rank'];
            _isPersonalBest = result['data']['is_personal_best'] == true || _isPersonalBest;
          }
        });
      }
    });
  }

  void _restartGame() {
    setState(() {
      _isGameOver = false;
      _isPaused = false;
      _isSubmittingScore = false;
      _globalRank = null;
    });
    _statsNotifier.value = const EmergencyRushHudStats();
    _game.restart();
  }

  void _pauseGame() {
    if (_isGameOver) return;
    _game.pause();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    _game.resume();
    setState(() => _isPaused = false);
  }

  @override
  void dispose() {
    _statsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─── FLAME GAME WIDGET WITH SWIPE GESTURE ───────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0.0;
              if (velocity > 180) {
                // Swipe Right
                _game.movePlayerRight();
              } else if (velocity < -180) {
                // Swipe Left
                _game.movePlayerLeft();
              }
            },
            onDoubleTap: () {
              _game.activateSirenRush();
            },
            child: GameWidget(
              game: _game,
            ),
          ),

          // ─── REACTIONARY HUD OVERLAY VIA VALUE NOTIFIER ──────────
          ValueListenableBuilder<EmergencyRushHudStats>(
            valueListenable: _statsNotifier,
            builder: (context, stats, _) {
              if (_isGameOver || _isPaused) return const SizedBox.shrink();

              return EmergencyRushHud(
                score: stats.score,
                distance: stats.distance,
                speed: stats.speed,
                lives: stats.lives,
                sirenEnergy: stats.sirenEnergy,
                isSirenActive: stats.isSirenActive,
                onPause: _pauseGame,
                onMoveLeft: () => _game.movePlayerLeft(),
                onMoveRight: () => _game.movePlayerRight(),
                onActivateSiren: () => _game.activateSirenRush(),
              );
            },
          ),

          // ─── PAUSE DIALOG OVERLAY ────────────────────────────────
          if (_isPaused)
            Center(
              child: PauseDialog(
                onResume: _resumeGame,
                onRestart: _restartGame,
                onExit: () => Navigator.pop(context),
              ),
            ),

          // ─── GAME OVER DIALOG OVERLAY ────────────────────────────
          if (_isGameOver)
            Center(
              child: GameOverDialog(
                score: _statsNotifier.value.score,
                distance: _statsNotifier.value.distance,
                itemsCollected: _game.itemsCollected,
                topSpeed: _game.topSpeedAchieved,
                isSubmitting: _isSubmittingScore,
                isPersonalBest: _isPersonalBest,
                globalRank: _globalRank,
                onPlayAgain: _restartGame,
                onShowLeaderboard: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmergencyRushLeaderboardScreen()),
                  );
                },
                onExit: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }
}
