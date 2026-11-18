import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/screen/menu/helpdesk_main.dart';

/// A sleek, space-efficient Mini Ticket Strip (~88px) for Unclosed Helpdesk Tickets
/// with a 3D Stacked Card Deck Carousel, Priority Badge, and Ticket Notches.
class CardHelpdeskTicket extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback? onRefresh;

  const CardHelpdeskTicket({
    super.key,
    required this.items,
    this.onRefresh,
  });

  @override
  State<CardHelpdeskTicket> createState() => _CardHelpdeskTicketState();
}

class _CardHelpdeskTicketState extends State<CardHelpdeskTicket> {
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
                backgroundColor: const Color(0xFFFEE2E2).withValues(alpha: 0.35),
                borderColor: const Color(0xFFFECACA),
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
                backgroundColor: const Color(0xFFFEF2F2),
                borderColor: const Color(0xFFFCA5A5).withValues(alpha: 0.6),
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
                _dragDistance += details.primaryDelta ?? 0;
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (_dragDistance < -35 || velocity < -200) {
                  _goToNext(total);
                } else if (_dragDistance > 35 || velocity > 200) {
                  _goToPrev(total);
                }
                _dragDistance = 0;
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final inFrom = Offset(_slideDirection * 0.18, 0.0);
                  final outTo = Offset(-_slideDirection * 0.18, 0.0);

                  final slideIn = Tween<Offset>(
                    begin: inFrom,
                    end: Offset.zero,
                  ).animate(animation);

                  final slideOut = Tween<Offset>(
                    begin: Offset.zero,
                    end: outTo,
                  ).animate(animation);

                  final isIncoming = (child.key as ValueKey?)?.value == safeIndex;

                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                    ),
                    child: SlideTransition(
                      position: isIncoming ? slideIn : slideOut,
                      child: child,
                    ),
                  );
                },
                child: _buildTicketCard(
                  key: ValueKey<int>(safeIndex),
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
    final status = (data['status'] ?? 'Open').toString().trim();
    final prioritas = (data['prioritas'] ?? 'Medium').toString().trim();
    final noTiket = (data['no_tiket'] ?? '-').toString().trim();
    final keluhan = (data['keluhan'] ?? 'Tidak ada deskripsi keluhan').toString().trim();

    // Pelapor & Unit
    String reporterName = '-';
    if (data['pelapor'] != null && data['pelapor']['nama'] != null) {
      reporterName = data['pelapor']['nama'].toString();
    } else if (data['nik_pelapor'] != null) {
      reporterName = data['nik_pelapor'].toString();
    }

    String deptName = '';
    if (data['departemen'] != null && data['departemen']['nama'] != null) {
      deptName = data['departemen']['nama'].toString();
    }

    // Color theme based on priority & status
    Color priorityColor = const Color(0xFFF59E0B); // Amber for Medium
    if (prioritas.toLowerCase() == 'high') {
      priorityColor = const Color(0xFFEF4444); // Red
    } else if (prioritas.toLowerCase() == 'low') {
      priorityColor = const Color(0xFF0EA5E9); // Blue
    }

    final isProses = status.toLowerCase() == 'proses';
    final Color statusColor = isProses ? const Color(0xFF2563EB) : const Color(0xFFDC2626);
    final Color statusBg = isProses ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2);
    final Color statusBorder = isProses ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA);

    // Format tanggal
    String dateStr = '';
    if (data['tanggal'] != null) {
      try {
        final parsed = DateTime.parse(data['tanggal'].toString());
        dateStr = DateFormat('dd MMM', 'id_ID').format(parsed);
      } catch (_) {
        dateStr = '';
      }
    }

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
                  builder: (context) => const HelpdeskMainScreen(),
                ),
              );
              if (widget.onRefresh != null) {
                widget.onRefresh!();
              }
            },
            child: Row(
              children: [
                // ── LEFT STUB: Priority & Helpdesk Icon ──────────────────────
                Container(
                  width: stubWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        priorityColor.withValues(alpha: 0.16),
                        priorityColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.support_agent_rounded,
                          size: 22,
                          color: priorityColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prioritas.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: priorityColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── SEPARATOR DASHED LINE ───────────────────────────────────
                CustomPaint(
                  size: Size(1, cardHeight),
                  painter: _DashedLinePainter(
                    color: const Color(0xFFE2E8F0),
                    notchRadius: notchRadius,
                  ),
                ),

                // ── RIGHT BODY: Info Tiket & Keluhan ─────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 8,
                      bottom: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Status Pill + No Tiket + Tanggal / Counter
                        Row(
                          children: [
                            // Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: statusBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4.5,
                                    height: 4.5,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // No. Tiket
                            Expanded(
                              child: Text(
                                noTiket,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            // Counter (e.g. 1/4) if multiple
                            if (totalCount > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${currentIndex + 1}/$totalCount",
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Row 2: Keluhan
                        Text(
                          keluhan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.15,
                            letterSpacing: -0.2,
                          ),
                        ),

                        // Row 3: Pelapor & Link Kelola
                        Row(
                          children: [
                            const Icon(
                              Icons.person_pin_circle_outlined,
                              size: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                deptName.isNotEmpty
                                    ? "$reporterName • $deptName"
                                    : (dateStr.isNotEmpty ? "$reporterName • $dateStr" : reporterName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Kelola",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 10.5,
                                    color: Color(0xFF0284C7),
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

/// Custom Clipper that punches semi-circular ticket notches at the vertical stub division line
class _MiniTicketClipper extends CustomClipper<Path> {
  final double stubWidth;
  final double notchRadius;
  final double cornerRadius;

  _MiniTicketClipper({
    required this.stubWidth,
    required this.notchRadius,
    this.cornerRadius = 16.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final nr = notchRadius;
    final x = stubWidth;

    // Start at top-left corner
    path.moveTo(r, 0);

    // Top edge to top notch
    path.lineTo(x - nr, 0);
    path.arcToPoint(
      Offset(x + nr, 0),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Top edge to top-right corner
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));

    // Right edge to bottom-right corner
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));

    // Bottom edge to bottom notch
    path.lineTo(x + nr, h);
    path.arcToPoint(
      Offset(x - nr, h),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Bottom edge to bottom-left corner
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));

    // Left edge to top-left corner
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _MiniTicketClipper oldClipper) {
    return oldClipper.stubWidth != stubWidth ||
        oldClipper.notchRadius != notchRadius ||
        oldClipper.cornerRadius != cornerRadius;
  }
}

/// Custom Painter for drawing the dashed perforation line between notches
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double notchRadius;

  _DashedLinePainter({
    required this.color,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashHeight = 3.5;
    const dashSpace = 2.5;

    final startY = notchRadius + 4;
    final endY = size.height - notchRadius - 4;

    double currentY = startY;
    while (currentY < endY) {
      canvas.drawLine(
        Offset(0, currentY),
        Offset(0, (currentY + dashHeight).clamp(startY, endY)),
        paint,
      );
      currentY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.notchRadius != notchRadius;
  }
}
