import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/undangan.dart';

/// A sleek, space-efficient Mini Ticket Strip (~85px)
/// for displaying upcoming meeting invitations on the employee dashboard.
class CardUndanganTicket extends StatelessWidget {
  final Map<String, dynamic> data;
  final int totalCount;
  final int currentIndex;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  const CardUndanganTicket({
    super.key,
    required this.data,
    this.totalCount = 1,
    this.currentIndex = 0,
    this.onNext,
    this.onPrev,
  });

  DateTime? get _eventDate {
    final raw = data['tanggal'] ?? data['tgl_terbit'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  String _getCountdownLabel(DateTime event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(event.year, event.month, event.day);
    final diffDays = eventDay.difference(today).inDays;

    if (diffDays == 0) {
      final diffHours = event.difference(now).inHours;
      if (diffHours > 0) {
        return "HARI INI • $diffHours JAM LAGI";
      } else if (diffHours == 0) {
        final diffMins = event.difference(now).inMinutes;
        if (diffMins > 0) return "HARI INI • $diffMins MENIT";
        return "SEDANG BERLANGSUNG";
      }
      return "HARI INI";
    } else if (diffDays == 1) {
      return "BESOK";
    } else if (diffDays > 1) {
      return "$diffDays HARI LAGI";
    } else {
      return "SELESAI";
    }
  }

  Color _getCountdownColor(DateTime event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(event.year, event.month, event.day);
    final diffDays = eventDay.difference(today).inDays;

    if (diffDays == 0) {
      return const Color(0xFFEF4444); // Red alert for today
    } else if (diffDays == 1) {
      return const Color(0xFFF59E0B); // Amber
    } else if (diffDays > 1) {
      return const Color(0xFF0284C7); // Sky Blue
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = _eventDate ?? DateTime.now();
    final perihal = data['perihal']?.toString() ?? "Rapat / Kegiatan Internal";
    final tempat = (data['lokasi'] ?? data['tempat'] ?? "-").toString();

    final countdownLabel = _getCountdownLabel(eventDate);
    final countdownColor = _getCountdownColor(eventDate);
    final dayStr = DateFormat("dd", "id_ID").format(eventDate);
    final monthStr = DateFormat("MMM", "id_ID").format(eventDate).toUpperCase();
    final timeStr = DateFormat("HH:mm", "id_ID").format(eventDate);

    final ticketNo = "INV-${(data['id'] ?? data['surat_id'] ?? '000').toString().padLeft(4, '0')}";

    const stubWidth = 80.0;
    const notchRadius = 6.0;
    const cardHeight = 86.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipPath(
          clipper: _MiniTicketClipper(
            stubWidth: stubWidth,
            notchRadius: notchRadius,
            cornerRadius: 16.0,
          ),
          child: Material(
            color: Colors.white,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Undangan(),
                  ),
                );
              },
              child: Stack(
                children: [
                  Row(
                    children: [
                      // ── LEFT STUB: Date & Time ─────────────────────────
                      Container(
                        width: stubWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withValues(alpha: 0.14),
                              primaryColor.withValues(alpha: 0.04),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayStr,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              monthStr,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 9,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── VERTICAL PERFORATION ────────────────────────────
                      CustomPaint(
                        painter: _VerticalDashedLinePainter(
                          color: Colors.grey[300]!,
                          notchRadius: notchRadius,
                          dashHeight: 3.5,
                          dashSpace: 3.0,
                        ),
                        size: const Size(1, cardHeight),
                      ),

                      // ── RIGHT SECTION: Details & Action ─────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Bar: Countdown & Pager / Ticket ID
                              Row(
                                children: [
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: countdownColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: countdownColor.withValues(alpha: 0.25),
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (countdownColor == const Color(0xFFEF4444)) ...[
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                        ],
                                        Text(
                                          countdownLabel,
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: countdownColor,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),

                                  // Pagination or Ticket No
                                  if (totalCount > 1) ...[
                                    InkWell(
                                      onTap: onPrev,
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(
                                          Icons.chevron_left_rounded,
                                          size: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "${currentIndex + 1}/$totalCount",
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: onNext,
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          size: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      ticketNo,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[400],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Perihal Title (Max 1 line to save vertical rhythm)
                              Text(
                                perihal,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.2,
                                ),
                              ),

                              // Bottom Row: Location & Buka button
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 11,
                                    color: Colors.red[400],
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      tempat,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Buka",
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 9,
                                          color: primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

/// Custom Clipper for Mini Horizontal Ticket with Top and Bottom Inward Notches
class _MiniTicketClipper extends CustomClipper<Path> {
  final double stubWidth;
  final double notchRadius;
  final double cornerRadius;

  _MiniTicketClipper({
    required this.stubWidth,
    required this.notchRadius,
    required this.cornerRadius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final notchX = stubWidth;

    // Start from top-left after corner
    path.moveTo(cornerRadius, 0);

    // Top edge to notch
    path.lineTo(notchX - notchRadius, 0);

    // Top notch cutout (concave inward into the card)
    path.arcToPoint(
      Offset(notchX + notchRadius, 0),
      radius: Radius.circular(notchRadius),
      clockwise: true,
    );

    // Top edge to top-right corner
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Right edge to bottom-right corner
    path.lineTo(size.width, size.height - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: Radius.circular(cornerRadius),
    );

    // Bottom edge to bottom notch
    path.lineTo(notchX + notchRadius, size.height);

    // Bottom notch cutout (concave inward into the card)
    path.arcToPoint(
      Offset(notchX - notchRadius, size.height),
      radius: Radius.circular(notchRadius),
      clockwise: true,
    );

    // Bottom edge to bottom-left corner
    path.lineTo(cornerRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Left edge to top-left corner
    path.lineTo(0, cornerRadius);
    path.arcToPoint(
      Offset(cornerRadius, 0),
      radius: Radius.circular(cornerRadius),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// Custom painter for the vertical perforated dashed line
class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;
  final double notchRadius;
  final double dashHeight;
  final double dashSpace;

  _VerticalDashedLinePainter({
    required this.color,
    required this.notchRadius,
    this.dashHeight = 3.5,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.9;

    double startY = notchRadius + 2.0;
    final endY = size.height - notchRadius - 2.0;

    while (startY < endY) {
      final currentDashHeight = (startY + dashHeight > endY) ? (endY - startY) : dashHeight;
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + currentDashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
