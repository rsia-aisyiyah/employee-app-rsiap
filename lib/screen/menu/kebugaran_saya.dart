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
  List employeeLeaderboard = [];
  List departmentLeaderboard = [];

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

      var leaderboardRes = await Api().getData('/sdi/health/leaderboard');
      if (leaderboardRes.statusCode == 200) {
        var body = json.decode(leaderboardRes.body);
        if (body['success'] == true && body['message'] != null) {
          var data = body['message'];
          setState(() {
            employeeLeaderboard = data['employee_rankings'] ?? [];
            departmentLeaderboard = data['department_rankings'] ?? [];
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
        Msg.success(context, "Data Smartwatch berhasil disinkronkan!");
        await _loadHealthData();
      } else {
        Msg.error(context, "Gagal menyinkronkan data Smartwatch");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan sync: $e");
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
      appBar: AppBar(
        title: const Text(
          "Kebugaran Saya",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: isSyncing 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.sync_rounded),
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
                    _buildLeaderboardTabs(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSummary() {
    int steps = todayData['jumlah_langkah'] ?? 8450;
    double progress = (steps / 10000).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withBlue(220)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 9,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("👟", style: TextStyle(fontSize: 20)),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Target Langkah Harian",
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.decimalPattern('id').format(steps),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "/ 10.000 Langkah (Target Sehat)",
                      style: TextStyle(color: Colors.amberAccent.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.watch_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Terakhir Sync: ${todayData['last_synced_at'] != null ? DateFormat('HH:mm').format(DateTime.parse(todayData['last_synced_at'])) : 'Hari ini'}",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _triggerManualSync,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "🔄 Sync Sekarang",
                      style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    int hr = todayData['detak_jantung_avg'] ?? 74;
    int rhr = todayData['detak_jantung_resting'] ?? 62;
    int sleepMin = todayData['durasi_tidur_menit'] ?? 435;
    double sleepHours = double.parse((sleepMin / 60).toStringAsFixed(1));
    double spo2 = (todayData['spo2_avg'] ?? 98.5).toDouble();

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
                  subtitle: sleepMin < 300 ? "⚠️ Kurang Tidur" : "Cukup Istirahat",
                  icon: "😴",
                  color: sleepMin < 300 ? Colors.orange : Colors.indigo,
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
                  value: "$spo2%",
                  subtitle: "Normal (95-100%)",
                  icon: "🩸",
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: "Kalori Aktif",
                  value: "${todayData['kalori_aktif'] ?? 340} kcal",
                  subtitle: "${todayData['menit_aktif'] ?? 45} mnt aktif",
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

  Widget _buildLeaderboardTabs() {
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
              Tab(text: "🏆 Peringkat Pegawai"),
              Tab(text: "🏢 Peringkat Unit"),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeeRankList(),
                _buildDepartmentRankList(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmployeeRankList() {
    if (employeeLeaderboard.isEmpty) {
      return const Center(child: Text("Belum ada data peringkat pegawai"));
    }
    return ListView.builder(
      itemCount: employeeLeaderboard.length,
      itemBuilder: (context, index) {
        var item = employeeLeaderboard[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index == 0
                  ? Colors.amber
                  : index == 1
                      ? Colors.grey[400]
                      : index == 2
                          ? Colors.amber[700]
                          : Colors.grey[200],
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  color: index < 3 ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item['nama'] ?? 'Pegawai',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              "${item['jbtn'] ?? '-'} • ${item['departemen'] ?? '-'}",
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              "${NumberFormat.decimalPattern('id').format(item['total_steps'] ?? 0)} lgk",
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepartmentRankList() {
    if (departmentLeaderboard.isEmpty) {
      return const Center(child: Text("Belum ada data peringkat unit"));
    }
    return ListView.builder(
      itemCount: departmentLeaderboard.length,
      itemBuilder: (context, index) {
        var item = departmentLeaderboard[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(
                "${index + 1}",
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(item['departemen'] ?? 'Unit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text("${item['total_members']} Anggota Aktif", style: const TextStyle(fontSize: 11)),
            trailing: Text(
              "${NumberFormat.decimalPattern('id').format(item['avg_steps_per_member'] ?? 0)} lgk/staf",
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
