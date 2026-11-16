import 'package:flutter/material.dart';
import '../engine/baby_bath_controller.dart';

/// Heads-Up Display (HUD) untuk Game Memandikan Bayi
class BabyBathHud extends StatelessWidget {
  final BabyBathController controller;
  final VoidCallback onExit;

  const BabyBathHud({
    super.key,
    required this.controller,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final temp = controller.waterTemp;
    final isOptimalTemp = temp >= 36.0 && temp <= 38.0;
    final tempColor = isOptimalTemp
        ? const Color(0xFF10B981)
        : (temp > 38.0 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6));

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Kembali / Pause
                InkWell(
                  onTap: onExit,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF1E293B)),
                  ),
                ),

                // Indikator Suhu Air Termometer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tempColor.withValues(alpha: 0.40)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.thermostat_rounded, size: 16, color: tempColor),
                      const SizedBox(width: 4),
                      Text(
                        "${temp.toStringAsFixed(1)}°C",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: tempColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOptimalTemp ? "Ideal" : (temp > 38.0 ? "Panas" : "Dingin"),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tempColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indikator Skor
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        "${controller.score}",
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Baris Meter Kebersihan & Kenyamanan
            Row(
              children: [
                // Cleanliness Meter
                Expanded(
                  child: _buildMeterBar(
                    label: "Kebersihan",
                    value: controller.cleanlinessProgress,
                    color: const Color(0xFF0284C7),
                    icon: Icons.cleaning_services_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                // Comfort Meter
                Expanded(
                  child: _buildMeterBar(
                    label: "Kenyamanan",
                    value: controller.comfortMeter / 100.0,
                    color: const Color(0xFFEC4899),
                    icon: Icons.favorite_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeterBar({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Text(
                "${(value * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
