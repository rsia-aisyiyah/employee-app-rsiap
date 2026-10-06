import 'package:flutter/material.dart';

class GameOverDialog extends StatelessWidget {
  final int score;
  final int distance;
  final int itemsCollected;
  final int topSpeed;
  final bool isSubmitting;
  final bool isPersonalBest;
  final int? globalRank;
  final VoidCallback onPlayAgain;
  final VoidCallback onShowLeaderboard;
  final VoidCallback onExit;

  const GameOverDialog({
    Key? key,
    required this.score,
    required this.distance,
    required this.itemsCollected,
    required this.topSpeed,
    required this.isSubmitting,
    required this.isPersonalBest,
    this.globalRank,
    required this.onPlayAgain,
    required this.onShowLeaderboard,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E242B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00A896).withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon & Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE53935).withOpacity(0.4), width: 2),
              ),
              child: const Icon(
                Icons.car_crash_rounded,
                color: Color(0xFFFF5252),
                size: 40,
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'AMBULANS TERHAMBAT!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Perjalanan darurat Anda berakhir di sini',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),

            const SizedBox(height: 20),

            // Score Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A896), Color(0xFF028090)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'TOTAL SKOR',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (isPersonalBest) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD600),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '⭐ REKOR PRIBADI BARU!',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stat Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.straighten_rounded,
                    label: 'Jarak',
                    value: '$distance m',
                    color: const Color(0xFF4FC3F7),
                  ),
                  _StatItem(
                    icon: Icons.medical_services_rounded,
                    label: 'Item Medis',
                    value: '$itemsCollected',
                    color: const Color(0xFF81C784),
                  ),
                  _StatItem(
                    icon: Icons.speed_rounded,
                    label: 'Top Speed',
                    value: '$topSpeed km/h',
                    color: const Color(0xFFFFB74D),
                  ),
                  if (globalRank != null && globalRank! > 0)
                    _StatItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'Peringkat',
                      value: '#$globalRank',
                      color: const Color(0xFFFFD54F),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.replay_rounded, size: 20),
                label: const Text(
                  'MAIN LAGI',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A896),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShowLeaderboard,
                    icon: const Icon(Icons.leaderboard_rounded, size: 18),
                    label: const Text('Klasemen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExit,
                    icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                    label: const Text('Keluar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
        ),
      ],
    );
  }
}
