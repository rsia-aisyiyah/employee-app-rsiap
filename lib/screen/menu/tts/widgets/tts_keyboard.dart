import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TtsKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onHintPressed;
  final int hintQuota;

  const TtsKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onDeletePressed,
    required this.onHintPressed,
    this.hintQuota = 3,
  });

  static const List<String> row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  static const List<String> row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  static const List<String> row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow(row1),
            const SizedBox(height: 5),
            _buildRow(row2),
            const SizedBox(height: 5),
            _buildRow3(),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildRow3() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hint Button
        _buildActionButton(
          icon: Icons.lightbulb_outline_rounded,
          color: const Color(0xFFF59E0B),
          badge: hintQuota > 0 ? '$hintQuota' : null,
          onTap: () {
            HapticFeedback.mediumImpact();
            onHintPressed();
          },
          tooltip: 'Bantuan Hint',
        ),

        // Letters Z - M
        ...row3.map((key) => _buildKey(key)),

        // Delete Button
        _buildActionButton(
          icon: Icons.backspace_outlined,
          color: const Color(0xFFEF4444),
          onTap: () {
            HapticFeedback.selectionClick();
            onDeletePressed();
          },
          tooltip: 'Hapus',
        ),
      ],
    );
  }

  Widget _buildKey(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: _AnimatedKeyButton(
          label: label,
          onTap: () {
            HapticFeedback.lightImpact();
            onKeyPressed(label);
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    required String tooltip,
  }) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: color, size: 20),
                  if (badge != null)
                    Positioned(
                      top: 4,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedKeyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AnimatedKeyButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_AnimatedKeyButton> createState() => _AnimatedKeyButtonState();
}

class _AnimatedKeyButtonState extends State<_AnimatedKeyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isPressed ? const Color(0xFFE2E8F0) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, 1.5),
                blurRadius: 1,
              ),
            ],
            border: Border.all(
              color: const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}
