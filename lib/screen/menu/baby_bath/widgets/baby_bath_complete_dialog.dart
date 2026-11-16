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

    String title = "Luar Biasa!";
    String subtitle = "Bayi bersih, wangi, dan sangat nyaman!";
    Color titleColor = const Color(0xFF10B981);

    if (stars == 3) {
      title = "Spesialis Mandi Bayi Teladan!";
      subtitle = "Suhu air pas dan bayi sangat ceria & nyaman!";
      titleColor = const Color(0xFF0284C7);
    } else if (stars == 2) {
      title = "Hebat & Teliti!";
      subtitle = "Bayi sudah bersih, jaga kestabilan suhu air ya.";
      titleColor = const Color(0xFFF59E0B);
    } else {
      title = "Perlu Perhatian Ekstra!";
      subtitle = "Perhatikan suhu air agar bayi tidak menangis.";
      titleColor = const Color(0xFFEF4444);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 16),

            // Kartu Skor Rincian
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                children: [
                  _buildScoreRow("Skor Total", "${controller.score} Poin"),
                  const Divider(height: 16),
                  _buildScoreRow("Suhu Akhir", "${controller.waterTemp.toStringAsFixed(1)}°C"),
                  const SizedBox(height: 6),
                  _buildScoreRow("Kenyamanan", "${controller.comfortMeter.toInt()}%"),
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
