import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/undangan.dart';

/// A sleek, space-efficient Mini Ticket Strip (~85px)
/// with a 3D Stacked Card Deck Carousel for multiple invitations.
class CardUndanganTicket extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? data;

  // Optional legacy props
  final int totalCount;
  final int currentIndex;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  const CardUndanganTicket({
    super.key,
    this.items = const [],
    this.data,
    this.totalCount = 1,
    this.currentIndex = 0,
    this.onNext,
    this.onPrev,
  });

  @override
  State<CardUndanganTicket> createState() => _CardUndanganTicketState();
}

class _CardUndanganTicketState extends State<CardUndanganTicket> {
  int _currentIndex = 0;
  int _slideDirection = 1; // 1 for next (from right), -1 for prev (from left)

  List<Map<String, dynamic>> get _list {
    if (widget.items.isNotEmpty) return widget.items;
    if (widget.data != null) return [widget.data!];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant CardUndanganTicket oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      setState(() {
        _currentIndex = widget.currentIndex;
      });
    }
  }

  void _goToNext() {
    if (widget.onNext != null) {
      widget.onNext!();
      return;
    }
    final len = _list.length;
    if (len <= 1) return;
    setState(() {
      _slideDirection = 1;
      _currentIndex = (_currentIndex + 1) % len;
    });
  }

  void _goToPrev() {
    if (widget.onPrev != null) {
      widget.onPrev!();
      return;
    }
    final len = _list.length;
    if (len <= 1) return;
    setState(() {
      _slideDirection = -1;
      _currentIndex = (_currentIndex - 1 + len) % len;
    });
  }

  DateTime? _getEventDate(Map<String, dynamic> data) {
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
    final list = _list;
    if (list.isEmpty) return const SizedBox.shrink();

    final safeIndex = _currentIndex.clamp(0, list.length - 1);
    final activeData = list[safeIndex];
    final total = list.length;

    const cardHeight = 86.0;
    const stubWidth = 80.0;
    const notchRadius = 6.0;

    // Single item: render clean single ticket without stack layers
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

    // Multiple items: Stacked Card Deck effect!
    const stackHeight = cardHeight + 8.0;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Layer 3: Deepest card peek (if >= 3 items) ──────────────────
          if (total >= 3)
            Positioned(
              top: 8,
              left: 28,
              right: 28,
              height: cardHeight,
              child: _buildDummyStackedTicket(
                stubWidth: stubWidth,
                notchRadius: notchRadius,
                opacity: 0.45,
                borderColor: primaryColor.withValues(alpha: 0.15),
              ),
            ),

          // ── Layer 2: Middle card peek (if >= 2 items) ───────────────────
          Positioned(
            top: 4,
            left: 24,
            right: 24,
            height: cardHeight,
            child: _buildDummyStackedTicket(
              stubWidth: stubWidth,
              notchRadius: notchRadius,
              opacity: 0.75,
              borderColor: primaryColor.withValues(alpha: 0.25),
            ),
          ),

          // ── Layer 1: Active Front Ticket ───────────────────────────────
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            height: cardHeight,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -100) {
                    _goToNext(); // Swipe left -> Next
                  } else if (details.primaryVelocity! > 100) {
                    _goToPrev(); // Swipe right -> Prev
                  }
                }
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

  /// Builds the background dummy ticket for the stacked layers behind
  Widget _buildDummyStackedTicket({
    required double stubWidth,
    required double notchRadius,
    required double opacity,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03 * opacity),
            blurRadius: 6,
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            border: Border.all(color: borderColor, width: 0.8),
          ),
        ),
      ),
    );
  }

  /// The interactive ticket card widget
  Widget _buildTicketCard({
    Key? key,
    required Map<String, dynamic> data,
    required double cardHeight,
    required double stubWidth,
    required double notchRadius,
    required int currentIndex,
    required int totalCount,
  }) {
    final eventDate = _getEventDate(data) ?? DateTime.now();
    final perihal = data['perihal']?.toString() ?? "Rapat / Kegiatan Internal";
    final tempat = (data['lokasi'] ?? data['tempat'] ?? "-").toString();

    final countdownLabel = _getCountdownLabel(eventDate);
    final countdownColor = _getCountdownColor(eventDate);
    final dayStr = DateFormat("dd", "id_ID").format(eventDate);
    final monthStr = DateFormat("MMM", "id_ID").format(eventDate).toUpperCase();
    final timeStr = DateFormat("HH:mm", "id_ID").format(eventDate);
    final ticketNo = "INV-${(data['id'] ?? data['surat_id'] ?? '000').toString().padLeft(4, '0')}";

    return Container(
      key: key,
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
            child: Row(
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
                                    InkWell(
                                      onTap: _goToPrev,
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(
                                          Icons.chevron_left_rounded,
                                          size: 13,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "${currentIndex + 1}/$totalCount",
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _goToNext,
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          size: 13,
                                          color: Color(0xFF475569),
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
