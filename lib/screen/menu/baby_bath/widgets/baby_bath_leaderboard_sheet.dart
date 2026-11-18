import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rsia_employee_app/api/request.dart';

/// Modal BottomSheet Papan Peringkat (Leaderboard) & Statistik Mandi Bayi RSIA
class BabyBathLeaderboardSheet extends StatefulWidget {
  const BabyBathLeaderboardSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BabyBathLeaderboardSheet(),
    );
  }

  @override
  State<BabyBathLeaderboardSheet> createState() => _BabyBathLeaderboardSheetState();
}

class _BabyBathLeaderboardSheetState extends State<BabyBathLeaderboardSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _leaderboard = [];
  Map<String, dynamic>? _myStats;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resLeaderboard = await Api().getData('/game/baby-bath/leaderboard');
      final resMyStats = await Api().getData('/game/baby-bath/my-stats');

      if (resLeaderboard.statusCode == 200) {
        final bodyLeaderboard = jsonDecode(resLeaderboard.body);
        if (bodyLeaderboard['success'] == true && bodyLeaderboard['data'] != null) {
          final data = bodyLeaderboard['data'];
          if (data is List) {
            _leaderboard = data;
          } else if (data is Map && data['leaderboard'] is List) {
            _leaderboard = data['leaderboard'];
          }
        }
      } else {
        _errorMessage = "Gagal memuat papan peringkat (${resLeaderboard.statusCode})";
      }

      if (resMyStats.statusCode == 200) {
        final bodyMyStats = jsonDecode(resMyStats.body);
        if (bodyMyStats['success'] == true && bodyMyStats['data'] is Map<String, dynamic>) {
          _myStats = bodyMyStats['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching baby bath leaderboard: $e");
      _errorMessage = "Gagal memuat papan peringkat. Pastikan koneksi internet stabil.";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Papan Peringkat Mandi Bayi",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        "Top Perawat & Bidan Berdasarkan Ketepatan SOP",
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),

          const Divider(height: 20),

          // Konten Utama
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Coba Lagi"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: const Color(0xFF0284C7),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          children: [
                            // Kartu Rekor Saya
                            if (_myStats != null) _buildMyStatsCard(),

                            const SizedBox(height: 16),

                            Text(
                              "Peringkat Shift Perinatologi",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (_leaderboard.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Icon(Icons.military_tech_outlined, size: 44, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Belum ada data shift mandi bayi.\nJadilah yang pertama bermain!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...List.generate(_leaderboard.length, (index) {
                                final item = _leaderboard[index];
                                return _buildLeaderboardTile(index + 1, item);
                              }),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatsCard() {
    final highScore = _myStats?['high_score'] ?? 0;
    final totalBabies = _myStats?['total_babies'] ?? _myStats?['total_babies_bathed'] ?? 0;
    final gamesPlayed = _myStats?['total_shifts'] ?? _myStats?['total_games_played'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_rounded, size: 16, color: Colors.white70),
              SizedBox(width: 6),
              Text(
                "Rekor Pribadi Anda",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem("High Score", "$highScore", Icons.star_rounded),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _buildStatItem("Bayi Selesai", "$totalBabies", Icons.child_care_rounded),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _buildStatItem("Shift Selesai", "$gamesPlayed", Icons.timer_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFFDE047)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(int rank, dynamic item) {
    Color rankColor = const Color(0xFF64748B);
    Color? badgeBg;

    if (rank == 1) {
      rankColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
    } else if (rank == 2) {
      rankColor = const Color(0xFF475569);
      badgeBg = const Color(0xFFE2E8F0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFB45309);
      badgeBg = const Color(0xFFFFEDD5);
    }

    final pegawai = item['pegawai'] ?? {};
    final nama = item['nama'] ?? pegawai['nama'] ?? item['nik'] ?? 'Pegawai RSIA';
    final jabatan = item['jabatan'] ?? pegawai['jbtn'] ?? 'Unit Perinatologi';
    final score = item['high_score'] ?? item['score'] ?? 0;
    final babies = item['max_babies'] ?? item['total_babies_bathed'] ?? item['completed_babies'] ?? 0;
    final stars = item['stars'] ?? (score >= 2000 ? 3 : (score >= 1500 ? 2 : 1));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: rank <= 3 ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank <= 3 ? const Color(0xFFBAE6FD) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: badgeBg ?? Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$rank",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail Pegawai
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      jabatan,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "• 👶 $babies bayi",
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Skor & Bintang
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$score",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0284C7),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(stars, (index) {
                  return const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24));
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
