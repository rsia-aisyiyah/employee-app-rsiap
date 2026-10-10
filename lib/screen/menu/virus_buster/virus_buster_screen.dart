import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/game/virus_buster_game.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/models/virus_buster_models.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/services/virus_buster_service.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/widgets/virtual_gamepad.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/widgets/virus_buster_dialogs.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/widgets/virus_buster_hud.dart';

class VirusBusterScreen extends StatefulWidget {
  final HeroConfig? heroConfig;
  final GameDifficulty difficulty;

  const VirusBusterScreen({
    Key? key,
    this.heroConfig,
    this.difficulty = GameDifficulty.medium,
  }) : super(key: key);

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

  // ─── KEYBOARD CONTROL SUPPORT (EMULATOR / PHYSICAL KEYBOARD) ─────────────
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Timer? _keyboardShootTimer;

  // ─── VIRTUAL GAMEPAD KEY (UNTUK RESET STATUS TOMBOL SAAT TRANSISI) ────────
  final GlobalKey<VirtualGamepadState> _gamepadKey = GlobalKey<VirtualGamepadState>();

  void _resetAllInput() {
    _stopKeyboardShoot();
    _pressedKeys.clear();
    _gamepadKey.currentState?.reset();
    _game.playerStop();
    _game.playerStandUp();
  }

  @override
  void initState() {
    super.initState();
    _loadLocalBest();
    _initGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardShootTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_isGameOver || _isPaused) return;

    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      if (_pressedKeys.contains(key)) return;
      _pressedKeys.add(key);

      // Escape / P -> Pause Game
      if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP) {
        _onPause();
        return;
      }

      // Gerak Kiri: A atau Panah Kiri
      if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.arrowLeft) {
        _game.playerMoveLeft();
      }
      // Gerak Kanan: D atau Panah Kanan
      else if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.arrowRight) {
        _game.playerMoveRight();
      }

      // Lompat: W, Panah Atas, atau Space
      if (key == LogicalKeyboardKey.keyW ||
          key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.space) {
        _game.playerJump();
      }

      // Jongkok: S atau Panah Bawah
      if (key == LogicalKeyboardKey.keyS || key == LogicalKeyboardKey.arrowDown) {
        _game.playerCrouch();
      }

      // Tembak: J, K, Z, X, C, atau Enter
      if (key == LogicalKeyboardKey.keyJ ||
          key == LogicalKeyboardKey.keyK ||
          key == LogicalKeyboardKey.keyZ ||
          key == LogicalKeyboardKey.keyX ||
          key == LogicalKeyboardKey.keyC ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        _startKeyboardShoot();
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(key);

      // Cek gerakan horizontal saat tombol dilepas
      final isLeft = _pressedKeys.contains(LogicalKeyboardKey.keyA) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowLeft);
      final isRight = _pressedKeys.contains(LogicalKeyboardKey.keyD) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowRight);

      if (isLeft && !isRight) {
        _game.playerMoveLeft();
      } else if (isRight && !isLeft) {
        _game.playerMoveRight();
      } else {
        _game.playerStop();
      }

      // Cek jongkok dilepas
      final isDown = _pressedKeys.contains(LogicalKeyboardKey.keyS) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowDown);
      if (!isDown) {
        _game.playerStandUp();
      }

      // Cek tembak dilepas
      final isShooting = _pressedKeys.contains(LogicalKeyboardKey.keyJ) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyK) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyZ) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyX) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyC) ||
          _pressedKeys.contains(LogicalKeyboardKey.enter) ||
          _pressedKeys.contains(LogicalKeyboardKey.numpadEnter);
      if (!isShooting) {
        _stopKeyboardShoot();
      }
    }
  }

  void _startKeyboardShoot() {
    _game.playerShoot();
    _keyboardShootTimer?.cancel();
    final interval = (200 * (widget.heroConfig?.shootCooldownMultiplier ?? 1.0)).round();
    _keyboardShootTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!_isGameOver && !_isPaused) {
        _game.playerShoot();
      }
    });
  }

  void _stopKeyboardShoot() {
    _keyboardShootTimer?.cancel();
    _keyboardShootTimer = null;
  }

  Future<void> _loadLocalBest() async {
    final best = await VirusBusterService.getLocalBest();
    _localBestScore = best['high_score'] ?? 0;
  }

  void _initGame() {
    _game = VirusBusterGame(
      heroConfig: widget.heroConfig,
      difficulty: widget.difficulty,
      onStatsUpdated: (stats) {
        if (!_isGameOver && !_isPaused) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _statsNotifier.value = stats;
            }
          });
        }
      },
      onGameOverCallback: _onGameOver,
      onStageClearedCallback: _onStageCleared,
    );
  }

  void _onGameOver(int finalScore, int stage, int defeated) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _resetAllInput();
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
            _resetAllInput();
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _resetAllInput();

      final isGameComplete = clearedStage >= StageConfig.stages.length;

      if (isGameComplete) {
        final isPb = currentScore > _localBestScore;
        if (isPb) {
          _localBestScore = currentScore;
        }

        await VirusBusterService.submitScore(
          score: currentScore,
          stage: clearedStage,
          virusesDefeated: _game.virusesDefeated,
        );

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => GameVictoryDialog(
            totalScore: currentScore,
            virusesDefeated: _game.virusesDefeated,
            isPersonalBest: isPb,
            onFinishAndExit: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke menu utama Virus Buster
            },
            onContinueEndless: () {
              Navigator.pop(context);
              _resetAllInput();
              _game.nextStage();
            },
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => StageClearedDialog(
            clearedStage: clearedStage,
            currentScore: currentScore,
            onNextStage: () {
              Navigator.pop(context);
              _resetAllInput();
              _game.nextStage();
            },
          ),
        );
      }
    });
  }

  void _onPause() {
    _resetAllInput();
    setState(() => _isPaused = true);
    _game.pauseEngine();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GamePauseDialog(
        onResume: () {
          Navigator.pop(context);
          _resetAllInput();
          setState(() => _isPaused = false);
          _game.resumeEngine();
        },
        onRestart: () {
          Navigator.pop(context);
          _resetAllInput();
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
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
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
              key: _gamepadKey,
              shootIntervalMs: (220 * (widget.heroConfig?.shootCooldownMultiplier ?? 1.0)).round(),
              onLeftDown: () => _game.playerMoveLeft(),
              onRightDown: () => _game.playerMoveRight(),
              onStopMove: () => _game.playerStop(),
              onCrouchDown: () => _game.playerCrouch(),
              onCrouchUp: () => _game.playerStandUp(),
              onJump: () => _game.playerJump(),
              onShoot: () => _game.playerShoot(),
            ),
          ),
        ],
      ),
    ),
  );
}
}
