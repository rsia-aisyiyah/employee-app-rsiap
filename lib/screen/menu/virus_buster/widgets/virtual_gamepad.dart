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

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0D1117).withOpacity(0.85),
            const Color(0xFF0D1117),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ─── D-PAD KIRI & KANAN (JEMPOL KIRI) ──────────────────────────
          Row(
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
                child: _buildArcadeButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'KIRI',
                  isPressed: _isLeftPressed,
                  baseColor: const Color(0xFF1E293B),
                  activeColor: const Color(0xFF00A896),
                ),
              ),
              const SizedBox(width: 14),

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
                child: _buildArcadeButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'KANAN',
                  isPressed: _isRightPressed,
                  baseColor: const Color(0xFF1E293B),
                  activeColor: const Color(0xFF00A896),
                ),
              ),
            ],
          ),

          // ─── ACTION BUTTONS (JEMPOL KANAN: LOMPAT & TEMBAK) ───────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tombol LOMPAT (JUMP)
              Listener(
                onPointerDown: (_) {
                  _triggerHaptic();
                  setState(() => _isJumpPressed = true);
                  widget.onJump();
                },
                onPointerUp: (_) => setState(() => _isJumpPressed = false),
                onPointerCancel: (_) => setState(() => _isJumpPressed = false),
                child: _buildArcadeButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  label: 'LOMPAT',
                  isPressed: _isJumpPressed,
                  baseColor: const Color(0xFF1E293B),
                  activeColor: const Color(0xFFF59E0B),
                  isRound: true,
                ),
              ),
              const SizedBox(width: 16),

              // Tombol TEMBAK (SHOOT)
              Listener(
                onPointerDown: (_) {
                  _triggerHaptic();
                  setState(() => _isShootPressed = true);
                  widget.onShoot();
                },
                onPointerUp: (_) => setState(() => _isShootPressed = false),
                onPointerCancel: (_) => setState(() => _isShootPressed = false),
                child: _buildArcadeButton(
                  icon: Icons.vaccines_rounded,
                  label: 'TEMBAK',
                  isPressed: _isShootPressed,
                  baseColor: const Color(0xFF0F766E),
                  activeColor: const Color(0xFF00E5FF),
                  isRound: true,
                  size: 64,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArcadeButton({
    required IconData icon,
    required String label,
    required bool isPressed,
    required Color baseColor,
    required Color activeColor,
    bool isRound = false,
    double size = 56,
  }) {
    final currentColor = isPressed ? activeColor : baseColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: currentColor,
            shape: isRound ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isRound ? null : BorderRadius.circular(16),
            border: Border.all(
              color: isPressed ? activeColor : Colors.white.withOpacity(0.18),
              width: isPressed ? 2.5 : 1.2,
            ),
            boxShadow: [
              if (isPressed)
                BoxShadow(
                  color: activeColor.withOpacity(0.55),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.48,
              color: isPressed ? Colors.white : Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isPressed ? activeColor : Colors.white54,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
