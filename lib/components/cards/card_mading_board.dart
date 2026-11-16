import 'package:flutter/material.dart';

/// Model item memo di papan mading
class MadingMemoItem {
  final String key;
  final String title;
  final int count;
  final Color pinColor;
  final Color paperColor;
  final Color accentColor;
  final IconData icon;
  final double rotation;

  const MadingMemoItem({
    required this.key,
    required this.title,
    required this.count,
    required this.pinColor,
    required this.paperColor,
    required this.accentColor,
    required this.icon,
    this.rotation = 0.0,
  });
}

/// Widget Papan Mading (Bulletin Board) bergaya Corkboard Interaktif
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
        // Nuansa papan gabus hangat modern (Corkboard Warm Sand)
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8DFC8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5E3C).withValues(alpha: 0.07),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Papan Mading (Wood-style Pill Header) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Wooden / Craft Header Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE3D1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD6C6A7), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "📌",
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 5),
                      Text(
                        "PAPAN AGENDA & TUGAS",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B4E2E),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Total counter chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: totalAgenda > 0
                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    totalAgenda > 0 ? "$totalAgenda Perlu Respon" : "Semua Beres ✓",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: totalAgenda > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Deretan Memo Kertas Berpin (Pinned Sticky Notes Carousel) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: memos.map((memo) {
                final isSelected = memo.key == selectedKey;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildStickyNote(memo, isSelected),
                );
              }).toList(),
            ),
          ),

          // ── Divider Halus Papan ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE8DFC8).withValues(alpha: 0.8),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "DETAIL ITEM TERPILIH",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9E8E75),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE8DFC8).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Kartu Tiket Aktif di Bawah Papan ──
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedSwitcher(
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
          ),
        ],
      ),
    );
  }

  /// Membuat kertas sticky note lengkap dengan jarum pin 3D
  Widget _buildStickyNote(MadingMemoItem memo, bool isSelected) {
    return Transform.rotate(
      angle: isSelected ? 0.0 : memo.rotation,
      child: GestureDetector(
        onTap: () => onSelectMemo(memo.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 82,
          height: 84,
          transform: isSelected
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.identity(),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // ── Lembaran Kertas Memo ──
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: memo.paperColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? memo.accentColor
                          : const Color(0xFFE2D6C0),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isSelected ? 0.12 : 0.05,
                        ),
                        blurRadius: isSelected ? 8 : 4,
                        offset: Offset(0, isSelected ? 4 : 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        memo.icon,
                        size: 20,
                        color: memo.accentColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        memo.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Badge Counter di Sudut Kanan Kertas ──
              if (memo.count > 0)
                Positioned(
                  top: 4,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: memo.accentColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 3,
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

              // ── Pushpin 3D di Bagian Atas Kertas ──
              Positioned(
                top: 1,
                child: _build3dPushPin(memo.pinColor, isSelected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membuat Pushpin 3D dengan refleksi cahaya dan bayangan
  Widget _build3dPushPin(Color color, bool isSelected) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow pin
          Positioned(
            bottom: 0,
            child: Container(
              width: 10,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Kepala pin 3D
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.35),
                radius: 0.7,
                colors: [
                  Colors.white.withValues(alpha: 0.7),
                  color,
                  Color.lerp(color, Colors.black, 0.45) ?? Colors.black,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
