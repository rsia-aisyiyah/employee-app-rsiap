import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'baby_bath_game_screen.dart';
import 'widgets/baby_bath_leaderboard_sheet.dart';

/// Layar Menu Utama Game "RSIA Baby Spa & Bath Care"
class BabyBathHomeScreen extends StatelessWidget {
  const BabyBathHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: const Text(
          "Baby Spa & Bath Care",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Hero Banner Ilustrasi Kartun Bayi Mandi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE0F2FE),
                      Color(0xFFBAE6FD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo RSIA Aisyiyah & Badge Perinatologi
                    Container(
                      width: 95,
                      height: 95,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.20),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo-rsia-aisyiyah.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.child_care_rounded,
                            size: 48,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Badge Unit Perinatologi (Tanpa pengulangan kata RSIA)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        "INSTALASI PERINATOLOGI & KEBIDANAN",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0369A1),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Baby Bath & Care Simulator",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0369A1),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Simulasi interaktif memandikan bayi sesuai SOP medis, menaruh kembali ke boks bayi, dan menyelesaikan shift perinatologi.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Panduan SOP Medis
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Panduan SOP Mandi Bayi:",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _buildSopStep(
                number: "1",
                title: "Suhu Air Hangat Ideal",
                desc: "Campur air hingga suhu 36.5°C - 37.5°C. Jangan terlalu panas atau dingin.",
                icon: Icons.thermostat_rounded,
                color: const Color(0xFF0284C7),
              ),
              _buildSopStep(
                number: "2",
                title: "Wajah & Rambut Terlebih Dahulu",
                desc: "Gunakan kapas steril lembut untuk mata dan wajah, lalu keramas perlahan.",
                icon: Icons.face_rounded,
                color: const Color(0xFFF59E0B),
              ),
              _buildSopStep(
                number: "3",
                title: "Gosok Badan & Mainkan Bebek",
                desc: "Usap sabun ke lipatan leher, ketiak, dan badan. Buat bayi gembira!",
                icon: Icons.soap_rounded,
                color: const Color(0xFF10B981),
              ),
              _buildSopStep(
                number: "4",
                title: "Bilas & Keringkan Segera",
                desc: "Bilas busa hingga tuntas, lalu bungkus handuk hangat dan beri minyak telon.",
                icon: Icons.spa_rounded,
                color: const Color(0xFF8B5CF6),
              ),

              const SizedBox(height: 32),

              // Tombol Mulai Memandikan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BabyBathGameScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text(
                    "Mulai Memandikan Bayi",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tombol Papan Peringkat (Leaderboard)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => BabyBathLeaderboardSheet.show(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0369A1),
                    side: const BorderSide(color: Color(0xFFBAE6FD), width: 1.5),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 20),
                  label: const Text(
                    "Papan Peringkat (Leaderboard)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSopStep({
    required String number,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, size: 18, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
