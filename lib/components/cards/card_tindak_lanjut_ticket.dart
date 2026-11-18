import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/models/tindak_lanjut_model.dart';
import 'package:rsia_employee_app/screen/menu/tindak_lanjut/tindak_lanjut_detail_screen.dart';
import 'package:rsia_employee_app/screen/menu/tindak_lanjut/tindak_lanjut_screen.dart';

/// A sleek, space-efficient Mini Ticket Strip (~88px) for Tindak Lanjut Rapat
/// with a 3D Stacked Card Deck Carousel, Circular Progress Gauge, and Ticket Notches.
class CardTindakLanjutTicket extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback? onRefresh;

  const CardTindakLanjutTicket({
    super.key,
    required this.items,
    this.onRefresh,
  });

  @override
  State<CardTindakLanjutTicket> createState() => _CardTindakLanjutTicketState();
}

class _CardTindakLanjutTicketState extends State<CardTindakLanjutTicket> {
  int _currentIndex = 0;
  int _slideDirection = 1; // 1 for next (from right), -1 for prev (from left)
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final total = widget.items.length;
    final safeIndex = _currentIndex.clamp(0, total - 1);
    final activeData = widget.items[safeIndex];

    const cardHeight = 88.0;
    const stubWidth = 76.0;
    const notchRadius = 6.5;

    // Single item: direct ticket
    if (total <= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildTicketCard(
          data: activeData,
          cardHeight: cardHeight,
          stubWidth: stubWidth,
          notchRadius: notchRadius,
          currentIndex: 0,
          totalCount: 1,
        ),
      );
    }

    final double frontRight = total >= 3 ? 32.0 : (total == 2 ? 26.0 : 20.0);

    return SizedBox(
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Layer 3: Kertas lembar ke-3 (paling belakang) ──
          if (total >= 3)
            Positioned(
              top: 0,
              bottom: 0,
              left: 20,
              right: 12,
              child: _buildDummyStackedTicket(
                backgroundColor: const Color(0xFFF1F5F9),
                borderColor: const Color(0xFFCBD5E1),
                shadowAlpha: 0.04,
              ),
            ),

          // ── Layer 2: Kertas lembar ke-2 (tengah) ──
          if (total >= 2)
            Positioned(
              top: 0,
              bottom: 0,
              left: 20,
              right: total >= 3 ? 22 : 16,
              child: _buildDummyStackedTicket(
                backgroundColor: const Color(0xFFF8FAFC),
                borderColor: const Color(0xFFE2E8F0),
                shadowAlpha: 0.05,
              ),
            ),

          // ── Layer 1: Active Front Ticket ───────────────────────────────
          Positioned(
            top: 0,
            bottom: 0,
            left: 20,
            right: frontRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                _dragDistance = 0;
              },
              onHorizontalDragUpdate: (details) {
                _dragDistance += details.delta.dx;
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -100 || _dragDistance < -35) {
                  _goToNext(total); // Swipe left -> Next
                } else if (velocity > 100 || _dragDistance > 35) {
                  _goToPrev(total); // Swipe right -> Prev
                }
                _dragDistance = 0;
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(_slideDirection * 0.12, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildTicketCard(
                  key: ValueKey(safeIndex),
                  data: activeData,
                  cardHeight: cardHeight,
                  stubWidth: stubWidth,
                  notchRadius: notchRadius,
                  currentIndex: safeIndex,
                  totalCount: total,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNext(int total) {
    if (total <= 1) return;
    setState(() {
      _slideDirection = 1;
      _currentIndex = (_currentIndex + 1) % total;
    });
  }

  void _goToPrev(int total) {
    if (total <= 1) return;
    setState(() {
      _slideDirection = -1;
      _currentIndex = (_currentIndex - 1 + total) % total;
    });
  }

  /// Builds the background dummy ticket for the stacked layers behind
  Widget _buildDummyStackedTicket({
    required Color backgroundColor,
    required Color borderColor,
    required double shadowAlpha,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha),
            blurRadius: 5,
            offset: const Offset(2.5, 1),
          ),
        ],
      ),
    );
  }

  /// The active ticket card
  Widget _buildTicketCard({
    Key? key,
    required Map<String, dynamic> data,
    required double cardHeight,
    required double stubWidth,
    required double notchRadius,
    required int currentIndex,
    required int totalCount,
  }) {
    final item = TindakLanjutItem.fromJson(data);
    final pct = item.progressPercent.clamp(0, 100);
    final deadline = item.deadlineDate;
    final isOverdue = item.isOverdue;

    Color themeColor = primaryColor;
    if (pct == 100 || item.status == 'selesai') {
      themeColor = const Color(0xFF10B981); // Emerald Green
    } else if (isOverdue) {
      themeColor = const Color(0xFFEF4444); // Red
    } else if (pct == 0 || item.status == 'pending') {
      themeColor = const Color(0xFFF59E0B); // Amber
    }

    final countdownLabel = _getCountdownLabel(deadline, isOverdue);
    final ticketNo = "RTL-${item.id.toString().padLeft(4, '0')}";

    return Container(
      key: key,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 7,
            offset: const Offset(3, 1),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 2),
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TindakLanjutDetailScreen(
                    id: item.id,
                    initialItem: item,
                  ),
                ),
              );
              if (widget.onRefresh != null) {
                widget.onRefresh!();
              }
            },
            child: Row(
              children: [
                // ── LEFT STUB: Circular Progress Ring Gauge ─────────────────
                Container(
                  width: stubWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeColor.withValues(alpha: 0.15),
                        themeColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Radial Progress Ring
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: pct / 100.0,
                              strokeWidth: 3.5,
                              backgroundColor: themeColor.withValues(alpha: 0.18),
                              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                              strokeCap: StrokeCap.round,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(7.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$pct',
                                      style: TextStyle(
                                        fontSize: pct >= 100 ? 12 : 14,
                                        fontWeight: FontWeight.w900,
                                        color: themeColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      '%',
                                      style: TextStyle(
                                        fontSize: pct >= 100 ? 7.5 : 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: themeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isOverdue
                            ? 'OVERDUE'
                            : (pct == 100 ? 'SELESAI' : 'PROGRES'),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── VERTICAL PERFORATION ────────────────────────────
                CustomPaint(
                  painter: _VerticalDashedLinePainter(
                    color: Colors.grey.shade300,
                    notchRadius: notchRadius,
                    dashHeight: 3.5,
                    dashSpace: 3.0,
                  ),
                  size: Size(1, cardHeight),
                ),

                // ── RIGHT SECTION: Details & Action ─────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Bar: Status Chip & Pager / Ticket ID
                        Row(
                          children: [
                            // Status / Countdown Badge
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: themeColor.withValues(alpha: 0.25),
                                    width: 0.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: themeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 3.5),
                                    Flexible(
                                      child: Text(
                                        countdownLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: themeColor,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Pagination with mini chevrons if multi-item, else Ticket ID
                            if (totalCount > 1) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _goToPrev(totalCount),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(
                                          Icons.chevron_left,
                                          size: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${currentIndex + 1}/$totalCount',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _goToNext(totalCount),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(
                                          Icons.chevron_right,
                                          size: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Text(
                                ticketNo,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Title & Task description snippet
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.perihalRapat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              item.cleanDeskripsi,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),

                        // Bottom Row: Target date & Action pill button
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 10.5,
                              color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 3.5),
                            Expanded(
                              child: Text(
                                deadline != null
                                    ? DateFormat("dd MMM yyyy", "id_ID").format(deadline)
                                    : "Tanpa tenggat",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                ),
                              ),
                            ),

                            // Action button "Kelola →" / "Semua"
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TindakLanjutScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Kelola",
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 10,
                                      color: primaryColor,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCountdownLabel(DateTime? deadline, bool isOverdue) {
    if (isOverdue) return "TERLAMBAT";
    if (deadline == null) return "RTL RAPAT";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(deadline.year, deadline.month, deadline.day);
    final diffDays = eventDay.difference(today).inDays;

    if (diffDays == 0) {
      return "TARGET HARI INI";
    } else if (diffDays == 1) {
      return "TARGET BESOK";
    } else if (diffDays > 1) {
      return "$diffDays HARI LAGI";
    } else {
      return "TERLAMBAT";
    }
  }
}

/// Custom Clipper for the mini ticket with inward notches
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

    // Top notch cutout
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

    // Bottom notch cutout
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
