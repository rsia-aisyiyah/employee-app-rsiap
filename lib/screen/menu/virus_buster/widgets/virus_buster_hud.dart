import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/models/virus_buster_models.dart';

class VirusBusterHud extends StatelessWidget {
  final VirusBusterStats stats;
  final VoidCallback onPause;

  const VirusBusterHud({
    Key? key,
    required this.stats,
    required this.onPause,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stageConfig = StageConfig.stages[(stats.stage - 1).clamp(0, StageConfig.stages.length - 1)];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Lives, Stage Pill, Skor & Pause
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lives (Hati Kesehatan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(stats.maxLives, (index) {
                      final isAlive = index < stats.lives;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isAlive ? const Color(0xFFEF4444) : Colors.white24,
                          size: 18,
                        ),
                      );
                    }),
                  ),
                ),

                // Stage Info Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFF00E5FF), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'STAGE ${stats.stage}: ${stageConfig.locationTag.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                // Skor & Pause
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${stats.score}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onPause,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: const Icon(Icons.pause_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Row 2: Progress to Boss & Active Power-up timer
            Row(
              children: [
                // Progress Bar Menuju Boss
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: stats.stageProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00A896), Color(0xFF00E5FF)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),

                // Active Powerup Tag (jika aktif)
                if (stats.activePowerupName.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          '${stats.activePowerupName} (${stats.powerupTimer.toStringAsFixed(0)}s)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
