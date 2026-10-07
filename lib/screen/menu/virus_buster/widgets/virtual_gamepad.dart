import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VirtualGamepad extends StatefulWidget {
  final VoidCallback onLeftDown;
  final VoidCallback onRightDown;
  final VoidCallback onStopMove;
  final VoidCallback onJump;
  final VoidCallback onShoot;

  const VirtualGamepad({
    Key? key,
    required this.onLeftDown,
    required this.onRightDown,
    required this.onStopMove,
    required this.onJump,
    required this.onShoot,
  }) : super(key: key);

  @override
  State<VirtualGamepad> createState() => _VirtualGamepadState();
}

class _VirtualGamepadState extends State<VirtualGamepad> {
  bool _isLeftPressed = false;
  bool _isRightPressed = false;
  bool _isJumpPressed = false;
  bool _isShootPressed = false;

  Timer? _rapidFireTimer;

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _startShoot() {
    _triggerHaptic();
    setState(() => _isShootPressed = true);
    widget.onShoot();

    // Auto-fire / Rapid Fire saat tombol tembak ditahan (setiap 220ms)
    _rapidFireTimer?.cancel();
    _rapidFireTimer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      widget.onShoot();
      HapticFeedback.selectionClick();
    });
  }

  void _stopShoot() {
    _rapidFireTimer?.cancel();
    _rapidFireTimer = null;
    setState(() => _isShootPressed = false);
  }

  @override
  void dispose() {
    _rapidFireTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0D1117).withOpacity(0.8),
            const Color(0xFF0D1117).withOpacity(0.96),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ─── D-PAD KIRI & KANAN (JEMPOL KIRI ERGONOMIS) ─────────────
          _buildDpadCluster(),

          // ─── ACTION CLUSTER KANAN (DIAGONAL ARC: LOMPAT & TEMBAK) ────
          _buildActionCluster(),
        ],
      ),
    );
  }

  // ─── D-PAD CLUSTER (PILLED ARCADE ROCKER) ──────────────────────────────────
  Widget _buildDpadCluster() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol KIRI
          Listener(
            onPointerDown: (_) {
              _triggerHaptic();
              setState(() => _isLeftPressed = true);
              widget.onLeftDown();
            },
            onPointerUp: (_) {
              setState(() => _isLeftPressed = false);
              widget.onStopMove();
            },
            onPointerCancel: (_) {
              setState(() => _isLeftPressed = false);
              widget.onStopMove();
            },
            child: _buildDpadKey(
              icon: Icons.arrow_back_rounded,
              isPressed: _isLeftPressed,
              isLeft: true,
            ),
          ),

          Container(
            width: 1.5,
            height: 36,
            color: Colors.white.withOpacity(0.08),
          ),

          // Tombol KANAN
          Listener(
            onPointerDown: (_) {
              _triggerHaptic();
              setState(() => _isRightPressed = true);
              widget.onRightDown();
            },
            onPointerUp: (_) {
              setState(() => _isRightPressed = false);
              widget.onStopMove();
            },
            onPointerCancel: (_) {
              setState(() => _isRightPressed = false);
              widget.onStopMove();
            },
            child: _buildDpadKey(
              icon: Icons.arrow_forward_rounded,
              isPressed: _isRightPressed,
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDpadKey({
    required IconData icon,
    required bool isPressed,
    required bool isLeft,
  }) {
    final activeColor = const Color(0xFF00A896);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 58,
      height: 54,
      decoration: BoxDecoration(
        color: isPressed ? activeColor.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(18) : Radius.zero,
          right: !isLeft ? const Radius.circular(18) : Radius.zero,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 28,
          color: isPressed ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }

  // ─── ACTION CLUSTER DIAGONAL (ARC ERGONOMIS JEMPOL KANAN) ───────────────────
  // Tombol LOMPAT di posisi bawah-kiri dan TEMBAK di posisi atas-kanan
  // Sangat mudah ditekan bersamaan (bisa menahan tembak sambil mengetuk lompat!)
  Widget _buildActionCluster() {
    return SizedBox(
      width: 145,
      height: 105,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Tombol LOMPAT (Di Bawah-Kiri / Dekat pangkal jempol)
          Positioned(
            left: 0,
            bottom: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Listener(
                  onPointerDown: (_) {
                    _triggerHaptic();
                    setState(() => _isJumpPressed = true);
                    widget.onJump();
                  },
                  onPointerUp: (_) => setState(() => _isJumpPressed = false),
                  onPointerCancel: (_) => setState(() => _isJumpPressed = false),
                  child: _buildActionButton(
                    icon: Icons.arrow_upward_rounded,
                    label: 'A',
                    size: 52,
                    isPressed: _isJumpPressed,
                    activeColor: const Color(0xFFF59E0B), // Emas arcade
                    baseColor: const Color(0xFF1E293B),
                    subLabel: 'LOMPAT',
                  ),
                ),
              ],
            ),
          ),

          // 2. Tombol TEMBAK (Di Atas-Kanan / Ujung jempol)
          // Berukuran lebih besar (62px) dengan Rapid-Fire saat ditahan
          Positioned(
            right: 0,
            top: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Listener(
                  onPointerDown: (_) => _startShoot(),
                  onPointerUp: (_) => _stopShoot(),
                  onPointerCancel: (_) => _stopShoot(),
                  child: _buildActionButton(
                    icon: Icons.vaccines_rounded,
                    label: 'B',
                    size: 62,
                    isPressed: _isShootPressed,
                    activeColor: const Color(0xFF00E5FF), // Cyan neon RSIA
                    baseColor: const Color(0xFF0F766E),
                    subLabel: 'TEMBAK',
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required double size,
    required bool isPressed,
    required Color activeColor,
    required Color baseColor,
    required String subLabel,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPressed ? activeColor : baseColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isPressed ? Colors.white : (isPrimary ? activeColor.withOpacity(0.6) : Colors.white24),
              width: isPressed ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (isPressed)
                BoxShadow(
                  color: activeColor.withOpacity(0.6),
                  blurRadius: 18,
                  spreadRadius: 2,
                )
              else if (isPrimary)
                BoxShadow(
                  color: activeColor.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ikon Medis / Aksi
              Icon(
                icon,
                size: size * 0.46,
                color: isPressed ? const Color(0xFF0F172A) : Colors.white,
              ),

              // Huruf Tombol Retro (A / B) di Sudut Atas
              Positioned(
                top: 4,
                right: 7,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isPressed ? Colors.black54 : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subLabel,
          style: TextStyle(
            color: isPressed ? activeColor : Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}
