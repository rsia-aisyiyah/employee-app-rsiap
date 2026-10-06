import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/tts/models/tts_model.dart';
import 'package:rsia_employee_app/screen/menu/tts/services/tts_service.dart';

class TtsLeaderboardScreen extends StatefulWidget {
  const TtsLeaderboardScreen({super.key});

  @override
  State<TtsLeaderboardScreen> createState() => _TtsLeaderboardScreenState();
}

class _TtsLeaderboardScreenState extends State<TtsLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _myRankData;

  List<TtsPlayerScore> _topPlayers = [];
  List<Map<String, dynamic>> _topDepartments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    final data = await TtsService.getLeaderboard();

    if (mounted) {
      setState(() {
        if (data != null && data['top_players'] is List) {
          _topPlayers = (data['top_players'] as List).map((p) {
            return TtsPlayerScore(
              name: p['name'] ?? '',
              department: p['department'] ?? 'Umum',
              avatar: p['photo'],
              timeSeconds: p['time_seconds'] ?? 0,
              score: p['score'] ?? 0,
              playedAt: DateTime.now(),
            );
          }).toList();
        } else {
          _topPlayers = [];
        }

        if (data != null && data['top_departments'] is List) {
          final deptColors = [
            const Color(0xFF0D9488),
            const Color(0xFFDC2626),
            const Color(0xFFE11D48),
            const Color(0xFF2563EB),
            const Color(0xFF7C3AED),
            const Color(0xFF0284C7),
          ];

          _topDepartments = (data['top_departments'] as List).asMap().entries.map((entry) {
            int idx = entry.key;
            var d = entry.value;
            return {
              'department': d['department'] ?? '',
              'avgTime': d['avg_time'] ?? '00:00',
              'totalParticipants': d['total_participants'] ?? 0,
              'score': d['score'] ?? 0,
              'color': deptColors[idx % deptColors.length],
            };
          }).toList();
        } else {
          _topDepartments = [];
        }

        _myRankData = data != null ? data['my_rank'] : null;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Papan Peringkat TTS',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
            onPressed: _loadLeaderboard,
            tooltip: 'Segarkan',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0284C7),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: const [
            Tab(text: '👤 Top Karyawan'),
            Tab(text: '🏢 Peringkat Unit'),
          ],
        ),
      ),
      body: _isLoading && _topPlayers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(onRefresh: _loadLeaderboard, child: _buildPlayersTab()),
                RefreshIndicator(onRefresh: _loadLeaderboard, child: _buildDepartmentsTab()),
              ],
            ),
      bottomNavigationBar: _buildMyRankBottomBar(),
    );
  }

  Widget _buildPlayersTab() {
    if (_topPlayers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Belum Ada Rekor Nilai',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada pegawai yang menyelesaikan soal TTS di database. Selesaikan level TTS dan jadilah juara pertama!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_topPlayers.length < 3) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _topPlayers.length,
        itemBuilder: (context, index) {
          final p = _topPlayers[index];
          int rank = index + 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rank == 1 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: rank == 1 ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  child: Text(
                    rank == 1 ? '🥇' : '🥈',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 14),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    p.name.isNotEmpty ? p.name[0] : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.department,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.formattedTime,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.score} Poin',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    final p1 = _topPlayers[0];
    final p2 = _topPlayers[1];
    final p3 = _topPlayers[2];
    final runnersUp = _topPlayers.length > 3 ? _topPlayers.sublist(3) : <TtsPlayerScore>[];

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        // ── Top 3 Podium ──
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF3BC8ED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                '🏆 PODIUM JUARA RSIA 🏆',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Rank 2 (Left)
                  _buildPodiumStep(
                    rank: 2,
                    player: p2,
                    podiumHeight: 90,
                    badgeColor: const Color(0xFFCBD5E1),
                    badgeIcon: '🥈',
                  ),

                  // Rank 1 (Center)
                  _buildPodiumStep(
                    rank: 1,
                    player: p1,
                    podiumHeight: 120,
                    badgeColor: const Color(0xFFFDE047),
                    badgeIcon: '👑',
                    isFirst: true,
                  ),

                  // Rank 3 (Right)
                  _buildPodiumStep(
                    rank: 3,
                    player: p3,
                    podiumHeight: 70,
                    badgeColor: const Color(0xFFFDBA74),
                    badgeIcon: '🥉',
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Runner Up Section Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Peringkat Selanjutnya',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              Text(
                '${_topPlayers.length} Peserta',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),

        // ── Runners-Up List ──
        ...runnersUp.asMap().entries.map((entry) {
          int rank = entry.key + 4;
          TtsPlayerScore p = entry.value;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Rank Circle
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Avatar / Initials
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDFF8FF),
                  child: Text(
                    p.name.isNotEmpty ? p.name[0] : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Department
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        p.department,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time & Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.formattedTime,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.score} Poin',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPodiumStep({
    required int rank,
    required TtsPlayerScore player,
    required double podiumHeight,
    required Color badgeColor,
    required String badgeIcon,
    bool isFirst = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown or Badge
        Text(badgeIcon, style: TextStyle(fontSize: isFirst ? 24 : 18)),
        const SizedBox(height: 4),

        // Avatar
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: badgeColor, width: 2),
              ),
              child: CircleAvatar(
                radius: isFirst ? 26 : 21,
                backgroundColor: Colors.white,
                child: Text(
                  player.name.isNotEmpty ? player.name[0] : '?',
                  style: TextStyle(
                    fontSize: isFirst ? 18 : 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Name
        SizedBox(
          width: isFirst ? 95 : 80,
          child: Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Time
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            player.formattedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Podium Pillar
        Container(
          width: isFirst ? 76 : 64,
          height: podiumHeight,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isFirst ? 0.28 : 0.18),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Text(
            '#$rank',
            style: TextStyle(
              fontSize: isFirst ? 22 : 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentsTab() {
    if (_topDepartments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_rounded,
                  size: 48,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Belum Ada Partisipasi Unit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada unit/departemen yang tercatat. Selesaikan level TTS agar unit Anda muncul di peringkat!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Peringkat unit dihitung dari total partisipasi aktif staf dan rata-rata kecepatan pengerjaan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade900,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._topDepartments.asMap().entries.map((entry) {
          int rank = entry.key + 1;
          var dept = entry.value;
          Color deptColor = dept['color'];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? const Color(0xFFFEF3C7)
                        : (rank == 2 ? const Color(0xFFF1F5F9) : const Color(0xFFFFF7ED)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: rank == 1
                          ? const Color(0xFFF59E0B)
                          : (rank == 2 ? const Color(0xFF94A3B8) : const Color(0xFFEA580C)),
                    ),
                  ),
                  child: Text(
                    rank == 1 ? '🥇' : (rank == 2 ? '🥈' : (rank == 3 ? '🥉' : '#$rank')),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 14),

                // Department Name & Participants
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept['department'],
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${dept['totalParticipants']} Staf Berpartisipasi',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),

                // Avg Time & Points
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF0284C7)),
                        const SizedBox(width: 3),
                        Text(
                          dept['avgTime'],
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dept['score']} Pts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: deptColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMyRankBottomBar() {
    String rankStr = 'Belum Ada Rekor';
    String timeStr = 'Selesaikan level untuk masuk peringkat';

    if (_myRankData != null) {
      rankStr = '#${_myRankData!['rank']}';
      int t = _myRankData!['time_seconds'] ?? 0;
      int m = t ~/ 60;
      int s = t % 60;
      timeStr = 'Waktu terbaik: ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(color: const Color(0xFF3BC8ED).withOpacity(0.3)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star_rounded, color: Color(0xFF0284C7), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _myRankData != null ? 'Peringkat Anda: $rankStr' : 'Peringkat Anda: Belum Ada Rekor',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    _myRankData != null ? timeStr : 'Selesaikan level untuk masuk peringkat',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3BC8ED),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _myRankData != null ? 'Main Lagi' : 'Main Sekarang',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
