import 'package:flutter/material.dart';
import '../engine/baby_bath_controller.dart';

/// Dialog Selesai Mandi dengan Evaluasi Bintang 1-3 & SOP Medis
class BabyBathCompleteDialog extends StatelessWidget {
  final BabyBathController controller;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const BabyBathCompleteDialog({
    super.key,
    required this.controller,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final stars = controller.calculateStars();

    Color titleColor = const Color(0xFF10B981);

    if (stars == 3) {
      titleColor = const Color(0xFF0284C7);
    } else if (stars == 2) {
      titleColor = const Color(0xFFF59E0B);
    } else {
      titleColor = const Color(0xFFEF4444);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bersih Tanpa Redundansi Teks
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo-rsia-aisyiyah.png',
                  height: 26,
                  errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital_rounded, size: 22, color: Color(0xFF0D9488)),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Evaluasi Shift Perinatologi",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F766E),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Deretan Bintang 1-3
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isEarned = index < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 38,
                    color: isEarned ? const Color(0xFFFBBF24) : Colors.grey.shade300,
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            Text(
              controller.completedBabiesCount >= 3
                  ? "Bidan Perinatologi Teladan!"
                  : (controller.completedBabiesCount >= 2
                      ? "Perawat Mahir Mandi Bayi!"
                      : "Shift Telah Berakhir!"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "${controller.completedBabiesCount} bayi telah bersih, wangi, dan tertidur lelap di boks!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 14),

            // Kartu Skor Rincian Multi-Bayi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                children: [
                  _buildScoreRow("Bayi Selesai di Boks", "👶 ${controller.completedBabiesCount} Bayi"),
                  const Divider(height: 14),
                  _buildScoreRow("Skor Total Shift", "${controller.score} Poin"),
                  const SizedBox(height: 6),
                  _buildScoreRow("Tingkat Kenyamanan", "${controller.comfortMeter.toInt()}%"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Main Lagi / Keluar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Main Lagi", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}
