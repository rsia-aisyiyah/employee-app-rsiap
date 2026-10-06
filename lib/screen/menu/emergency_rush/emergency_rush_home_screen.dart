import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/emergency_rush_leaderboard_screen.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/emergency_rush_screen.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/services/emergency_rush_service.dart';

class EmergencyRushHomeScreen extends StatefulWidget {
  const EmergencyRushHomeScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyRushHomeScreen> createState() => _EmergencyRushHomeScreenState();
}

class _EmergencyRushHomeScreenState extends State<EmergencyRushHomeScreen>
    with SingleTickerProviderStateMixin {
  int _highScore = 0;
  int _maxDistance = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadStats();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final local = await EmergencyRushService.getLocalBest();
    if (mounted) {
      setState(() {
        _highScore = local['high_score'] ?? 0;
        _maxDistance = local['max_distance'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Ambient background glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A896).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            top: 220,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ─── TOP APP BAR ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),

                      // Category Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF00A896).withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sports_esports_rounded,
                                color: Color(0xFF00A896), size: 15),
                            SizedBox(width: 6),
                            Text(
                              'RSIA ARCADE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Leaderboard Shortcut
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmergencyRushLeaderboardScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: const Icon(Icons.leaderboard_rounded,
                              color: Color(0xFFFFD54F), size: 19),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── SCROLLABLE CONTENT ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── HERO SHOWPIECE CARD ──────────────────────────
                        _buildHeroShowpiece(),

                        const SizedBox(height: 16),

                        // ─── STATS BENTO TILES ────────────────────────────
                        _buildStatsRow(),

                        const SizedBox(height: 18),

                        // ─── SECTION TITLE ────────────────────────────────
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A896),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'MEKANIK & TANTANGAN',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ─── BENTO GRID ITEM INTEL ────────────────────────
                        _buildIntelCards(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── STICKY BOTTOM LAUNCH BAR ─────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomLaunchBar(),
          ),
        ],
      ),
    );
  }

  // ─── HERO SHOWPIECE ────────────────────────────────────────────────────────
  Widget _buildHeroShowpiece() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Road Background Stripe Watermark
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(
                painter: _RoadShowpiecePatternPainter(),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A896).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'HIGH SPEED REFLEX',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    // Live Siren indicator
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _pulseController.value > 0.5
                                    ? const Color(0xFFFF1744)
                                    : const Color(0xFF2979FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pulseController.value > 0.5
                                        ? const Color(0x88FF1744)
                                        : const Color(0x882979FF),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'READY',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Main Title & Ambulance Vector Miniature
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EMERGENCY\nRUSH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ambulans Gesit RSIA',
                            style: TextStyle(
                              color: Color(0xFF00A896),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kendalikan laju ambulans menembus 3 lajur lalu lintas kota. Kumpulkan P3K & booster sirine.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Ambulance Miniature Stand
                    _buildAmbulanceStand(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── AMBULANCE STAND ───────────────────────────────────────────────────────
  Widget _buildAmbulanceStand() {
    return Container(
      width: 76,
      height: 104,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1318),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Road center line
          Positioned(
            top: 6,
            bottom: 6,
            child: Container(
              width: 2.5,
              color: const Color(0x44FFD54F),
            ),
          ),

          // Mini Ambulance Body
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(0, sin(_pulseController.value * pi) * 2),
                child: Container(
                  width: 38,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: _pulseController.value > 0.5
                            ? const Color(0x44FF1744)
                            : const Color(0x442979FF),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Dual RSIA Teal Stripe
                      Positioned(
                        left: 2,
                        top: 6,
                        bottom: 6,
                        width: 3,
                        child: Container(color: const Color(0xFF00A896)),
                      ),
                      Positioned(
                        right: 2,
                        top: 6,
                        bottom: 6,
                        width: 3,
                        child: Container(color: const Color(0xFF00A896)),
                      ),
                      // Windshield
                      Positioned(
                        top: 14,
                        left: 6,
                        right: 6,
                        height: 9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF263238),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Siren bar on roof
                      Positioned(
                        top: 8,
                        left: 10,
                        right: 10,
                        height: 4,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF1744),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(2),
                                    bottomLeft: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2979FF),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(2),
                                    bottomRight: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // RSIA cross on roof
                      Positioned(
                        top: 34,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE53935),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, color: Colors.white, size: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── STATS BENTO ROW ───────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        // Best Score Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFFD54F), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HIGH SCORE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_highScore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Max Distance Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A896).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.route_rounded,
                      color: Color(0xFF00A896), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JARAK TERJAUH',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_maxDistance m',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── INTEL TILES (BENTO GRID) ──────────────────────────────────────────────
  Widget _buildIntelCards() {
    return Column(
      children: [
        _intelTile(
          icon: Icons.swipe_rounded,
          iconColor: const Color(0xFF00E5FF),
          title: 'Kendali Refleks 3 Lajur',
          desc: 'Swipe jari kiri/kanan atau gunakan tombol navigasi untuk bermanuver menghindari kemacetan.',
          badge: 'KONTROL',
        ),
        const SizedBox(height: 8),
        _intelTile(
          icon: Icons.medical_services_rounded,
          iconColor: const Color(0xFF00A896),
          title: 'Koleksi Item Medis',
          desc: 'First Aid Kit (🩹) memulihkan nyawa hati, Kapsul Energi (💊) mengisi daya turbo darurat.',
          badge: 'PICKUPS',
        ),
        const SizedBox(height: 8),
        _intelTile(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFFFFD54F),
          title: 'Mode Sirine Turbo',
          desc: 'Saat bar energi penuh, aktifkan sirine untuk melaju kebal dan menabrak rintangan tanpa celaka.',
          badge: 'POWER-UP',
        ),
      ],
    );
  }

  Widget _intelTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM FIXED LAUNCH BAR ───────────────────────────────────────────────
  Widget _buildBottomLaunchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D1117).withOpacity(0.0),
            const Color(0xFF0D1117).withOpacity(0.92),
            const Color(0xFF0D1117),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Leaderboard button
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmergencyRushLeaderboardScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(Icons.leaderboard_rounded,
                    color: Color(0xFFFFD54F), size: 22),
              ),
            ),

            const SizedBox(width: 12),

            // Start Race Button
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyRushScreen(),
                      ),
                    );
                    _loadStats();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: const Color(0xFF00A896).withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'MULAI MELAJU',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ROAD BACKGROUND PATTERN PAINTER ─────────────────────────────────────────
class _RoadShowpiecePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1.0;

    // Draw subtle technical grid lines
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
