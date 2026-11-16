import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Model item memo di papan mading dengan karakteristik fisik alami
class MadingMemoItem {
  final String key;
  final String title;
  final int count;
  final Color pinColor;
  final Color paperColor;
  final Color accentColor;
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
    required this.accentColor,
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
                        const Text(
                          "MADING AGENDA & TUGAS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF63472A),
                            letterSpacing: 0.6,
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

  /// Membuat kertas memo dengan efek sobekan tangan alami & paper curl
  Widget _buildRealPhysicalMemo(MadingMemoItem memo, bool isSelected) {
    const memoWidth = 88.0;
    const memoHeight = 94.0;
    final angle = isSelected ? memo.rotation * 0.25 : memo.rotation;

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
              // ── Bayangan Melengkung Kertas (Paper Curl Shadow) ──
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

                        // Konten Catatan Memo
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                memo.icon,
                                size: 21,
                                color: memo.accentColor,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                memo.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  color: const Color(0xFF334155),
                                  height: 1.1,
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

              // ── Badge Angka Alami (Red Paper Tag) ──
              if (memo.count > 0)
                Positioned(
                  top: 2,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: memo.accentColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 2.5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      memo.count.toString(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
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
