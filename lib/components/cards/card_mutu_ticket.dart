import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/models/inmut_model.dart';
import 'package:rsia_employee_app/screen/menu/mutu/mutu_unit_screen.dart';

/// A sleek Mini Ticket Strip (~88px) for Indikator Mutu & Validasi
/// matching the exact aesthetic of CardTindakLanjutTicket.
class CardMutuTicket extends StatefulWidget {
  final List<InmutUnitItem> items;
  final VoidCallback? onRefresh;

  const CardMutuTicket({
    super.key,
    required this.items,
    this.onRefresh,
  });

  @override
  State<CardMutuTicket> createState() => _CardMutuTicketState();
}

class _CardMutuTicketState extends State<CardMutuTicket> {
  int _currentIndex = 0;
  int _slideDirection = 1;
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

    if (total <= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildTicketCard(
          unit: activeData,
          cardHeight: cardHeight,
          stubWidth: stubWidth,
          notchRadius: notchRadius,
          currentIndex: 0,
          totalCount: 1,
        ),
      );
    }

    const stackHeight = cardHeight + 8.0;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
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
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            height: cardHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _dragDistance = 0,
              onHorizontalDragUpdate: (details) => _dragDistance += details.delta.dx,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -100 || _dragDistance < -35) {
                  _goToNext(total);
                } else if (velocity > 100 || _dragDistance > 35) {
                  _goToPrev(total);
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
                  unit: activeData,
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

  Widget _buildDummyStackedTicket({
    required double stubWidth,
    required double notchRadius,
    required double opacity,
    required Color borderColor,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
            color: Colors.white,
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.0),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard({
    Key? key,
    required InmutUnitItem unit,
    required double cardHeight,
    required double stubWidth,
    required double notchRadius,
    required int currentIndex,
    required int totalCount,
  }) {
    final status = unit.submissionStatus;
    Color accentColor;
    Color lightBg;
    String badgeText;
    String stubText;

    if (status == 'revision') {
      accentColor = const Color(0xFFEF4444);
      lightBg = const Color(0xFFFEF2F2);
      badgeText = 'PERLU REVISI';
      stubText = 'REVISI';
    } else if (unit.isValidator && unit.pendingIndicators > 0 && unit.pendingAnalyses > 0) {
      accentColor = const Color(0xFFF59E0B);
      lightBg = const Color(0xFFFFFBEB);
      badgeText = 'VALIDASI & ANALISA';
      stubText = 'MUTU';
    } else if (unit.isValidator && unit.pendingIndicators > 0) {
      accentColor = const Color(0xFFF59E0B);
      lightBg = const Color(0xFFFFFBEB);
      badgeText = 'BUTUH VALIDASI';
      stubText = 'VALIDASI';
    } else if (unit.isValidator && unit.pendingAnalyses > 0) {
      accentColor = const Color(0xFF8B5CF6);
      lightBg = const Color(0xFFF5F3FF);
      badgeText = 'BUTUH ANALISA';
      stubText = 'ANALISA';
    } else if (status == 'requested') {
      accentColor = const Color(0xFFF59E0B);
      lightBg = const Color(0xFFFFFBEB);
      badgeText = 'BUTUH VALIDASI';
      stubText = 'VALIDASI';
    } else {
      accentColor = const Color(0xFF2563EB);
      lightBg = const Color(0xFFEFF6FF);
      badgeText = 'PENGUMPULAN DATA';
      stubText = 'MUTU';
    }

    final double pct = unit.totalIndicators > 0
        ? (unit.verifiedIndicators / unit.totalIndicators).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      key: key,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MutuUnitScreen()),
              ).then((_) => widget.onRefresh?.call());
            },
            child: Row(
              children: [
                // ── Left Stub (Gauge / Badge) ──
                Container(
                  width: stubWidth,
                  height: cardHeight,
                  color: lightBg,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: status == 'revision' ? 1.0 : pct,
                              strokeWidth: 3.5,
                              backgroundColor: accentColor.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                            Text(
                              status == 'revision'
                                  ? '!'
                                  : '${unit.verifiedIndicators}/${unit.totalIndicators}',
                              style: TextStyle(
                                fontSize: status == 'revision' ? 16 : 10.5,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stubText,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Perforation Divider ──
                CustomPaint(
                  size: Size(1, cardHeight),
                  painter: _DashedLinePainter(
                    color: Colors.grey.shade300,
                    dashHeight: 3,
                    dashGap: 3,
                  ),
                ),

                // ── Right Main Ticket Content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Line: Badge + Carousel Pager
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '• $badgeText',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (totalCount > 1) ...[
                              GestureDetector(
                                onTap: () => _goToPrev(totalCount),
                                child: Icon(Icons.chevron_left_rounded, size: 14, color: Colors.grey.shade500),
                              ),
                              Text(
                                '${currentIndex + 1}/$totalCount',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                              ),
                              GestureDetector(
                                onTap: () => _goToNext(totalCount),
                                child: Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey.shade500),
                              ),
                            ],
                          ],
                        ),

                        // Title
                        Text(
                          unit.namaRuang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),

                        // Subtitle
                        Text(
                          status == 'revision'
                              ? (unit.revisionNote ?? 'Perlu perbaikan data entri.')
                              : (unit.isValidator && unit.pendingIndicators > 0 && unit.pendingAnalyses > 0)
                                  ? '${unit.pendingIndicators} belum validasi • ${unit.pendingAnalyses} belum analisa.'
                                  : (unit.isValidator && unit.pendingIndicators > 0)
                                      ? '${unit.pendingIndicators} dari ${unit.totalIndicators} indikator menunggu validasi.'
                                      : (unit.isValidator && unit.pendingAnalyses > 0)
                                          ? '${unit.pendingAnalyses} dari ${unit.totalIndicators} indikator menunggu analisa.'
                                          : status == 'requested'
                                              ? 'Diajukan oleh ${unit.namaPic ?? 'PIC'}. Menunggu validasi P2.'
                                              : '${unit.filledIndicators} dari ${unit.totalIndicators} indikator telah terisi.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        // Bottom Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              unit.isValidator ? 'Peran: Validator' : 'Peran: PIC Unit',
                              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    unit.isValidator ? 'Validasi' : 'Kelola',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_rounded, size: 10, color: accentColor),
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
    final cutX = stubWidth;

    path.moveTo(r, 0);
    path.lineTo(cutX - nr, 0);
    path.arcToPoint(
      Offset(cutX + nr, 0),
      radius: Radius.circular(nr),
      clockwise: false,
    );
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));

    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));

    path.lineTo(cutX + nr, h);
    path.arcToPoint(
      Offset(cutX - nr, h),
      radius: Radius.circular(nr),
      clockwise: false,
    );
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));

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

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashGap;

  _DashedLinePainter({
    required this.color,
    this.dashHeight = 3,
    this.dashGap = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double y = 8;
    while (y < size.height - 8) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
