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
            // ── Baris 1: Tombol Kembali, Profil Bayi, Timer & Skor ──
            Row(
              children: [
                // Tombol Kembali
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
                    child: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(width: 8),

                // Profil Bayi Aktif
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/logo-rsia-aisyiyah.png',
                          height: 18,
                          errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital_rounded, size: 16, color: Color(0xFF0D9488)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            controller.currentBaby.motherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Timer Shift Countdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: controller.shiftSecondsRemaining <= 30
                        ? const Color(0xFFFEF2F2)
                        : Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.shiftSecondsRemaining <= 30
                          ? const Color(0xFFEF4444)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: controller.shiftSecondsRemaining <= 30
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${(controller.shiftSecondsRemaining ~/ 60)}:${(controller.shiftSecondsRemaining.toInt() % 60).toString().padLeft(2, '0')}",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: controller.shiftSecondsRemaining <= 30
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Indikator Skor
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, size: 15, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        "${controller.score}",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Baris 2: Bayi Selesai di Boks & Suhu Air ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Counter Bayi Selesai Masuk Boks
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bedroom_baby_rounded, size: 15, color: Color(0xFF10B981)),
                      const SizedBox(width: 5),
                      Text(
                        "${controller.completedBabiesCount} Bayi di Boks",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),

                // Indikator Suhu Air Termometer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tempColor.withValues(alpha: 0.40)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.thermostat_rounded, size: 15, color: tempColor),
                      const SizedBox(width: 4),
                      Text(
                        "${temp.toStringAsFixed(1)}°C",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: tempColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOptimalTemp ? "(Ideal)" : (temp > 38.0 ? "(Panas)" : "(Dingin)"),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tempColor,
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
