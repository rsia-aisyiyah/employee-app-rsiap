import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/virus_buster_game.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/models/virus_buster_models.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/services/virus_buster_service.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/widgets/virtual_gamepad.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/widgets/virus_buster_dialogs.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/widgets/virus_buster_hud.dart';

class VirusBusterScreen extends StatefulWidget {
  const VirusBusterScreen({Key? key}) : super(key: key);

  @override
  State<VirusBusterScreen> createState() => _VirusBusterScreenState();
}

class _VirusBusterScreenState extends State<VirusBusterScreen> {
  late VirusBusterGame _game;

  final ValueNotifier<VirusBusterStats> _statsNotifier =
      ValueNotifier<VirusBusterStats>(const VirusBusterStats());

  bool _isGameOver = false;
  bool _isPaused = false;
  int _localBestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadLocalBest();
    _initGame();
  }

  Future<void> _loadLocalBest() async {
    final best = await VirusBusterService.getLocalBest();
    _localBestScore = best['high_score'] ?? 0;
  }

  void _initGame() {
    _game = VirusBusterGame(
      onStatsUpdated: (stats) {
        if (!_isGameOver && !_isPaused) {
          _statsNotifier.value = stats;
        }
      },
      onGameOverCallback: _onGameOver,
      onStageClearedCallback: _onStageCleared,
    );
  }

  void _onGameOver(int finalScore, int stage, int defeated) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _isGameOver = true);

      final isPb = finalScore > _localBestScore;
      if (isPb) {
        _localBestScore = finalScore;
      }

      await VirusBusterService.submitScore(
        score: finalScore,
        stage: stage,
        virusesDefeated: defeated,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => GameOverDialog(
          finalScore: finalScore,
          stage: stage,
          virusesDefeated: defeated,
          isPersonalBest: isPb,
          onRestart: () {
            Navigator.pop(context);
            setState(() => _isGameOver = false);
            _game.restartGame();
          },
          onExit: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  void _onStageCleared(int clearedStage, int currentScore) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => StageClearedDialog(
          clearedStage: clearedStage,
          currentScore: currentScore,
          onNextStage: () {
            Navigator.pop(context);
            _game.nextStage();
          },
        ),
      );
    });
  }

  void _onPause() {
    setState(() => _isPaused = true);
    _game.pauseEngine();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GamePauseDialog(
        onResume: () {
          Navigator.pop(context);
          setState(() => _isPaused = false);
          _game.resumeEngine();
        },
        onRestart: () {
          Navigator.pop(context);
          setState(() => _isPaused = false);
          _game.resumeEngine();
          _game.restartGame();
        },
        onExit: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // 1. Flame Game Canvas
          Positioned.fill(
            child: GameWidget(
              game: _game,
            ),
          ),

          // 2. Heads-Up Display (HUD)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<VirusBusterStats>(
              valueListenable: _statsNotifier,
              builder: (_, stats, __) => VirusBusterHud(
                stats: stats,
                onPause: _onPause,
              ),
            ),
          ),

          // 3. Virtual Gamepad (Kontrol Sentuh Jempol)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VirtualGamepad(
              onLeftDown: () => _game.playerMoveLeft(),
              onRightDown: () => _game.playerMoveRight(),
              onStopMove: () => _game.playerStop(),
              onJump: () => _game.playerJump(),
              onShoot: () => _game.playerShoot(),
            ),
          ),
        ],
      ),
    );
  }
}
