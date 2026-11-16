import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Model item memo di papan mading dengan karakteristik fisik alami
class MadingMemoItem {
  final String key;
  final String title;
  final int count;
  final Color pinColor;
  final Color paperColor;
  final Color inkColor; // Warna tinta pena / spidol yang meresap
  final IconData icon;
  final double rotation;
  final double pinXOffset;
  final int seed;

  const MadingMemoItem({
    required this.key,
    required this.title,
    required this.count,
    required this.pinColor,
    required this.paperColor,
    required this.inkColor,
    required this.icon,
    this.rotation = 0.0,
    this.pinXOffset = 42.0,
    this.seed = 0,
  });
}

/// Widget Papan Mading (Bulletin Board) bergaya Corkboard Realistis
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
    // Hanya tampilkan jika ada memo aktif (count > 0)
    if (memos.isEmpty) return const SizedBox.shrink();

    final totalAgenda = memos.fold<int>(0, (sum, m) => sum + m.count);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2D6C0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4E2E).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: CustomPaint(
          painter: _SubtleCorkPainter(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Mading Bergaya Plakat Kayu Tipis ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildHeaderPin(),
                        const SizedBox(width: 8),
                        Text(
                          "MADING AGENDA & TUGAS",
                          style: GoogleFonts.kalam(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5A3E22),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$totalAgenda Perlu Respon",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // ── Deretan Kertas Memo Sobekan Fisik Nyata ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: memos.map((memo) {
                    final isSelected = memo.key == selectedKey;
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _buildRealPhysicalMemo(memo, isSelected),
                    );
                  }).toList(),
                ),
              ),

              // ── Divider Serat Halus ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 1,
                  color: const Color(0xFFE2D6C0).withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 12),

              // ── Area Tiket Detail yang Dipilih ──
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: activeCard,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membuat kertas memo dengan tulisan tinta tangan menyatu & sobekan fisik
  Widget _buildRealPhysicalMemo(MadingMemoItem memo, bool isSelected) {
    const memoWidth = 92.0;
    const memoHeight = 98.0;
    final angle = isSelected ? memo.rotation * 0.25 : memo.rotation;
    final ink = memo.inkColor;

    return Transform.rotate(
      angle: angle,
      child: GestureDetector(
        onTap: () => onSelectMemo(memo.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: memoWidth,
          height: memoHeight,
          transform: isSelected
              ? Matrix4.translationValues(0, -4, 0)
              : Matrix4.identity(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Bayangan Melengkung Kertas (Paper Shadow) ──
              Positioned(
                top: 8,
                left: 3,
                right: 1,
                bottom: 2,
                child: Transform.rotate(
                  angle: 0.03,
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

              // ── Kertas Memo Sobekan Alami (Real Hand-Torn Edge) ──
              Positioned.fill(
                top: 6,
                child: ClipPath(
                  clipper: _RealTornPaperClipper(seed: memo.seed),
                  child: Container(
                    color: memo.paperColor,
                    child: Stack(
                      children: [
                        // Garis-garis samar buku catatan bergaris (Notebook ruled lines)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RuledNotepadPainter(),
                          ),
                        ),

                        // Serat kertas sobekan putih tipis di tepi bawah
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 4,
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),

                        // Konten Catatan Memo: Ikon & Teks Berpadu Tinta Asli
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Ikon bergaya cap stempel / coretan tinta menyatu ke kertas
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ink.withValues(alpha: 0.08),
                                ),
                                child: Icon(
                                  memo.icon,
                                  size: 19,
                                  color: ink.withValues(alpha: 0.88),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Teks bergaya tulisan tangan spidol / pulpen fisik nyata (GoogleFonts.kalam)
                              Text(
                                memo.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.kalam(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: ink.withValues(alpha: 0.90),
                                  height: 1.05,
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(
                                      color: ink.withValues(alpha: 0.18),
                                      offset: const Offset(0.3, 0.4),
                                      blurRadius: 0.5,
                                    ),
                                  ],
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

              // ── Badge Angka Alami (Red Paper Tag / Sticker) ──
              if (memo.count > 0)
                Positioned(
                  top: 2,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 2.5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      memo.count.toString(),
                      style: GoogleFonts.kalam(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

              // ── Pushpin 3D Menancap di Kertas ──
              Positioned(
                top: 0,
                left: memo.pinXOffset.clamp(14.0, memoWidth - 28.0),
                child: _buildRealPushPin(memo.pinColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membuat Pushpin 3D dengan sorot cahaya, bayangan di kertas, dan lubang jarum
  Widget _buildRealPushPin(Color color) {
    const double size = 15.0;

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bayangan pin yang jatuh ke kertas di arah kanan bawah
          Positioned(
            right: 1,
            bottom: 2,
            child: Container(
              width: size * 0.8,
              height: size * 0.45,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Lubang tancap jarum mikro (Pinhole)
          Positioned(
            bottom: 3,
            child: Container(
              width: 2.5,
              height: 2.5,
              decoration: const BoxDecoration(
                color: Color(0xFF334155),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Jarum pin logam perak kecil
          Positioned(
            bottom: 3.5,
            child: Container(
              width: 1.8,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),

          // Kepala pin bulat kubah 3D (Glossy dome pushpin)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.38),
                radius: 0.72,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  color,
                  Color.lerp(color, Colors.black, 0.5) ?? Colors.black,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPin() {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFDC2626),
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.7,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            const Color(0xFFDC2626),
            const Color(0xFF7F1D1D),
          ],
        ),
      ),
    );
  }
}

/// Clipper untuk menghasilkan Sobekan Kertas Tangan Alami (Deckle Edge / Hand-Torn Paper)
class _RealTornPaperClipper extends CustomClipper<Path> {
  final int seed;

  _RealTornPaperClipper({this.seed = 0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Sisi atas sedikit lengkungan kertas alami
    path.moveTo(0, 0);
    path.lineTo(w, 0);

    // Sisi kanan lurus sedikit bernafas
    path.lineTo(w, h - 7);

    // ── Tepi Bawah: Sobekan serat kertas bergelombang mikro halus ──
    const int segments = 14;
    final double dx = w / segments;

    for (int i = 0; i < segments; i++) {
      final double x1 = w - (i + 0.5) * dx;
      final double x2 = w - (i + 1.0) * dx;

      // Variasi kurva halus 1-3px (sobekan kertas nyata, bukan gergaji tajam)
      final double wave = math.sin((i + seed * 3) * 1.5) * 2.2 +
          math.cos((i * 2 + seed) * 1.2) * 1.2;

      final double y1 = h - 5 + wave;
      final double y2 = h - 5 - (wave * 0.4);

      path.quadraticBezierTo(x1, y1, x2, y2);
    }

    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _RealTornPaperClipper oldClipper) =>
      oldClipper.seed != seed;
}

/// Melukis garis catatan buku binder bergaris samar di kertas memo
class _RuledNotepadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    // Garis horizontal memo
    double y = 32.0;
    while (y < size.height - 12) {
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), linePaint);
      y += 14.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Melukis tekstur serat gabus alami papan mading
class _SubtleCorkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = const Color(0xFFD4C5AB).withValues(alpha: 0.20);
    final paintLight = Paint()..color = Colors.white.withValues(alpha: 0.25);

    final random = math.Random(101);
    const int totalDots = 70;

    for (int i = 0; i < totalDots; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.5 + random.nextDouble() * 1.2;

      canvas.drawCircle(Offset(x, y), r, (i % 2 == 0) ? paintDark : paintLight);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
