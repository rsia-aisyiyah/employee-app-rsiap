import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/undangan.dart';

/// A premium, non-mainstream Ticket Stub / Boarding Pass widget
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
        if (diffMins > 0) return "HARI INI • $diffMins MENIT LAGI";
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
      return const Color(0xFFEF4444); // Red/Amber alert for today
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
    
    // PIC resolution
    String? picName;
    if (data['penanggung_jawab'] is Map) {
      picName = data['penanggung_jawab']['nama']?.toString();
    } else if (data['penanggungJawab'] is Map) {
      picName = data['penanggungJawab']['nama']?.toString();
    }
    picName ??= data['pj']?.toString();

    final countdownLabel = _getCountdownLabel(eventDate);
    final countdownColor = _getCountdownColor(eventDate);
    final timeStr = DateFormat("HH:mm", "id_ID").format(eventDate);
    final dateStr = DateFormat("EEEE, d MMMM yyyy", "id_ID").format(eventDate);

    // Dynamic ticket number from ID or surat_id
    final ticketNo = "INV-${(data['id'] ?? data['surat_id'] ?? '000').toString().padLeft(4, '0')}";

    const notchRadius = 10.0;
    const notchFromBottom = 44.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipPath(
          clipper: _TicketClipper(
            notchRadius: notchRadius,
            notchFromBottom: notchFromBottom,
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
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.white,
                      primaryColor.withValues(alpha: 0.025),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header Band ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.15),
                            primaryColor.withValues(alpha: 0.04),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 14,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "AGENDA UNDANGAN",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: primaryColor.withValues(alpha: 0.9),
                                ),
                              ),
                              if (totalCount > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${currentIndex + 1}/$totalCount",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // Countdown Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: countdownColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: countdownColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (countdownColor == const Color(0xFFEF4444)) ...[
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  countdownLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: countdownColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Main Body (Event Details) ────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perihal,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Information Grid
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date & Time Box
                              Expanded(
                                flex: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_filled_rounded,
                                            size: 13,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "$timeStr WIB",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Venue Box
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 13,
                                            color: Colors.red[400],
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            "Lokasi",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tempat,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (picName != null && picName.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_pin_rounded,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Pengundang: ",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    picName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Perforated Dashed Line Divider ───────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: notchRadius + 4),
                      child: CustomPaint(
                        painter: _DashedLinePainter(
                          color: Colors.grey[300]!,
                          dashWidth: 4,
                          dashSpace: 3,
                        ),
                        size: const Size(double.infinity, 1),
                      ),
                    ),

                    // ── Bottom Tear-Off Stub (Barcode & Action) ──────────
                    Container(
                      height: notchFromBottom - 1, // minus divider thickness
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Realistic stylized barcode
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBarcodeGraphic(),
                              const SizedBox(width: 8),
                              Text(
                                ticketNo,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),

                          // Pill Action Link
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (totalCount > 1 && onPrev != null && currentIndex > 0)
                                InkWell(
                                  onTap: onPrev,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      size: 18,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Detail",
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 11,
                                      color: primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                              if (totalCount > 1 && onNext != null && currentIndex < totalCount - 1)
                                InkWell(
                                  onTap: onNext,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodeGraphic() {
    // Alternating thickness bars to look like a mini barcode
    final barWidths = [1.2, 2.2, 0.8, 1.8, 2.5, 0.8, 1.4, 2.0, 0.8, 1.5, 2.2];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: barWidths.map((w) {
        return Container(
          width: w,
          height: 14,
          margin: const EdgeInsets.only(right: 1.5),
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(0.5),
          ),
        );
      }).toList(),
    );
  }
}

/// Custom clipper that punches two semi-circular notches into the sides
class _TicketClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchFromBottom;

  _TicketClipper({
    required this.notchRadius,
    required this.notchFromBottom,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    const cornerRadius = 18.0;

    // Start from top-left after corner
    path.moveTo(cornerRadius, 0);

    // Top edge
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // Right edge down to notch
    final notchY = size.height - notchFromBottom;

    path.lineTo(size.width, notchY - notchRadius);
    // Right notch cutout (concave inward)
    path.arcToPoint(
      Offset(size.width, notchY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right edge down to bottom-right corner
    path.lineTo(size.width, size.height - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: const Radius.circular(cornerRadius),
    );

    // Bottom edge
    path.lineTo(cornerRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // Left edge up to notch
    path.lineTo(0, notchY + notchRadius);
    // Left notch cutout (concave inward)
    path.arcToPoint(
      Offset(0, notchY - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Left edge up to top-left corner
    path.lineTo(0, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// Custom painter for the perforated dashed line
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  _DashedLinePainter({
    required this.color,
    this.dashWidth = 4,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
