import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VirtualGamepad extends StatefulWidget {
  final VoidCallback onLeftDown;
  final VoidCallback onRightDown;
  final VoidCallback onStopMove;
  final VoidCallback onCrouchDown;
  final VoidCallback onCrouchUp;
  final VoidCallback onJump;
  final VoidCallback onShoot;
  final int shootIntervalMs;

  const VirtualGamepad({
    Key? key,
    required this.onLeftDown,
    required this.onRightDown,
    required this.onStopMove,
    required this.onCrouchDown,
    required this.onCrouchUp,
    required this.onJump,
    required this.onShoot,
    this.shootIntervalMs = 220,
  }) : super(key: key);

  @override
  State<VirtualGamepad> createState() => VirtualGamepadState();
}

class VirtualGamepadState extends State<VirtualGamepad> {
  bool _isLeftPressed = false;
  bool _isRightPressed = false;
  bool _isCrouchPressed = false;
  bool _isJumpPressed = false;
  bool _isShootPressed = false;

  Timer? _rapidFireTimer;

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void reset() {
    _rapidFireTimer?.cancel();
    _rapidFireTimer = null;
    if (mounted) {
      setState(() {
        _isLeftPressed = false;
        _isRightPressed = false;
        _isCrouchPressed = false;
        _isJumpPressed = false;
        _isShootPressed = false;
      });
    }
  }

  void _startShoot() {
    _triggerHaptic();
    setState(() => _isShootPressed = true);
    widget.onShoot();

    // Auto-fire / Rapid Fire saat tombol tembak ditahan (menyesuaikan spesialisasi hero)
    _rapidFireTimer?.cancel();
    _rapidFireTimer = Timer.periodic(Duration(milliseconds: widget.shootIntervalMs), (_) {
      widget.onShoot();
      HapticFeedback.selectionClick();
    });
  }

  void _stopShoot() {
    _rapidFireTimer?.cancel();
    _rapidFireTimer = null;
    if (mounted) {
      setState(() => _isShootPressed = false);
    }
  }

  @override
  void dispose() {
    _rapidFireTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.transparent, // Transparan agar panggung game terlihat jelas
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ─── NAVIGASI 4-ARAH LINGKARAN TRANSPARAN (JEMPOL KIRI) ─────────
          _buildDpadCluster(),

          // ─── TOMBOL TEMBAK TUNGGAL (JEMPOL KANAN) ───────────────────────
          _buildActionCluster(),
        ],
      ),
    );
  }

  // ─── D-PAD 4-ARAH ERGONOMIS & BESAR (LOMPAT, JONGKOK, MUNDUR, JALAN) ──────
  Widget _buildDpadCluster() {
    const double clusterSize = 148.0;
    const double btnSize = 52.0;
    const double centerOffset = (clusterSize - btnSize) / 2; // 48.0

    return SizedBox(
      width: clusterSize,
      height: clusterSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Titik tengah transparan penanda poros resting jempol
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
          ),

          // 1. ATAS (LOMPAT)
          Positioned(
            top: 0,
            left: centerOffset,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) {
                _triggerHaptic();
                setState(() => _isJumpPressed = true);
                widget.onJump();
              },
              onPointerUp: (_) => setState(() => _isJumpPressed = false),
              onPointerCancel: (_) => setState(() => _isJumpPressed = false),
              child: _buildCircularDpadButton(
                icon: Icons.arrow_upward_rounded,
                isPressed: _isJumpPressed,
                activeColor: const Color(0xFFF59E0B), // Emas
                btnSize: btnSize,
              ),
            ),
          ),

          // 2. BAWAH (JONGKOK)
          Positioned(
            bottom: 0,
            left: centerOffset,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) {
                _triggerHaptic();
                setState(() => _isCrouchPressed = true);
                widget.onCrouchDown();
              },
              onPointerUp: (_) {
                setState(() => _isCrouchPressed = false);
                widget.onCrouchUp();
              },
              onPointerCancel: (_) {
                setState(() => _isCrouchPressed = false);
                widget.onCrouchUp();
              },
              child: _buildCircularDpadButton(
                icon: Icons.arrow_downward_rounded,
                isPressed: _isCrouchPressed,
                activeColor: const Color(0xFF38BDF8), // Biru langit
                btnSize: btnSize,
              ),
            ),
          ),

          // 3. KIRI (MUNDUR)
          Positioned(
            left: 0,
            top: centerOffset,
            child: Listener(
              behavior: HitTestBehavior.opaque,
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
              child: _buildCircularDpadButton(
                icon: Icons.arrow_back_rounded,
                isPressed: _isLeftPressed,
                activeColor: const Color(0xFF00E5FF), // Cyan neon
                btnSize: btnSize,
              ),
            ),
          ),

          // 4. KANAN (MAJU / JALAN)
          Positioned(
            right: 0,
            top: centerOffset,
            child: Listener(
              behavior: HitTestBehavior.opaque,
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
              child: _buildCircularDpadButton(
                icon: Icons.arrow_forward_rounded,
                isPressed: _isRightPressed,
                activeColor: const Color(0xFF00E5FF), // Cyan neon
                btnSize: btnSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularDpadButton({
    required IconData icon,
    required bool isPressed,
    required Color activeColor,
    required double btnSize,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      width: btnSize,
      height: btnSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPressed
            ? activeColor.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.35),
        border: Border.all(
          color: isPressed
              ? Colors.white
              : Colors.white.withValues(alpha: 0.45),
          width: isPressed ? 2.4 : 1.6,
        ),
        boxShadow: [
          if (isPressed)
            BoxShadow(
              color: activeColor.withValues(alpha: 0.65),
              blurRadius: 12,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 30,
          color: isPressed ? Colors.white : Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }

  // ─── ACTION CLUSTER: TOMBOL TEMBAK TUNGGAL (JEMPOL KANAN) ───────────────────
  Widget _buildActionCluster() {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _startShoot(),
      onPointerUp: (_) => _stopShoot(),
      onPointerCancel: (_) => _stopShoot(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isShootPressed
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.8)
                  : const Color(0xFF0F766E).withValues(alpha: 0.55),
              border: Border.all(
                color: _isShootPressed
                    ? Colors.white
                    : const Color(0xFF00E5FF).withValues(alpha: 0.75),
                width: _isShootPressed ? 2.8 : 2.0,
              ),
              boxShadow: [
                if (_isShootPressed)
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                    blurRadius: 18,
                    spreadRadius: 3,
                  )
                else
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.vaccines_rounded,
                size: 33,
                color: _isShootPressed ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'TEMBAK',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: _isShootPressed
                  ? const Color(0xFF00E5FF)
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
