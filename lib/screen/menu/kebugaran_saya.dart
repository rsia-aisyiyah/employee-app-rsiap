import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/services/health_service.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class KebugaranSayaScreen extends StatefulWidget {
  const KebugaranSayaScreen({super.key});

  @override
  State<KebugaranSayaScreen> createState() => _KebugaranSayaScreenState();
}

class _KebugaranSayaScreenState extends State<KebugaranSayaScreen> with SingleTickerProviderStateMixin {
  final box = GetStorage();
  late TabController _tabController;
  bool isLoading = true;
  bool isSyncing = false;

  Map todayData = {};
  Map monthlyStats = {};
  List weeklyTrend = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHealthData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthData() async {
    setState(() {
      isLoading = true;
    });

    final nik = box.read('sub');
    try {
      var summaryRes = await Api().getData('/sdi/health/summary?nik=$nik');
      if (summaryRes.statusCode == 200) {
        var body = json.decode(summaryRes.body);
        if (body['success'] == true && body['message'] != null) {
          var data = body['message'];
          setState(() {
            todayData = data['today'] ?? {};
            monthlyStats = data['monthly_stats'] ?? {};
            weeklyTrend = data['weekly_trend'] ?? [];
          });
        }
      }
    } catch (e) {
      print("ERROR HEALTH DATA: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _triggerManualSync() async {
    setState(() {
      isSyncing = true;
    });

    final nik = box.read('sub');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Fetch real metrics from Apple Health / Google Health Connect
    Map<String, dynamic> realHealth = await HealthService.fetchTodayHealthData();
    realHealth['tanggal'] = today;

    final syncPayload = {
      'nik': nik,
      'platform': Theme.of(context).platform == TargetPlatform.iOS ? 'iOS' : 'Android',
      'device_name': realHealth['sumber_device'] ?? 'Smartwatch',
      'logs': [realHealth]
    };

    try {
      var res = await Api().postData(syncPayload, '/sdi/health/sync');
      if (res.statusCode == 200) {
        if (mounted) {
          int steps = realHealth['jumlah_langkah'] ?? 0;
          String logInfo = realHealth['status_log'] ?? '';
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Row(
                children: [
                  Icon(Icons.health_and_safety, color: Colors.teal),
                  SizedBox(width: 8),
                  Text("Status Sync Sensor", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Langkah Terbaca: $steps langkah", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("Sumber: ${realHealth['sumber_device']}"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    child: Text(logInfo.isEmpty ? "Tidak ada catatan error." : logInfo, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tutup")),
              ],
            ),
          );
        }
        await _loadHealthData();
      } else {
        if (mounted) Msg.error(context, "Gagal menyinkronkan data Smartwatch");
      }
    } catch (e) {
      if (mounted) Msg.error(context, "Terjadi kesalahan sync: $e");
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Wellness",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: isSyncing 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.sync_rounded, color: Colors.white),
            onPressed: isSyncing ? null : _triggerManualSync,
            tooltip: "Sync Smartwatch Now",
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHealthData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeaderSummary(),
                    const SizedBox(height: 16),
                    _buildMetricCards(),
                    const SizedBox(height: 20),
                    _buildPersonalActivityTabs(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  int _parseNum(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? 0);
    return 0;
  }

  Widget _buildHeaderSummary() {
    int steps = _parseNum(todayData['jumlah_langkah']);
    double progress = (steps / 10000).clamp(0.0, 1.0);
    double distanceKm = double.parse((steps * 0.00075).toStringAsFixed(1));
    int calories = (steps * 0.04).toInt();
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 12;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            const Color(0xFF2596BE),
            const Color(0xFF155E75),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle Ambient Glow Circle Safely Positioned
          Positioned(
            bottom: -20,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(22, topPadding, 22, 22),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Futuristic Glowing Circular Ring
                    SizedBox(
                      width: 105,
                      height: 105,
                      child: CustomPaint(
                        painter: GradientCircularProgressPainter(
                          progress: progress,
                          strokeWidth: 10,
                          gradientColors: const [
                            Color(0xFFFFD700), // Gold
                            Color(0xFFFF9100), // Orange
                            Color(0xFFFF3D00), // Coral Red
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_run_rounded,
                                color: Colors.amberAccent,
                                size: 24,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${(progress * 100).toInt()}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right Side Metrics Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("🔥 ", style: TextStyle(fontSize: 10)),
                                    Text(
                                      "TARGET HARIAN",
                                      style: TextStyle(
                                        color: Colors.amberAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                NumberFormat.decimalPattern('id').format(steps),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "langkah",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Target: 10.000 Langkah Harian",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Mini Badges for Distance & Calories
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Colors.cyanAccent, size: 12),
                                    const SizedBox(width: 3),
                                    Text(
                                      "$distanceKm km",
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 12),
                                    const SizedBox(width: 3),
                                    Text(
                                      "$calories kcal",
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sleek Glassmorphic Sync Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.watch_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Sync: ${todayData['last_synced_at'] != null ? DateFormat('HH:mm').format(DateTime.parse(todayData['last_synced_at'])) : 'Hari ini'}",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: isSyncing ? null : _triggerManualSync,
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSyncing)
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                                )
                              else
                                Icon(Icons.sync_rounded, color: primaryColor, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                isSyncing ? "Syncing..." : "Sync Sekarang",
                                style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    int hr = _parseNum(todayData['detak_jantung_avg']);
    int rhr = _parseNum(todayData['detak_jantung_resting']);
    int sleepMin = _parseNum(todayData['durasi_tidur_menit']);
    double sleepHours = double.parse((sleepMin / 60).toStringAsFixed(1));
    double? spo2Val = double.tryParse(todayData['spo2_avg']?.toString() ?? '');
    int calories = _parseNum(todayData['kalori_aktif']);
    int activeMins = _parseNum(todayData['menit_aktif']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Indikator Kesehatan Hari Ini",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: "Detak Jantung",
                  value: "$hr BPM",
                  subtitle: "Resting: $rhr BPM",
                  icon: "❤️",
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: "Tidur Malam",
                  value: "$sleepHours Jam",
                  subtitle: sleepMin == 0 ? "Belum ada data" : (sleepMin < 300 ? "⚠️ Kurang Tidur" : "Cukup Istirahat"),
                  icon: "😴",
                  color: sleepMin == 0 ? Colors.grey : (sleepMin < 300 ? Colors.orange : Colors.indigo),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: "Saturasi SpO2",
                  value: spo2Val != null ? "$spo2Val%" : "- %",
                  subtitle: spo2Val != null ? "Normal (95-100%)" : "Belum ada data",
                  icon: "🩸",
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: "Kalori Aktif",
                  value: "$calories kcal",
                  subtitle: "$activeMins mnt aktif",
                  icon: "🔥",
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required String icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Text(icon, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: color[700], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPersonalActivityTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey[500],
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "📊 Riwayat 7 Hari Terakhir"),
              Tab(text: "🎯 Target & Statistik Saya"),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyTrendList(),
                _buildMonthlyStatsView(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendList() {
    if (weeklyTrend.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_walk_rounded, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text("Belum ada riwayat aktivitas mingguan", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
    }
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: weeklyTrend.length,
        itemBuilder: (context, index) {
          var item = weeklyTrend[index];
          int steps = _parseNum(item['jumlah_langkah']);
          double progress = (steps / 10000).clamp(0.0, 1.0);
          String tanggal = item['tanggal'] ?? '-';
          try {
            DateTime parsed = DateTime.parse(tanggal);
            tanggal = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(parsed);
          } catch (_) {}

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tanggal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(
                        "${NumberFormat.decimalPattern('id').format(steps)} langkah",
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      color: progress >= 1.0 ? Colors.green : primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${item['jarak_km'] ?? 0} km • ${item['kalori_aktif'] ?? 0} kcal",
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        "${(progress * 100).toInt()}% target harian",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: progress >= 1.0 ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyStatsView() {
    int totalSteps = _parseNum(monthlyStats['total_steps']);
    int avgSteps = _parseNum(monthlyStats['avg_steps']);
    int totalDays = _parseNum(monthlyStats['total_days']);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMonthlyStatCard(
                  title: "Total Langkah Bulan Ini",
                  value: NumberFormat.decimalPattern('id').format(totalSteps),
                  unit: "langkah",
                  icon: Icons.route_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMonthlyStatCard(
                  title: "Rata-rata Harian",
                  value: NumberFormat.decimalPattern('id').format(avgSteps),
                  unit: "langkah/hari",
                  icon: Icons.trending_up_rounded,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMonthlyStatCard(
            title: "Hari Aktif Tercatat",
            value: "$totalDays",
            unit: "hari aktif bulan ini",
            icon: Icons.calendar_today_rounded,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Colors.amber[800], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Target rekomendasi: 6.000 - 10.000 langkah setiap hari secara konsisten dapat meningkatkan kesehatan kardiovaskular dan stamina tubuh Anda.",
                    style: TextStyle(fontSize: 11, color: Colors.amber[900], height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color[700]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> gradientColors;

  GradientCircularProgressPainter({
    required this.progress,
    this.strokeWidth = 10,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background Track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * 3.141592653589793 * progress.clamp(0.0, 1.0);

    // Glow Effect Under Progress Arc
    final glowPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: -0.5 * 3.141592653589793,
        endAngle: 1.5 * 3.141592653589793,
        transform: const GradientRotation(-0.5 * 3.141592653589793),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.141592653589793,
      sweepAngle,
      false,
      glowPaint,
    );

    // Foreground Gradient Arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: -0.5 * 3.141592653589793,
        endAngle: 1.5 * 3.141592653589793,
        transform: const GradientRotation(-0.5 * 3.141592653589793),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.141592653589793,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.gradientColors != gradientColors;
  }
}
