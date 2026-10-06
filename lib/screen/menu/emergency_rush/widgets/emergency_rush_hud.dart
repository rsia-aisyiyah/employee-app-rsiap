import 'package:flutter/material.dart';

class EmergencyRushHud extends StatelessWidget {
  final int score;
  final int distance;
  final int speed;
  final int lives;
  final double sirenEnergy;
  final bool isSirenActive;
  final VoidCallback onPause;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onActivateSiren;

  const EmergencyRushHud({
    Key? key,
    required this.score,
    required this.distance,
    required this.speed,
    required this.lives,
    required this.sirenEnergy,
    required this.isSirenActive,
    required this.onPause,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onActivateSiren,
  }) : super(key: key);

  Color _getSpeedColor(int speed) {
    if (speed < 80) return const Color(0xFF00E676);
    if (speed < 110) return const Color(0xFFFFD600);
    if (speed < 135) return const Color(0xFFFF9100);
    return const Color(0xFFFF1744);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // ─── TOP STATUS BAR ───────────────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pause button & Lives
                Row(
                  children: [
                    GestureDetector(
                      onTap: onPause,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Icon(Icons.pause_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Hearts
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        children: List.generate(3, (index) {
                          final isAlive = index < lives;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isAlive ? const Color(0xFFFF1744) : Colors.white30,
                              size: 18,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),

                // Distance & Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSirenActive
                              ? [const Color(0xFF00E5FF), const Color(0xFF00B0FF)]
                              : [const Color(0xFF00A896), const Color(0xFF028090)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isSirenActive
                                ? const Color(0x6600E5FF)
                                : const Color(0x4400A896),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSirenActive) ...[
                            const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '$score PTS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Distance
                    Text(
                      '$distance m',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── SPEED & SIREN GAUGE (Upper Left) ─────────────────────
          Positioned(
            top: 72,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Speedometer pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _getSpeedColor(speed).withOpacity(0.6), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed_rounded, color: _getSpeedColor(speed), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$speed',
                        style: TextStyle(
                          color: _getSpeedColor(speed),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        ' km/h',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Siren Rush Ready Button / Bar
                GestureDetector(
                  onTap: sirenEnergy >= 0.8 ? onActivateSiren : null,
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSirenActive
                          ? const Color(0xFF00E5FF).withOpacity(0.25)
                          : (sirenEnergy >= 0.8
                              ? const Color(0xFFFFD600).withOpacity(0.2)
                              : Colors.black.withOpacity(0.55)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSirenActive
                            ? const Color(0xFF00E5FF)
                            : (sirenEnergy >= 0.8 ? const Color(0xFFFFD600) : Colors.white24),
                        width: sirenEnergy >= 0.8 ? 1.8 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isSirenActive ? 'TURBO ON!' : (sirenEnergy >= 0.8 ? 'TAP SIRINE!' : 'SIRINE'),
                              style: TextStyle(
                                color: isSirenActive
                                    ? const Color(0xFF00E5FF)
                                    : (sirenEnergy >= 0.8 ? const Color(0xFFFFD600) : Colors.white70),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Icon(
                              Icons.notifications_active_rounded,
                              size: 13,
                              color: isSirenActive
                                  ? const Color(0xFF00E5FF)
                                  : (sirenEnergy >= 0.8 ? const Color(0xFFFFD600) : Colors.white38),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: sirenEnergy,
                            minHeight: 5,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isSirenActive
                                  ? const Color(0xFF00E5FF)
                                  : (sirenEnergy >= 0.8 ? const Color(0xFFFFD600) : const Color(0xFF00A896)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── BOTTOM ON-SCREEN STEER BUTTONS (Optional) ────────────
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Arrow
                _SteerButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onMoveLeft,
                ),

                // Hint in the center
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Geser / Tap Lajur',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),

                // Right Arrow
                _SteerButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onTap: onMoveRight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SteerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SteerButton({Key? key, required this.icon, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
