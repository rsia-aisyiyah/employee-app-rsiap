import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Model item memo di papan mading dengan karakteristik fisik acak
class MadingMemoItem {
  final String key;
  final String title;
  final int count;
  final Color pinColor;
  final Color paperColor;
  final Color accentColor;
  final IconData icon;
  final double rotation; // Sudut kemiringan kertas memo
  final double pinXOffset; // Posisi tancapan pin horizontal (acak)
  final int tearVariant; // Variasi pola sobekan kertas

  const MadingMemoItem({
    required this.key,
    required this.title,
    required this.count,
    required this.pinColor,
    required this.paperColor,
    required this.accentColor,
    required this.icon,
    this.rotation = 0.0,
    this.pinXOffset = 42.0,
    this.tearVariant = 0,
  });
}

/// Widget Papan Mading (Bulletin Board) bergaya Corkboard Realistis dengan kertas sobekan & pin acak
class CardMadingBoard extends StatelessWidget {
  final List<MadingMemoItem> memos;
  final String selectedKey;
  final ValueChanged<String> onSelectMemo;
  final Widget activeCard;

  const CardMadingBoard({
    super.key,
    required this.memos,
    required this.selectedKey,
    required this.onSelectMemo,
    required this.activeCard,
  });

  @override
  Widget build(BuildContext context) {
    if (memos.isEmpty) return const SizedBox.shrink();

    final totalAgenda = memos.fold<int>(0, (sum, m) => sum + m.count);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        // Nuansa gabus hangat dengan bingkai kayu lembut
        color: const Color(0xFFF7F2E7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDFD1B8), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A542C).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _CorkboardTexturePainter(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Papan Mading Kayu Realistis ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Plakat Kayu / Craft Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE5D2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD3C2A3), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B4E2E).withValues(alpha: 0.10),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMiniPin(const Color(0xFFEF4444)),
                          const SizedBox(width: 7),
                          const Text(
                            "MADING TUGAS & AGENDA",
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5E4226),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Counter Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: totalAgenda > 0
                            ? const Color(0xFFEF4444).withValues(alpha: 0.14)
                            : const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: totalAgenda > 0
                              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                              : const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        totalAgenda > 0 ? "$totalAgenda Perlu Respon" : "Semua Beres ✓",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: totalAgenda > 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // ── Deretan Memo Kertas Sobekan Tak Beraturan (Pinned Memos) ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: memos.map((memo) {
                    final isSelected = memo.key == selectedKey;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildRealTornStickyNote(memo, isSelected),
                    );
                  }).toList(),
                ),
              ),

              // ── Divider Tali / Serat Papan ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFD8C7A9).withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Kartu Tiket Aktif di Bawah Papan (dengan Pin Penancap di Atasnya) ──
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: activeCard,
                    ),

                    // Jarum Pin 3D Penancap di Atas Tiket Aktif (Realistis ala Mading)
                    Positioned(
                      top: -6,
                      child: _build3dPushPin(
                        _getActivePinColor(),
                        size: 16,
                        angle: -0.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActivePinColor() {
    final active = memos.firstWhere(
      (m) => m.key == selectedKey,
      orElse: () => memos.first,
    );
    return active.pinColor;
  }

  /// Membuat kertas sticky note dengan SOBEKAN TAK BERATURAN (Torn Paper Edge) dan pin acak
  Widget _buildRealTornStickyNote(MadingMemoItem memo, bool isSelected) {
    const cardWidth = 86.0;
    const cardHeight = 92.0;

    // Sudut rotasi: saat dipilih sedikit lebih tegak tapi tetap berkarakter
    final currentAngle = isSelected ? memo.rotation * 0.3 : memo.rotation;

    return Transform.rotate(
      angle: currentAngle,
      child: GestureDetector(
        onTap: () => onSelectMemo(memo.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: cardWidth,
          height: cardHeight,
          transform: isSelected
              ? Matrix4.translationValues(0, -5, 0)
              : Matrix4.identity(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Bayangan Jatuh Kertas (Asymmetrical Paper Shadow) ──
              Positioned(
                top: 8,
                left: 2,
                right: 2,
                bottom: 2,
                child: Transform.rotate(
                  angle: 0.02,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: isSelected ? 0.16 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              // ── Lapisan Serat Sobekan Putih Belakang (Paper Fiber Backing) ──
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipPath(
                  clipper: _TornPaperClipper(variant: memo.tearVariant, offsetY: 2.0),
                  child: Container(
                    color: const Color(0xFFF1EFEA), // Serat kertas sobekan
                  ),
                ),
              ),

              // ── Kertas Utama Sobekan (Torn Paper Note Body) ──
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                bottom: 2,
                child: ClipPath(
                  clipper: _TornPaperClipper(variant: memo.tearVariant),
                  child: Container(
                    decoration: BoxDecoration(
                      color: memo.paperColor,
                      border: Border.all(
                        color: isSelected ? memo.accentColor : const Color(0xFFE5D8BE),
                        width: isSelected ? 1.6 : 0.8,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Garis-garis halus kertas binder/memo (Notebook lines)
                        CustomPaint(
                          size: const Size(cardWidth, cardHeight),
                          painter: _NotepadLinesPainter(
                            lineColor: Colors.black.withValues(alpha: 0.04),
                          ),
                        ),

                        // Konten Memo (Icon + Judul)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                memo.icon,
                                size: 21,
                                color: memo.accentColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                memo.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  color: const Color(0xFF2D3748),
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Badge Counter Jumlah di Sudut Kanan Atas Kertas ──
              if (memo.count > 0)
                Positioned(
                  top: 2,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                    decoration: BoxDecoration(
                      color: memo.accentColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 3,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Text(
                      memo.count.toString(),
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // ── Jarum Pin 3D yang Menancap Acak di Kertas ──
              Positioned(
                top: 0,
                left: memo.pinXOffset.clamp(14.0, cardWidth - 28.0),
                child: _build3dPushPin(
                  memo.pinColor,
                  size: 15,
                  angle: (memo.pinXOffset % 2 == 0) ? -0.2 : 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pushpin 3D dengan refleksi cahaya, bayangan miring, dan jarum logam perak
  Widget _build3dPushPin(Color color, {double size = 14, double angle = 0.0}) {
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: size + 6,
        height: size + 6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Bayangan pin yang jatuh ke permukaan kertas miring
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: size * 0.85,
                height: size * 0.45,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Ujung jarum perak kecil yang menusuk
            Positioned(
              bottom: 2,
              child: Container(
                width: 2.2,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),

            // Kepala pin bulat jamur 3D mengilap (Glossy dome)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.38),
                  radius: 0.75,
                  colors: [
                    Colors.white.withValues(alpha: 0.85),
                    color,
                    Color.lerp(color, Colors.black, 0.55) ?? Colors.black,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPin(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.7,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            color,
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
      ),
    );
  }
}

/// Clipper untuk menghasilkan Sobekan Kertas Tak Beraturan (Real Torn Paper Edge)
class _TornPaperClipper extends CustomClipper<Path> {
  final int variant;
  final double offsetY;

  _TornPaperClipper({this.variant = 0, this.offsetY = 0.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height + offsetY;

    // Mulai dari kiri atas (sedikit tidak lurus penggaris agar organik)
    path.moveTo(0, 2);
    path.quadraticBezierTo(w * 0.5, 0, w, 2); // Garis atas melengkung mikro
    path.lineTo(w, h - 12);

    // ── Tepi Bawah: Gerigi Sobekan Kertas Organik Tak Beraturan ──
    final List<double> ripDeltas;
    switch (variant % 4) {
      case 0:
        ripDeltas = [2, -6, 5, -8, 3, -11, 4, -7, 6, -10, 2, -6, 0];
        break;
      case 1:
        ripDeltas = [4, -9, 3, -5, 7, -12, 2, -8, 5, -6, 4, -10, 0];
        break;
      case 2:
        ripDeltas = [1, -5, 6, -11, 2, -7, 8, -13, 3, -6, 5, -8, 0];
        break;
      default:
        ripDeltas = [3, -8, 4, -12, 6, -6, 2, -10, 5, -7, 3, -11, 0];
    }

    final int steps = ripDeltas.length;
    final double stepWidth = w / steps;

    for (int i = 0; i < steps; i++) {
      final double targetX = w - ((i + 1) * stepWidth);
      final double targetY = h - 6 + ripDeltas[i];
      path.lineTo(targetX.clamp(0.0, w), targetY);
    }

    path.lineTo(0, 2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TornPaperClipper oldClipper) {
    return oldClipper.variant != variant || oldClipper.offsetY != offsetY;
  }
}

/// Melukis garis catatan buku binder halus di permukaan kertas memo
class _NotepadLinesPainter extends CustomPainter {
  final Color lineColor;

  _NotepadLinesPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;

    double y = 28.0;
    while (y < size.height - 15) {
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), paint);
      y += 13.0;
    }
  }

  @override
  bool shouldRepaint(covariant _NotepadLinesPainter oldDelegate) => false;
}

/// Melukis bintik-bintik serat alami papan gabus (Corkboard speckled grain)
class _CorkboardTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = const Color(0xFFC7B596).withValues(alpha: 0.22);
    final paintLight = Paint()..color = Colors.white.withValues(alpha: 0.25);

    final random = math.Random(42); // Seed konstan agar tidak flicker
    const int totalDots = 90;

    for (int i = 0; i < totalDots; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.6 + random.nextDouble() * 1.4;

      canvas.drawCircle(Offset(x, y), r, (i % 2 == 0) ? paintDark : paintLight);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
