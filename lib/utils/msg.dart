import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';

class Msg {
  static OverlayEntry? _currentOverlay;
  static Timer? _timer;

  static _showOverlay({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    // Remove existing notification if any
    _timer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon,
        color: color,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    overlay.insert(_currentOverlay!);

    _timer = Timer(const Duration(seconds: snackBarDuration), () {
      if (_currentOverlay != null) {
        _currentOverlay?.remove();
        _currentOverlay = null;
      }
    });
  }

  static show(BuildContext context, String message) {
    _showOverlay(
      context: context,
      message: message,
      icon: Icons.info_outline_rounded,
      color: primaryColor,
    );
  }

  static success(BuildContext context, String message) {
    _showOverlay(
      context: context,
      message: message,
      icon: Icons.check_circle_rounded,
      color: Colors.green,
    );
  }

  static info(BuildContext context, String message) {
    _showOverlay(
      context: context,
      message: message,
      icon: Icons.info_outline_rounded,
      color: primaryColor,
    );
  }

  static warning(BuildContext context, String message) {
    _showOverlay(
      context: context,
      message: message,
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
    );
  }

  static error(BuildContext context, String message) {
    _showOverlay(
      context: context,
      message: message,
      icon: Icons.error_outline_rounded,
      color: Colors.red,
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Auto-dismiss after duration minus animation time
    Future.delayed(
        Duration(seconds: snackBarDuration) - const Duration(milliseconds: 400),
        () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: widget.color.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
