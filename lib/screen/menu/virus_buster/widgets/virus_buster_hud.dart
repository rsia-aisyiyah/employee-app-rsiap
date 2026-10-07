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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Lives, Flexible Stage Info, Skor & Pause
            Row(
              children: [
                // Lives (Hati Kesehatan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(stats.maxLives, (index) {
                      final isAlive = index < stats.lives;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Icon(
                          isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isAlive ? const Color(0xFFEF4444) : Colors.white24,
                          size: 16,
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(width: 8),

                // Stage Info Pill (Expanded agar tidak pernah overflow)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFF00E5FF), size: 13),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'S${stats.stage}: ${stageConfig.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Skor
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Pause Button
                InkWell(
                  onTap: onPause,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.pause_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Row 2: Progress Bar Menuju Boss & Active Power-up Timer
            Row(
              children: [
                // Progress Bar
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.8),
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

                // Active Power-up Tag
                if (stats.activePowerupName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          '${stats.activePowerupName} ${stats.powerupTimer.toStringAsFixed(0)}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
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
