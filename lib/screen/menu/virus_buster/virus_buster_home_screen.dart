import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/services/virus_buster_service.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/virus_buster_screen.dart';

class VirusBusterHomeScreen extends StatefulWidget {
  const VirusBusterHomeScreen({Key? key}) : super(key: key);

  @override
  State<VirusBusterHomeScreen> createState() => _VirusBusterHomeScreenState();
}

class _VirusBusterHomeScreenState extends State<VirusBusterHomeScreen>
    with SingleTickerProviderStateMixin {
  int _highScore = 0;
  int _maxStage = 1;
  int _totalViruses = 0;

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
    final local = await VirusBusterService.getLocalBest();
    if (mounted) {
      setState(() {
        _highScore = local['high_score'] ?? 0;
        _maxStage = local['max_stage'] ?? 1;
        _totalViruses = local['total_viruses'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A896).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
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

                      // Info Icon
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: const Icon(Icons.medical_services_outlined,
                            color: Color(0xFF00E5FF), size: 18),
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
                        // Hero Showpiece Card (Karakter Dokter Canvas Preview)
                        _buildHeroShowpiece(),

                        const SizedBox(height: 16),

                        // Stats Bento Grid
                        _buildStatsRow(),

                        const SizedBox(height: 20),

                        // Section 1: Lokasi Misi
                        _buildSectionHeader('LOKASI PATROLI STERILISASI'),
                        const SizedBox(height: 10),
                        _buildLocationCards(),

                        const SizedBox(height: 20),

                        // Section 2: Intel Virus & Power-up
                        _buildSectionHeader('INTEL VIRUS & AMUNISI MEDIS'),
                        const SizedBox(height: 10),
                        _buildIntelCards(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── STICKY BOTTOM LAUNCH BAR ─────────────────────────────────
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
      child: Column(
        children: [
          // Ilustrasi Vector Karakter Dokter Preview
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Aura lingkaran belakang
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00A896).withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Vector Dokter
                CustomPaint(
                  size: const Size(120, 130),
                  painter: _DoctorHeroPreviewPainter(),
                ),
              ],
            ),
          ),

          // Teks Judul & Tagline
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              children: [
                const Text(
                  'SUPER DOCTOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A896),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'VIRUS BUSTER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Operasi Steril RSIA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Kendalikan Dokter Spesialis dengan Syringe Blaster canggih. Jelajahi area Drop-Off IGD, Lobi Tunggu, hingga Nurse Station untuk membersihkan virus berbahaya!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS BENTO TILES ─────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildBentoTile(
            title: 'SKOR TERTINGGI',
            value: '$_highScore',
            icon: Icons.stars_rounded,
            color: const Color(0xFFFFD54F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBentoTile(
            title: 'STAGE TERTINGGI',
            value: 'Stage $_maxStage',
            icon: Icons.flag_rounded,
            color: const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBentoTile(
            title: 'VIRUS DIBASMI',
            value: '$_totalViruses',
            icon: Icons.coronavirus_rounded,
            color: const Color(0xFF22C55E),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION HEADER ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Row(
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
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ─── LOCATION CARDS ────────────────────────────────────────────────────────
  Widget _buildLocationCards() {
    final spots = [
      {
        'stage': '1',
        'title': 'Drop-Off IGD 24 Jam',
        'desc': 'Area kanopi depan & mobil ambulans gawat darurat RSIA',
        'icon': Icons.airport_shuttle_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'stage': '2',
        'title': 'Lobi Poliklinik',
        'desc': 'Deretan kursi tunggu besi pasien & layar antrean poliklinik',
        'icon': Icons.chair_rounded,
        'color': const Color(0xFF00A896),
      },
      {
        'stage': '3',
        'title': 'Nurse Station',
        'desc': 'Meja perawat neon toska, pintu poli, & berkas rawat inap',
        'icon': Icons.local_hospital_rounded,
        'color': const Color(0xFF38BDF8),
      },
    ];

    return Column(
      children: spots.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (s['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (s['color'] as Color).withOpacity(0.3)),
                ),
                child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STAGE ${s['stage']}: ${s['title']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s['desc'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── INTEL & POWERUP CARDS ─────────────────────────────────────────────────
  Widget _buildIntelCards() {
    return Row(
      children: [
        // Power-ups
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_information_rounded, color: Color(0xFF00E5FF), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'POWER-UP MEDIS',
                      style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildIntelBullet('❤️ P3K', 'Pulihkan 1 Hati'),
                _buildIntelBullet('💊 Vitamin C', 'Tembak Spread 3 Arah'),
                _buildIntelBullet('🛡️ Baju APD', 'Kebal Selama 8 Detik'),
                _buildIntelBullet('🧴 Sanitizer', 'Basmi Seluruh Virus Layar'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Virus Enemies
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.coronavirus_outlined, color: Color(0xFFEF4444), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'TIPE VIRUS',
                      style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildIntelBullet('🟢 Flu-Goo', 'Merayap di Lantai'),
                _buildIntelBullet('🔴 Corona Duri', 'Melayang & Memantul'),
                _buildIntelBullet('🦟 Nyamuk', 'Terbang Menukik Cepat'),
                _buildIntelBullet('👑 Mega Mutasi', 'Boss Akhir Setiap Stage'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntelBullet(String tag, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tag, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9.5)),
        ],
      ),
    );
  }

  // ─── STICKY BOTTOM LAUNCH BAR ──────────────────────────────────────────────
  Widget _buildBottomLaunchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.02);
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VirusBusterScreen(),
                    ),
                  ).then((_) => _loadStats());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A896),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0xFF00A896).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'MULAI MISI DOKTER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// CustomPainter untuk menggambar preview karakter dokter heroik di lobby
class _DoctorHeroPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.85);

    // Kaki & Celana
    final pantsPaint = Paint()..color = const Color(0xFF1E293B);
    final shoesPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -22, 10, 22), const Radius.circular(3)), pantsPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, -22, 10, 22), const Radius.circular(3)), pantsPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -4, 12, 6), const Radius.circular(2)), shoesPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, -4, 12, 6), const Radius.circular(2)), shoesPaint);

    // Jas Snelli Putih
    final coatPaint = Paint()..color = Colors.white;
    final coatBorder = Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final coatRect = RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -60, 32, 40), const Radius.circular(5));
    canvas.drawRRect(coatRect, coatPaint);
    canvas.drawRRect(coatRect, coatBorder);

    // Kemeja & Dasi Biru
    final shirtPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawRect(const Rect.fromLTWH(-6, -60, 12, 14), shirtPaint);
    final tiePaint = Paint()..color = const Color(0xFF0284C7);
    final tiePath = Path();
    tiePath.moveTo(0, -60);
    tiePath.lineTo(-3, -48);
    tiePath.lineTo(0, -42);
    tiePath.lineTo(3, -48);
    tiePath.close();
    canvas.drawPath(tiePath, tiePaint);

    // Stetoskop
    final stethoPaint = Paint()..color = const Color(0xFF475569)..strokeWidth = 2.2..style = PaintingStyle.stroke;
    final stethoPath = Path();
    stethoPath.moveTo(-10, -60);
    stethoPath.quadraticBezierTo(0, -46, 10, -60);
    canvas.drawPath(stethoPath, stethoPaint);
    canvas.drawCircle(const Offset(3, -48), 3, Paint()..color = const Color(0xFFCBD5E1));

    // Kepala & Muka
    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -84, 24, 20), const Radius.circular(7)), skinPaint);

    // Rambut Hitam Rapi
    final hairPaint = Paint()..color = const Color(0xFF0F172A);
    final hairPath = Path();
    hairPath.moveTo(-13, -78);
    hairPath.lineTo(-13, -88);
    hairPath.quadraticBezierTo(0, -92, 13, -88);
    hairPath.lineTo(13, -78);
    hairPath.lineTo(11, -81);
    hairPath.quadraticBezierTo(0, -83, -11, -81);
    hairPath.close();
    canvas.drawPath(hairPath, hairPaint);

    // Mata Dokter Ramah
    final eyeWhite = Paint()..color = Colors.white;
    final eyePupil = Paint()..color = const Color(0xFF0F172A);
    canvas.drawOval(const Rect.fromLTWH(-8, -78, 6, 4.5), eyeWhite);
    canvas.drawCircle(const Offset(-5, -76), 1.5, eyePupil);
    canvas.drawOval(const Rect.fromLTWH(2, -78, 6, 4.5), eyeWhite);
    canvas.drawCircle(const Offset(5, -76), 1.5, eyePupil);

    // Kacamata Persegi Modern Bingkai Putih / Bening Transparan (Sesuai Referensi Asli)
    final clearFrame = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final clearBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final clearLens = Paint()..color = const Color(0x33E0F2FE);

    final leftLens = RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -81, 8.5, 7.5), const Radius.circular(2));
    final rightLens = RRect.fromRectAndRadius(const Rect.fromLTWH(1.5, -81, 8.5, 7.5), const Radius.circular(2));

    canvas.drawRRect(leftLens, clearLens);
    canvas.drawRRect(leftLens, clearFrame);
    canvas.drawRRect(leftLens, clearBorder);

    canvas.drawRRect(rightLens, clearLens);
    canvas.drawRRect(rightLens, clearFrame);
    canvas.drawRRect(rightLens, clearBorder);

    canvas.drawLine(const Offset(-1.5, -77), const Offset(1.5, -77), clearFrame);

    // Syringe Blaster di Tangan
    final syringeBody = Paint()..color = const Color(0xCCF1F5F9);
    final syringeBorder = Paint()..color = const Color(0xFF00A896)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    const tubeRect = Rect.fromLTWH(14, -48, 20, 10);
    canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(2)), syringeBody);
    canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(2)), syringeBorder);

    // Cairan Biru Pendar di dalam tabung
    canvas.drawRect(const Rect.fromLTWH(16, -46, 15, 6), Paint()..color = const Color(0xFF00E5FF));

    // Moncong Jarum
    canvas.drawLine(const Offset(34, -43), const Offset(44, -43), Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 1.8);
    canvas.drawCircle(const Offset(44, -43), 4, Paint()..color = const Color(0xFF00E5FF).withOpacity(0.6));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
