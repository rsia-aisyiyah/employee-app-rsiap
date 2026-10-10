import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/virus_buster/models/virus_buster_models.dart';
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

  HeroConfig _selectedHero = HeroConfig.heroes.first;
  GameDifficulty _selectedDifficulty = GameDifficulty.medium;

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Ambient Soft Pastel Glow Background
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A896).withValues(alpha: 0.08),
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
                color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF1E293B), size: 18),
                        ),
                      ),

                      // Category Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF00A896).withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                                color: Color(0xFF0F766E),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.medical_services_outlined,
                            color: Color(0xFF0284C7), size: 18),
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
                        // Hero Showpiece Card (Karakter Vector Canvas Preview)
                        _buildHeroShowpiece(),

                        const SizedBox(height: 18),

                        // Section: Pilih Hero Nakes Langsung (7 Profesi)
                        _buildHeroSelectorSection(),

                        const SizedBox(height: 18),

                        // Section: Pilih Mode Tingkat Kesulitan Langsung (Easy, Medium, Hard)
                        _buildDifficultySection(),

                        const SizedBox(height: 20),

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _selectedHero.primaryColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ilustrasi Vector Karakter Hero Preview (Sesuai Nakes Terpilih)
          SizedBox(
            height: 155,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Aura lingkaran belakang sesuai warna khas hero
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _selectedHero.primaryColor.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Vector Hero Preview Sesuai Pakaian Nakes Terpilih (Auto-Scale, Tidak Terpotong)
                CustomPaint(
                  size: const Size(120, 130),
                  painter: _HeroPreviewPainter(heroConfig: _selectedHero),
                ),
              ],
            ),
          ),

          // Teks Judul & Tagline Hero
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              children: [
                const Text(
                  'VIRUS BUSTER',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),

                // Chip Bar: Profesi & Level Kesulitan
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedHero.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedHero.name} • ${_selectedHero.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedDifficulty.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _selectedDifficulty.color),
                      ),
                      child: Text(
                        'Mode: ${_selectedDifficulty.label}',
                        style: TextStyle(
                          color: _selectedDifficulty.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Card Info Spesifikasi Seragam & Skill Hero Aktif
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pakaian Seragam
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.checkroom_rounded,
                              size: 15, color: _selectedHero.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedHero.uniformDesc,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Senjata & Skill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.flash_on_rounded,
                              size: 15, color: _selectedHero.bulletColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedHero.weaponName} • ${_selectedHero.skillName} (${_selectedHero.skillDesc})',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Tombol Ringkas Detail Lengkap Profesi
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _showHeroAndDifficultyModal,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(Icons.info_outline_rounded,
                        size: 14, color: _selectedHero.primaryColor),
                    label: Text(
                      'Lihat Panduan 7 Profesi Lengkap',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _selectedHero.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO SELECTOR SECTION (LANGSUNG DI HOME SCREEN) ───────────────────────
  Widget _buildHeroSelectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _selectedHero.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PILIH HERO NAKES (7 PROFESI)',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _selectedHero.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _selectedHero.primaryColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Ketuk Karakter',
                style: TextStyle(
                  color: _selectedHero.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: HeroConfig.heroes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final hero = HeroConfig.heroes[index];
              final isSelected = hero.profession == _selectedHero.profession;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedHero = hero);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 96,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? hero.primaryColor.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? hero.primaryColor
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? hero.primaryColor.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Mini Vector Karakter Hero Utuh (Auto-Scale, Tidak Terpotong)
                      SizedBox(
                        height: 54,
                        child: CustomPaint(
                          size: const Size(46, 52),
                          painter: _HeroPreviewPainter(heroConfig: hero),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hero.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        hero.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? hero.primaryColor : const Color(0xFF64748B),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Badge Keunggulan Stat
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? hero.primaryColor
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          hero.roleTag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── DIFFICULTY SECTION (LANGSUNG DI HOME SCREEN) ──────────────────────────
  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              'TINGKAT KESULITAN (DIFFICULTY)',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: GameDifficulty.values.map((diff) {
            final isSelected = diff == _selectedDifficulty;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedDifficulty = diff);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? diff.color.withValues(alpha: 0.10)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? diff.color
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? diff.color.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          diff.label,
                          style: TextStyle(
                            color: isSelected ? diff.color : const Color(0xFF334155),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          diff == GameDifficulty.easy
                              ? '4 Nyawa • 0.8x'
                              : (diff == GameDifficulty.medium
                                  ? '3 Nyawa • 1.0x'
                                  : '2 Nyawa • 1.5x'),
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
            color: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBentoTile(
            title: 'STAGE TERTINGGI',
            value: 'Stage $_maxStage',
            icon: Icons.flag_rounded,
            color: const Color(0xFF0284C7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBentoTile(
            title: 'VIRUS DIBASMI',
            value: '$_totalViruses',
            icon: Icons.coronavirus_rounded,
            color: const Color(0xFF16A34A),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
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
            color: _selectedHero.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 11.5,
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
        'color': const Color(0xFF0284C7),
      },
    ];

    return Column(
      children: spots.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (s['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (s['color'] as Color).withValues(alpha: 0.3)),
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
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s['desc'] as String,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_information_rounded, color: Color(0xFF0284C7), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'POWER-UP MEDIS',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 10.5, fontWeight: FontWeight.bold),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.coronavirus_outlined, color: Color(0xFFDC2626), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'TIPE VIRUS',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 10.5, fontWeight: FontWeight.bold),
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
          Text(tag, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 10.5, fontWeight: FontWeight.bold)),
          Text(desc, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5)),
        ],
      ),
    );
  }

  // ─── STICKY BOTTOM LAUNCH BAR ──────────────────────────────────────────────
  Widget _buildBottomLaunchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris info ringkas hero & level saat ini
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedHero.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedHero.name} (${_selectedHero.title}) • Mode: ${_selectedDifficulty.label}',
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Tombol Mulai Misi
          AnimatedBuilder(
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
                          builder: (_) => VirusBusterScreen(
                            heroConfig: _selectedHero,
                            difficulty: _selectedDifficulty,
                          ),
                        ),
                      ).then((_) => _loadStats());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedHero.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: _selectedHero.primaryColor.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'MULAI MISI ${_selectedHero.title.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 13.5,
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
        ],
      ),
    );
  }

  void _showHeroAndDifficultyModal() {
    HeroConfig tempHero = _selectedHero;
    GameDifficulty tempDifficulty = _selectedDifficulty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header Modal
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PERSIAPAN MISI MEDIS',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pilih Profesi Hero Nakes & Tingkat Kesulitan',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFFE2E8F0), height: 1),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── 1. PILIH HERO NAKES (7 PROFESI) ───────────────
                          Row(
                            children: [
                              const Icon(Icons.badge_rounded, color: Color(0xFF00A896), size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'PILIH HERO NAKES (7 PROFESI)',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tempHero.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: tempHero.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  tempHero.title,
                                  style: TextStyle(
                                    color: tempHero.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Horizontal Carousel Hero Nakes
                          SizedBox(
                            height: 124,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: HeroConfig.heroes.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (_, index) {
                                final hero = HeroConfig.heroes[index];
                                final isSelected = hero.profession == tempHero.profession;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() => tempHero = hero);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 95,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? hero.primaryColor.withValues(alpha: 0.08)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? hero.primaryColor
                                            : const Color(0xFFE2E8F0),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? hero.primaryColor.withValues(alpha: 0.15)
                                              : Colors.black.withValues(alpha: 0.03),
                                          blurRadius: isSelected ? 8 : 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Mini Preview Karakter Hero
                                        SizedBox(
                                          height: 52,
                                          child: CustomPaint(
                                            size: const Size(42, 50),
                                            painter: _HeroPreviewPainter(heroConfig: hero),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          hero.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          hero.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected ? hero.primaryColor : const Color(0xFF64748B),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Card Detail Hero Terpilih
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: tempHero.primaryColor.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: tempHero.primaryColor.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.medical_services_rounded,
                                          size: 18, color: tempHero.primaryColor),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${tempHero.name} • ${tempHero.title}',
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            tempHero.roleTag,
                                            style: TextStyle(
                                              color: tempHero.primaryColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tempHero.description,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Divider(color: Color(0xFFE2E8F0), height: 1),
                                const SizedBox(height: 10),

                                // Pakaian Seragam
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.checkroom_rounded,
                                        size: 14, color: tempHero.primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'PAKAIAN & SERAGAM:',
                                            style: TextStyle(
                                              color: tempHero.primaryColor,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Text(
                                            tempHero.uniformDesc,
                                            style: const TextStyle(
                                              color: Color(0xFF334155),
                                              fontSize: 10.5,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Senjata & Skill
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.flash_on_rounded,
                                        size: 14, color: tempHero.bulletColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SENJATA: ${tempHero.weaponName.toUpperCase()}',
                                            style: TextStyle(
                                              color: tempHero.bulletColor,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Text(
                                            '${tempHero.skillName}: ${tempHero.skillDesc}',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 10.5,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ─── 2. PILIH MODE TINGKAT KESULITAN ────────────────
                          const Row(
                            children: [
                              Icon(Icons.speed_rounded, color: Color(0xFF00A896), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'TINGKAT KESULITAN (DIFFICULTY)',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: GameDifficulty.values.map((diff) {
                              final isSelected = diff == tempDifficulty;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() => tempDifficulty = diff);
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? diff.color.withValues(alpha: 0.10)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected
                                              ? diff.color
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? diff.color.withValues(alpha: 0.15)
                                                : Colors.black.withValues(alpha: 0.03),
                                            blurRadius: isSelected ? 8 : 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            diff.label,
                                            style: TextStyle(
                                              color: isSelected ? diff.color : const Color(0xFF334155),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            diff == GameDifficulty.easy
                                                ? 'Ekstra Nyawa'
                                                : (diff == GameDifficulty.medium
                                                    ? 'Standar'
                                                    : 'Skor x1.5!'),
                                            style: TextStyle(
                                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 10),

                          // Keterangan detail difficulty terpilih
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: tempDifficulty.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: tempDifficulty.color.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 14, color: tempDifficulty.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tempDifficulty.subtitle,
                                    style: TextStyle(
                                      color: tempDifficulty.color,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button di Modal
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedHero = tempHero;
                            _selectedDifficulty = tempDifficulty;
                          });
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VirusBusterScreen(
                                heroConfig: _selectedHero,
                                difficulty: _selectedDifficulty,
                              ),
                            ),
                          ).then((_) => _loadStats());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tempHero.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: tempHero.primaryColor.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rocket_launch_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'LUNCURKAN OPERASI (${tempHero.title.toUpperCase()})',
                              style: const TextStyle(
                                fontSize: 13,
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
            );
          },
        );
      },
    );
  }
}

/// CustomPainter untuk menggambar preview karakter heroik di lobby & selection modal
class _HeroPreviewPainter extends CustomPainter {
  final HeroConfig heroConfig;

  const _HeroPreviewPainter({required this.heroConfig});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();

    // Bounds virtual karakter:
    // Left = -22.0, Right = 50.0 (width = 72.0)
    // Top = -96.0, Bottom = 4.0 (height = 100.0)
    // Sumbu visual tengah: X = 6.0, Y = -46.0
    final double scale = min(size.width / 74.0, size.height / 102.0) * 0.92;
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Posisi tepat di tengah canvas secara proporsional dan tidak terpotong
    canvas.translate(cx - (6.0 * scale), cy - (-46.0 * scale));
    canvas.scale(scale);

    // Kaki & Celana Sesuai Hero
    final pantsPaint = Paint()..color = heroConfig.pantsColor;
    final shoesPaint = Paint()..color = heroConfig.shoesColor;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -22, 10, 22), const Radius.circular(3)), pantsPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, -22, 10, 22), const Radius.circular(3)), pantsPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -4, 12, 6), const Radius.circular(2)), shoesPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, -4, 12, 6), const Radius.circular(2)), shoesPaint);

    // Jas / Pakaian Seragam Hero
    final coatPaint = Paint()..color = heroConfig.coatColor;
    final coatBorder = Paint()
      ..color = heroConfig.coatBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final coatRect = RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -60, 32, 41), const Radius.circular(5));
    canvas.drawRRect(coatRect, coatPaint);

    // Shading Samping Jas/Baju
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -60, 5, 41), const Radius.circular(3)),
      Paint()..color = heroConfig.coatShadeColor,
    );
    canvas.drawRRect(coatRect, coatBorder);

    // Kemeja / Lapisan Dalam Sesuai Seragam
    final shirtPaint = Paint()..color = heroConfig.shirtColor;
    canvas.drawRect(const Rect.fromLTWH(-6, -60, 12, 14), shirtPaint);

    // Aksen Dada Khas Seragam Masing-Masing Hero
    if (heroConfig.hasTie) {
      final tiePaint = Paint()..color = heroConfig.accentColor;
      final tiePath = Path();
      tiePath.moveTo(0, -60);
      tiePath.lineTo(-3, -48);
      tiePath.lineTo(0, -42);
      tiePath.lineTo(3, -48);
      tiePath.close();
      canvas.drawPath(tiePath, tiePaint);
    } else if (heroConfig.hasLeadApron) {
      // Simbol Radiasi Trefoil Emas-Kuning di Dada Lead Apron
      final emblemPaint = Paint()..color = const Color(0xFFFACC15);
      final center = const Offset(0, -48);
      canvas.drawCircle(center, 3.2, emblemPaint);
      canvas.drawCircle(center, 1.2, Paint()..color = const Color(0xFF1E293B));
      for (int i = 0; i < 3; i++) {
        final angle = (i * 120 - 90) * 3.14159 / 180;
        final wingX = center.dx + cos(angle) * 4.8;
        final wingY = center.dy + sin(angle) * 4.8;
        canvas.drawCircle(Offset(wingX, wingY), 1.8, emblemPaint);
      }
    } else if (heroConfig.profession == HeroProfession.bidan) {
      // Lencana Bidan Delima Emas di Dada
      final broochPaint = Paint()..color = const Color(0xFFF59E0B);
      final center = const Offset(0, -48);
      canvas.drawCircle(center, 3.8, broochPaint);
      canvas.drawCircle(center, 2.0, Paint()..color = const Color(0xFFBE185D));
    } else if (heroConfig.profession == HeroProfession.gizi) {
      // Pin Apel Sehat Merah dengan Daun Hijau
      final applePaint = Paint()..color = const Color(0xFFEF4444);
      final center = const Offset(0, -48);
      canvas.drawCircle(center, 3.5, applePaint);
      canvas.drawCircle(Offset(center.dx + 1.5, center.dy - 3.5), 1.4, Paint()..color = const Color(0xFF10B981));
    } else if (heroConfig.profession == HeroProfession.farmasi) {
      // Pin Mortar & Pestle Farmasi Emas
      final mortarPaint = Paint()..color = const Color(0xFFF59E0B);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -51, 6, 5), const Radius.circular(1.5)),
        mortarPaint,
      );
      canvas.drawLine(const Offset(-2, -52), const Offset(2, -47), Paint()..color = Colors.white..strokeWidth = 1.0);
    } else if (heroConfig.isScrubSuit) {
      // Kerah V-neck Scrub Toska
      final vneckPaint = Paint()
        ..color = heroConfig.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      final vPath = Path();
      vPath.moveTo(-6, -60);
      vPath.lineTo(0, -47);
      vPath.lineTo(6, -60);
      canvas.drawPath(vPath, vneckPaint);
    }

    // Kerah Lapel Jas (Jika bukan scrub)
    if (!heroConfig.isScrubSuit) {
      final lapelPaint = Paint()..color = heroConfig.coatShadeColor;
      final lapelStroke = Paint()
        ..color = heroConfig.coatBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      // Lapel Kiri
      final lapelLeft = Path();
      lapelLeft.moveTo(-15, -60);
      lapelLeft.lineTo(-6, -46);
      lapelLeft.lineTo(-10, -42);
      lapelLeft.lineTo(-15, -48);
      lapelLeft.close();
      canvas.drawPath(lapelLeft, lapelPaint);
      canvas.drawPath(lapelLeft, lapelStroke);

      // Lapel Kanan
      final lapelRight = Path();
      lapelRight.moveTo(15, -60);
      lapelRight.lineTo(6, -46);
      lapelRight.lineTo(10, -42);
      lapelRight.lineTo(15, -48);
      lapelRight.close();
      canvas.drawPath(lapelRight, lapelPaint);
      canvas.drawPath(lapelRight, lapelStroke);

      // Garis Tengah Bukaan Jas & Kancing Mutiara
      canvas.drawLine(const Offset(0, -42), const Offset(0, -20), Paint()..color = heroConfig.coatBorderColor..strokeWidth = 1.2);
      for (final btnY in [-36.0, -28.0, -21.0]) {
        canvas.drawCircle(Offset(0, btnY), 1.6, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(0, btnY), 1.6, Paint()..color = heroConfig.coatBorderColor..style = PaintingStyle.stroke..strokeWidth = 0.8);
      }
    }

    // Saku Dada Kiri (Breast Pocket) & Pena Medis
    final pocketRect = const Rect.fromLTWH(-13, -44, 6.5, 7);
    canvas.drawRRect(RRect.fromRectAndRadius(pocketRect, const Radius.circular(1)), Paint()..color = heroConfig.coatShadeColor);
    canvas.drawRRect(RRect.fromRectAndRadius(pocketRect, const Radius.circular(1)), Paint()..color = heroConfig.coatBorderColor..style = PaintingStyle.stroke..strokeWidth = 0.9);
    canvas.drawLine(const Offset(-11.5, -46.5), const Offset(-11.5, -42), Paint()..color = const Color(0xFFEF4444)..strokeWidth = 1.3);
    canvas.drawLine(const Offset(-8.5, -46.5), const Offset(-8.5, -42), Paint()..color = heroConfig.primaryColor..strokeWidth = 1.3);

    // Kartu ID Card RSIA Gantung di Dada
    final badgeRect = RRect.fromRectAndRadius(const Rect.fromLTWH(-12.5, -36, 5, 6), const Radius.circular(1));
    canvas.drawLine(const Offset(-10, -40), const Offset(-10, -36), Paint()..color = heroConfig.primaryColor..strokeWidth = 0.9);
    canvas.drawRRect(badgeRect, Paint()..color = Colors.white);
    canvas.drawRRect(badgeRect, Paint()..color = heroConfig.primaryColor..style = PaintingStyle.stroke..strokeWidth = 0.6);
    canvas.drawRect(const Rect.fromLTWH(-12, -35.5, 4, 1.2), Paint()..color = heroConfig.primaryColor);

    // Saku Samping Jas Pinggang Kiri & Kanan
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -26, 6, 4), const Radius.circular(1)), Paint()..color = heroConfig.coatBorderColor..style = PaintingStyle.stroke..strokeWidth = 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, -26, 6, 4), const Radius.circular(1)), Paint()..color = heroConfig.coatBorderColor..style = PaintingStyle.stroke..strokeWidth = 0.8);

    // ── STETOSKOP MEDIS (Khusus Profesi Tertentu) ────────────────────
    if (heroConfig.hasStethoscope) {
      final stethoColor = heroConfig.profession == HeroProfession.perawat
          ? const Color(0xFF0F766E)
          : const Color(0xFF0F172A);
      final stethoTubeOuter = Paint()
        ..color = stethoColor
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final stethoTubeInner = Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final stethoPath = Path();
      stethoPath.moveTo(-11, -60);
      stethoPath.cubicTo(-13, -48, 5, -46, 5, -40);
      canvas.drawPath(stethoPath, stethoTubeOuter);
      canvas.drawPath(stethoPath, stethoTubeInner);

      // Diafragma Perak Mengkilap di Tengah Dada
      final stethoHead = const Offset(5, -39);
      canvas.drawCircle(stethoHead, 4.2, Paint()..color = const Color(0xFF334155));
      canvas.drawCircle(stethoHead, 3.5, Paint()..color = const Color(0xFFE2E8F0));
      canvas.drawCircle(stethoHead, 1.8, Paint()..color = Colors.white);
    }

    // ── LENGAN KIRI (Menyamping di Pinggang) ─────────────────────────
    final leftArm = Path();
    leftArm.moveTo(-15, -57);
    leftArm.lineTo(-20, -42);
    leftArm.lineTo(-16, -30);
    leftArm.lineTo(-12, -32);
    leftArm.lineTo(-15, -44);
    leftArm.close();
    canvas.drawPath(leftArm, Paint()..color = heroConfig.coatColor);
    canvas.drawPath(leftArm, Paint()..color = heroConfig.coatBorderColor..style = PaintingStyle.stroke..strokeWidth = 1.0);
    // Sarung tangan medis kiri di pinggang
    canvas.drawCircle(const Offset(-14, -28), 3.2, Paint()..color = heroConfig.gloveColor);

    // ── LENGAN KANAN & KEDUA TANGAN MEMEGANG SENJATA ────────────────
    final rightArm = Path();
    rightArm.moveTo(15, -57);
    rightArm.lineTo(21, -47);
    rightArm.lineTo(16, -38);
    rightArm.lineTo(12, -43);
    rightArm.lineTo(14, -50);
    rightArm.close();
    canvas.drawPath(rightArm, Paint()..color = heroConfig.coatColor);
    canvas.drawPath(rightArm, Paint()..color = heroConfig.coatBorderColor..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Manset Baju Kanan & Sarung Tangan
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(13, -40, 5, 4), const Radius.circular(1.5)),
      Paint()..color = heroConfig.gloveColor,
    );

    // Gagang Pistol Blaster
    final gripPath = Path();
    gripPath.moveTo(18, -38);
    gripPath.lineTo(22, -38);
    gripPath.lineTo(21, -29);
    gripPath.lineTo(17, -29);
    gripPath.close();
    canvas.drawPath(gripPath, Paint()..color = heroConfig.primaryColor);
    canvas.drawPath(gripPath, Paint()..color = heroConfig.accentColor..style = PaintingStyle.stroke..strokeWidth = 0.8);

    // Jari-jari Tangan Kanan Menggenggam Grip
    for (int i = 0; i < 3; i++) {
      final fy = -36.5 + (i * 2.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(18, fy, 4.5, 2.0), const Radius.circular(1)),
        Paint()..color = heroConfig.gloveColor,
      );
    }
    // Jari telunjuk di pelatuk
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(21, -39, 3.5, 2.0), const Radius.circular(1)),
      Paint()..color = Color.lerp(heroConfig.gloveColor, Colors.white, 0.45)!,
    );

    // ── BLASTER WEAPON DETAIL ───────────────────────────────────────
    const tubeRect = Rect.fromLTWH(14, -48, 20, 10);
    final tubeRRect = RRect.fromRectAndRadius(tubeRect, const Radius.circular(2.5));
    canvas.drawRRect(tubeRRect, Paint()..color = const Color(0x33FFFFFF));
    canvas.drawRRect(tubeRRect, Paint()..color = heroConfig.primaryColor..style = PaintingStyle.stroke..strokeWidth = 1.3);

    // Cairan / Energi Berpendar
    final fluidRect = const Rect.fromLTWH(16, -46, 15, 6);
    canvas.drawRRect(RRect.fromRectAndRadius(fluidRect, const Radius.circular(1.5)), Paint()..color = heroConfig.bulletColor);
    canvas.drawLine(const Offset(17, -44.5), const Offset(29, -44.5), Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 1.0);

    // Skala Garis di Tabung
    for (int t = 0; t < 3; t++) {
      final tx = 19.0 + (t * 3.5);
      canvas.drawLine(Offset(tx, -43), Offset(tx, -41), Paint()..color = Colors.white.withValues(alpha: 0.9)..strokeWidth = 0.8);
    }

    // Piston Plunger Belakang
    canvas.drawLine(const Offset(10, -43), const Offset(14, -43), Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 2.0);
    canvas.drawCircle(const Offset(8, -43), 2.5, Paint()..color = heroConfig.primaryColor);

    // Moncong Nozzle & Jarum Perak
    canvas.drawRect(const Rect.fromLTWH(34, -45.5, 3.5, 5), Paint()..color = heroConfig.primaryColor);
    canvas.drawLine(const Offset(37.5, -43), const Offset(46, -43), Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1.8);
    canvas.drawCircle(const Offset(46, -43), 4, Paint()..color = heroConfig.bulletColor.withValues(alpha: 0.75));
    canvas.drawCircle(const Offset(46, -43), 1.5, Paint()..color = Colors.white);

    // ── KEPALA, WAJAH & JILBAB / RAMBUT HERO ─────────────────────────
    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);

    if (heroConfig.hasHeadCover) {
      // ── HIJAB / KERUDUNG BERGO MEDIS MUSLIMAH (Bidan Amanda, Analis Maya, Nutrisionis Nurul) ──
      final hijabPaint = Paint()..color = heroConfig.effectiveHeadCoverColor;
      final hijabBorder = Paint()
        ..color = heroConfig.effectiveHeadCoverBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;

      // 1. Tudung Hijab Melingkupi Kepala & Menjuntai Anggun ke Dada (Drapery)
      final hijabBase = Path();
      hijabBase.moveTo(-16, -60); // bahu kiri
      hijabBase.lineTo(-16, -83);
      hijabBase.quadraticBezierTo(-15, -95, 0, -96); // puncak kepala melengkung halus
      hijabBase.quadraticBezierTo(15, -95, 16, -83);
      hijabBase.lineTo(16, -60); // bahu kanan
      // Menjuntai ke dada bawah membentuk lekukan bergo
      hijabBase.quadraticBezierTo(9, -52, 0, -51);
      hijabBase.quadraticBezierTo(-9, -52, -16, -60);
      hijabBase.close();
      canvas.drawPath(hijabBase, hijabPaint);
      canvas.drawPath(hijabBase, hijabBorder);

      // Shading lembut di sisi kiri hijab
      final hijabShade = Path();
      hijabShade.moveTo(-16, -60);
      hijabShade.lineTo(-16, -83);
      hijabShade.quadraticBezierTo(-15, -95, 0, -96);
      hijabShade.quadraticBezierTo(-8, -94, -10, -82);
      hijabShade.lineTo(-10, -60);
      hijabShade.close();
      canvas.drawPath(hijabShade, Paint()..color = heroConfig.effectiveHeadCoverShadeColor.withValues(alpha: 0.4));

      // 2. Bukaan Wajah Oval Terbuka Penuh (Dahi, Pipi, Dagu & Senyum Manis Terlihat Jelas)
      final faceOpening = Path();
      faceOpening.moveTo(0, -84); // dahi atas
      faceOpening.cubicTo(9.5, -84, 10.5, -73, 7.5, -66); // pelipis & pipi kanan
      faceOpening.quadraticBezierTo(0, -62.5, -7.5, -66); // dagu bawah melengkung manis
      faceOpening.cubicTo(-10.5, -73, -9.5, -84, 0, -84); // pipi kiri ke dahi
      faceOpening.close();
      canvas.drawPath(faceOpening, skinPaint);

      // Garis bingkai bukaan jilbab di sekeliling wajah
      canvas.drawPath(faceOpening, hijabBorder);

      // 3. Inner Ciput / Lis Bergo di Dahi Atas
      final ciputPaint = Paint()
        ..color = heroConfig.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      final ciputPath = Path();
      ciputPath.moveTo(-8.0, -80.5);
      ciputPath.quadraticBezierTo(0, -84.0, 8.0, -80.5);
      canvas.drawPath(ciputPath, ciputPaint);

      // 4. Mata Binar Cantik Nakes Muslimah
      final eyeWhite = Paint()..color = Colors.white;
      final eyePupil = Paint()..color = const Color(0xFF0F172A);
      // Mata Kiri
      canvas.drawOval(const Rect.fromLTWH(-7.5, -77, 5.5, 4.5), eyeWhite);
      canvas.drawCircle(const Offset(-4.8, -75), 1.5, eyePupil);
      canvas.drawCircle(const Offset(-4.2, -75.6), 0.6, Paint()..color = Colors.white);
      // Bulu mata kiri
      canvas.drawLine(const Offset(-7.5, -77), const Offset(-5, -78.5), Paint()..color = const Color(0xFF0F172A)..strokeWidth = 1.0);
      // Mata Kanan
      canvas.drawOval(const Rect.fromLTWH(2.0, -77, 5.5, 4.5), eyeWhite);
      canvas.drawCircle(const Offset(4.8, -75), 1.5, eyePupil);
      canvas.drawCircle(const Offset(5.4, -75.6), 0.6, Paint()..color = Colors.white);
      // Bulu mata kanan
      canvas.drawLine(const Offset(7.5, -77), const Offset(5, -78.5), Paint()..color = const Color(0xFF0F172A)..strokeWidth = 1.0);

      // 5. Pipi Merona Blush Pink Lembut
      final blushPaint = Paint()..color = const Color(0x66F472B6);
      canvas.drawCircle(const Offset(-6.0, -69.5), 2.2, blushPaint);
      canvas.drawCircle(const Offset(6.0, -69.5), 2.2, blushPaint);

      // 6. Hidung Kecil & Senyum Ramah Nakes Muslimah
      canvas.drawCircle(const Offset(0, -70), 0.8, Paint()..color = const Color(0xFFE2A882));
      final smilePaint = Paint()
        ..color = const Color(0xFFE11D48)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.2;
      final smilePath = Path();
      smilePath.moveTo(-2.8, -66.5);
      smilePath.quadraticBezierTo(0, -64.5, 2.8, -66.5);
      canvas.drawPath(smilePath, smilePaint);

      // 7. Lipatan Bergo Kain Jilbab di Bawah Dagu
      final foldPaint = Paint()
        ..color = heroConfig.effectiveHeadCoverBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      final foldPath = Path();
      foldPath.moveTo(0, -62.5);
      foldPath.quadraticBezierTo(-3.5, -57, -6, -54);
      canvas.drawPath(foldPath, foldPaint);
      final foldPath2 = Path();
      foldPath2.moveTo(0, -62.5);
      foldPath2.quadraticBezierTo(3.5, -57, 6, -54);
      canvas.drawPath(foldPath2, foldPaint);

      // Bros Khusus Kebidanan di Bawah Dagu (Hanya untuk Bidan)
      if (heroConfig.profession == HeroProfession.bidan) {
        final broochCenter = const Offset(0, -52);
        canvas.drawCircle(broochCenter, 3.2, Paint()..color = const Color(0xFFF59E0B));
        canvas.drawCircle(broochCenter, 1.8, Paint()..color = const Color(0xFFBE185D));
      }
    } else {
      // ── KEPALA KARAKTER STANDAR (PRIA / TANPA HEADCOVER) ──────────────
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -84, 24, 20), const Radius.circular(7)),
        skinPaint,
      );

      // Rambut Hitam Rapi Belah Samping
      final hairPaint = Paint()..color = heroConfig.hairColor;
      final hairPath = Path();
      hairPath.moveTo(-13, -78);
      hairPath.lineTo(-13, -88);
      hairPath.quadraticBezierTo(0, -92, 13, -88);
      hairPath.lineTo(13, -78);
      hairPath.lineTo(11, -81);
      hairPath.quadraticBezierTo(0, -83, -11, -81);
      hairPath.close();
      canvas.drawPath(hairPath, hairPaint);

      // Mata Karakter Pria
      final eyeWhite = Paint()..color = Colors.white;
      final eyePupil = Paint()..color = const Color(0xFF0F172A);
      canvas.drawOval(const Rect.fromLTWH(-8, -78, 6, 4.5), eyeWhite);
      canvas.drawCircle(const Offset(-5, -76), 1.5, eyePupil);
      canvas.drawOval(const Rect.fromLTWH(2, -78, 6, 4.5), eyeWhite);
      canvas.drawCircle(const Offset(5, -76), 1.5, eyePupil);
    }

    // Kacamata (Jika Hero Memakai Kacamata)
    if (heroConfig.hasGlasses) {
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
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeroPreviewPainter oldDelegate) =>
      oldDelegate.heroConfig != heroConfig;
}
