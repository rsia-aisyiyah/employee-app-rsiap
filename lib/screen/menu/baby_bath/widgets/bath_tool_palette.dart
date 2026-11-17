import 'package:flutter/material.dart';
import '../models/baby_bath_models.dart';
import '../engine/baby_bath_controller.dart';

/// Palet Alat Interaktif Memandikan Bayi di Bagian Bawah Layar
class BathToolPalette extends StatelessWidget {
  final BabyBathController controller;

  const BathToolPalette({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Baris Instruksi Petunjuk SOP Fase
            _buildPhaseInstruction(),

            const SizedBox(height: 10),

            // Baris Alat-Alat
            _buildToolRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseInstruction() {
    String instruction = "";
    IconData icon = Icons.info_outline_rounded;

    switch (controller.phase) {
      case BathPhase.waterPrep:
        instruction = "Campur kran panas & dingin hingga suhu 36.5° - 37.5°C";
        icon = Icons.thermostat_rounded;
        break;
      case BathPhase.faceAndHair:
        instruction = "Usap kapas ke mata/wajah, lalu teteskan sampo ke rambut";
        icon = Icons.face_rounded;
        break;
      case BathPhase.bodyScrub:
        instruction = "Usap spons sabun ke tubuh bayi, tap bebek agar tertawa";
        icon = Icons.soap_rounded;
        break;
      case BathPhase.rinsing:
        instruction = "Semprot shower air hangat hingga semua busa hilang";
        icon = Icons.shower_rounded;
        break;
      case BathPhase.dryingCare:
        instruction = "Keringkan dengan handuk lembut lalu oleskan minyak telon";
        icon = Icons.spa_rounded;
        break;
      case BathPhase.returnToCrib:
        instruction = "Pindahkan ${controller.currentBaby.motherName} ke boks tempat tidur bayi!";
        icon = Icons.bedroom_baby_rounded;
        break;
      case BathPhase.completed:
        instruction = "Shift selesai! Evaluasi performa memandikan bayi!";
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0284C7)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              instruction,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0369A1),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolRow() {
    switch (controller.phase) {
      case BathPhase.waterPrep:
        final isTempReady = controller.waterTemp >= 36.0 && controller.waterTemp <= 38.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionBtn(
              icon: Icons.hot_tub_rounded,
              label: "+ Air Panas",
              color: const Color(0xFFEF4444),
              onTap: controller.addHotWater,
            ),
            _buildActionBtn(
              icon: Icons.ac_unit_rounded,
              label: "+ Air Dingin",
              color: const Color(0xFF3B82F6),
              onTap: controller.addColdWater,
            ),
            ElevatedButton.icon(
              onPressed: isTempReady ? controller.advancePhaseManually : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text(
                "Mulai Mandi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        );

      case BathPhase.faceAndHair:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSelectableTool(
              tool: BathTool.cottonPad,
              icon: Icons.cleaning_services_rounded,
              label: "Kapas Steril",
              color: const Color(0xFF0284C7),
            ),
            _buildSelectableTool(
              tool: BathTool.shampoo,
              icon: Icons.sanitizer_rounded,
              label: "Sampo Bayi",
              color: const Color(0xFFF59E0B),
            ),
          ],
        );

      case BathPhase.bodyScrub:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSelectableTool(
              tool: BathTool.soapSponge,
              icon: Icons.soap_rounded,
              label: "Spons Sabun",
              color: const Color(0xFF10B981),
            ),
            _buildActionBtn(
              icon: Icons.toys_rounded,
              label: "Tekan Bebek",
              color: const Color(0xFFFBBF24),
              onTap: () {
                controller.onTouch(controller.duckPosition);
              },
            ),
          ],
        );

      case BathPhase.rinsing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSelectableTool(
              tool: BathTool.showerSpray,
              icon: Icons.shower_rounded,
              label: "Shower Bilas",
              color: const Color(0xFF0284C7),
            ),
          ],
        );

      case BathPhase.dryingCare:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSelectableTool(
              tool: BathTool.softTowel,
              icon: Icons.dry_rounded,
              label: "Handuk Bayi",
              color: const Color(0xFF8B5CF6),
            ),
            _buildSelectableTool(
              tool: BathTool.babyOil,
              icon: Icons.water_drop_rounded,
              label: "Minyak Telon",
              color: const Color(0xFFF59E0B),
            ),
          ],
        );

      case BathPhase.returnToCrib:
        if (!controller.isBabyInCrib) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: controller.putBabyInCrib,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  elevation: 2,
                ),
                icon: const Icon(Icons.bedroom_baby_rounded, size: 20),
                label: const Text(
                  "Letakkan di Boks Bayi (+150)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: controller.loadNextBaby,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  elevation: 2,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text(
                  "Panggil Bayi Berikutnya ➜",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          );
        }

      case BathPhase.completed:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectableTool({
    required BathTool tool,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = controller.activeTool == tool;

    return GestureDetector(
      onTap: () => controller.selectTool(tool),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.14) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
