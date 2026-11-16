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

              const SizedBox(height: 6),

              // ── Deretan Kertas Memo Sobekan Fisik Nyata (Grid Compact 1 atau 2 Baris) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: _buildMemosGrid(),
              ),

              // ── Divider Serat Halus ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 1,
                  color: const Color(0xFFE2D6C0).withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 10),

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

  /// Membangun grid memo tanpa scroll horizontal (maksimal 2 baris)
  Widget _buildMemosGrid() {
    if (memos.isEmpty) return const SizedBox.shrink();

    // Jika 1 s.d. 3 item: Cukup 1 baris
    if (memos.length <= 3) {
      return Row(
        children: memos.map((memo) {
          final isSelected = memo.key == selectedKey;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.5),
              child: _buildRealPhysicalMemo(memo, isSelected),
            ),
          );
        }).toList(),
      );
    }

    // Jika 4 item: 2 baris x 2 kolom
    if (memos.length == 4) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  child: _buildRealPhysicalMemo(memos[0], memos[0].key == selectedKey),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  child: _buildRealPhysicalMemo(memos[1], memos[1].key == selectedKey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  child: _buildRealPhysicalMemo(memos[2], memos[2].key == selectedKey),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  child: _buildRealPhysicalMemo(memos[3], memos[3].key == selectedKey),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Jika 5 item: Baris 1 (3 item), Baris 2 (2 item simetris di tengah)
    if (memos.length == 5) {
      return Column(
        children: [
          Row(
            children: memos.sublist(0, 3).map((memo) {
              final isSelected = memo.key == selectedKey;
              return Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  child: _buildRealPhysicalMemo(memo, isSelected),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(flex: 1),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  child: _buildRealPhysicalMemo(memos[3], memos[3].key == selectedKey),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  child: _buildRealPhysicalMemo(memos[4], memos[4].key == selectedKey),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ],
      );
    }

    // Jika 6 item atau lebih: Baris 1 (3 item), Baris 2 (3 item)
    return Column(
      children: [
        Row(
          children: memos.sublist(0, 3).map((memo) {
            final isSelected = memo.key == selectedKey;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.5),
                child: _buildRealPhysicalMemo(memo, isSelected),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: memos.sublist(3, memos.length.clamp(3, 6)).map((memo) {
            final isSelected = memo.key == selectedKey;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.5),
                child: _buildRealPhysicalMemo(memo, isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Membuat kertas memo persegi panjang proporsional dengan sobekan fisik & tinta menyatu
  Widget _buildRealPhysicalMemo(MadingMemoItem memo, bool isSelected) {
    const double memoHeight = 64.0;
    final angle = isSelected ? 0.0 : (memo.rotation * 0.45);
    final ink = memo.inkColor;

    return Transform.rotate(
      angle: angle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelectMemo(memo.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: memoHeight,
          transform: isSelected
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.identity(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Bayangan Melengkung Kertas (Paper Shadow) ──
              Positioned(
                top: 6,
                left: 2,
                right: 1,
                bottom: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: isSelected ? 0.18 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),

              // ── Kertas Memo Sobekan Alami (Real Hand-Torn Edge) ──
              Positioned.fill(
                top: 5,
                child: ClipPath(
                  clipper: _RealTornPaperClipper(seed: memo.seed),
                  child: Container(
                    decoration: BoxDecoration(
                      color: memo.paperColor,
                      border: isSelected
                          ? Border.all(
                              color: ink.withValues(alpha: 0.35),
                              width: 1.2,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Garis-garis samar buku catatan bergaris
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
                          height: 3,
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),

                        // Konten Catatan Memo: Ikon Mini & Teks Kalam
                        Padding(
                          padding: const EdgeInsets.fromLTRB(3, 7, 3, 3),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Ikon bergaya cap stempel tinta
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ink.withValues(alpha: 0.08),
                                  ),
                                  child: Icon(
                                    memo.icon,
                                    size: 15,
                                    color: ink.withValues(alpha: 0.90),
                                  ),
                                ),
                                const SizedBox(height: 1.5),

                                // Teks tulisan tangan Kalam menyatu ke kertas
                                Text(
                                  memo.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.kalam(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: ink.withValues(alpha: 0.92),
                                    height: 1.0,
                                    letterSpacing: 0.1,
                                    shadows: [
                                      Shadow(
                                        color: ink.withValues(alpha: 0.15),
                                        offset: const Offset(0.2, 0.3),
                                        blurRadius: 0.4,
                                      ),
                                    ],
                                  ),
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

              // ── Badge Angka Alami (Paper Tag Sticker) ──
              if (memo.count > 0)
                Positioned(
                  top: 1,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      memo.count.toString(),
                      style: GoogleFonts.kalam(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

              // ── Pushpin 3D Menancap di Atas Tengah Kertas ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.translate(
                    offset: Offset((memo.seed % 3 - 1) * 7.0, 0),
                    child: _buildRealPushPin(memo.pinColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membuat Pushpin 3D dengan sorot cahaya, bayangan di kertas, dan lubang jarum
  Widget _buildRealPushPin(Color color) {
    const double size = 11.5;

    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bayangan pin yang jatuh ke kertas
          Positioned(
            right: 1,
            bottom: 1.5,
            child: Container(
              width: size * 0.75,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),

          // Lubang tancap jarum mikro (Pinhole)
          Positioned(
            bottom: 2.5,
            child: Container(
              width: 2.0,
              height: 2.0,
              decoration: const BoxDecoration(
                color: Color(0xFF334155),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Jarum pin logam perak kecil
          Positioned(
            bottom: 3.0,
            child: Container(
              width: 1.5,
              height: 3.2,
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
                  blurRadius: 2.5,
                  offset: const Offset(0, 1),
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
    path.lineTo(w, h - 5);

    // ── Tepi Bawah: Sobekan serat kertas bergelombang mikro halus ──
    const int segments = 12;
    final double dx = w / segments;

    for (int i = 0; i < segments; i++) {
      final double x1 = w - (i + 0.5) * dx;
      final double x2 = w - (i + 1.0) * dx;

      // Variasi kurva halus 1-2px
      final double wave = math.sin((i + seed * 3) * 1.5) * 1.5 +
          math.cos((i * 2 + seed) * 1.2) * 0.8;

      final double y1 = h - 4 + wave;
      final double y2 = h - 4 - (wave * 0.4);

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
      ..strokeWidth = 0.7;

    // Garis horizontal memo compact
    double y = 18.0;
    while (y < size.height - 7) {
      canvas.drawLine(Offset(3, y), Offset(size.width - 3, y), linePaint);
      y += 11.0;
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
