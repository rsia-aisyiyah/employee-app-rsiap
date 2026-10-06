import 'package:flutter/material.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/models/emergency_rush_model.dart';
import 'package:rsia_employee_app/screen/menu/emergency_rush/services/emergency_rush_service.dart';

class EmergencyRushLeaderboardScreen extends StatefulWidget {
  const EmergencyRushLeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyRushLeaderboardScreen> createState() => _EmergencyRushLeaderboardScreenState();
}

class _EmergencyRushLeaderboardScreenState extends State<EmergencyRushLeaderboardScreen> {
  bool _isLoading = true;
  List<EmergencyRushLeaderboardItem> _leaderboard = [];
  EmergencyRushMyStats? _myStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final res = await EmergencyRushService.getLeaderboard(limit: 30);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _leaderboard = res['leaderboard'] ?? [];
        _myStats = res['my_stats'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15191E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E242B),
        elevation: 0,
        title: const Text(
          'Klasemen Ambulans Gesit',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A896)))
          : Column(
              children: [
                // Top podium if we have at least 1 player
                if (_leaderboard.isNotEmpty) _buildPodium(),

                // List of players
                Expanded(
                  child: _leaderboard.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: const Color(0xFF00A896),
                          onRefresh: _loadData,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _leaderboard.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _leaderboard[index];
                              return _buildLeaderboardTile(item);
                            },
                          ),
                        ),
                ),

                // My Stats Sticky Footer
                if (_myStats != null) _buildMyStatsFooter(),
              ],
            ),
    );
  }

  Widget _buildPodium() {
    final top1 = _leaderboard.isNotEmpty ? _leaderboard[0] : null;
    final top2 = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final top3 = _leaderboard.length > 2 ? _leaderboard[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E242B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2
          if (top2 != null) _buildPodiumPillar(top2, rank: 2, height: 95, color: const Color(0xFFB0BEC5)),
          // #1 (Center)
          if (top1 != null) _buildPodiumPillar(top1, rank: 1, height: 125, color: const Color(0xFFFFD54F)),
          // #3
          if (top3 != null) _buildPodiumPillar(top3, rank: 3, height: 80, color: const Color(0xFFFFAB91)),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar(EmergencyRushLeaderboardItem item, {required int rank, required double height, required Color color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle
        Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 26 : 22,
              backgroundColor: color.withOpacity(0.2),
              child: Text(
                item.nama.isNotEmpty ? item.nama.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: rank == 1 ? 18 : 15),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                '$rank',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 85,
          child: Text(
            item.nama,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '${item.highScore} pts',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: height * 0.45,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Center(
            child: Text(
              '${item.maxDistance}m',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(EmergencyRushLeaderboardItem item) {
    final isMe = item.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF00A896).withOpacity(0.15) : const Color(0xFF1E242B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? const Color(0xFF00A896) : Colors.white10,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${item.rank}',
                style: TextStyle(
                  color: item.rank <= 3 ? const Color(0xFFFFD54F) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & Department
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe ? const Color(0xFF00A896) : Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A896),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('ANDA', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.departemen,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ),

          // Score & Distance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.highScore} PTS',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.maxDistance} m • ${item.totalRuns}x main',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_rounded, color: Colors.white.withOpacity(0.3), size: 48),
          const SizedBox(height: 12),
          const Text('Belum ada rekor permainan', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Jadilah pengemudi ambulans pertama!', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMyStatsFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Peringkat Anda', style: TextStyle(color: Colors.white60, fontSize: 11)),
                Text(
                  '#${_myStats!.rank > 0 ? _myStats!.rank : '-'}',
                  style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Skor Tertinggi Anda', style: TextStyle(color: Colors.white60, fontSize: 11)),
                Text(
                  '${_myStats!.highScore} PTS (${_myStats!.maxDistance} m)',
                  style: const TextStyle(color: Color(0xFF00A896), fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
