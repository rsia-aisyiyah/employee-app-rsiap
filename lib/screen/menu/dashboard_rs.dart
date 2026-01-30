import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class DashboardRS extends StatefulWidget {
  const DashboardRS({super.key});

  @override
  State<DashboardRS> createState() => _DashboardRSState();
}

class _DashboardRSState extends State<DashboardRS> {
  bool _isLoading = true;
  bool _isReloading = false;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _codeBlue = {};

  // Filter states
  String _selectedPeriod = 'today';
  String _tglAwal = '';
  String _tglAkhir = '';

  // Auto reload states
  bool _autoReloadEnabled = false;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _tglAwal = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _tglAkhir = _tglAwal;
    _fetchData();
  }

  @override
  void dispose() {
    _stopAutoReload();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      if (_stats.isEmpty) {
        _isLoading = true;
      } else {
        _isReloading = true;
      }
    });

    try {
      final statsRes = await Api()
          .getData("/dashboard/stats?tgl_awal=$_tglAwal&tgl_akhir=$_tglAkhir");
      final codeBlueRes = await Api().getData("/dashboard/codeblue");

      if (statsRes.statusCode == 200 && codeBlueRes.statusCode == 200) {
        if (mounted) {
          setState(() {
            final cbData = json.decode(codeBlueRes.body)['data'];
            _stats = json.decode(statsRes.body)['data'] ?? {};
            _codeBlue =
                (cbData is Map) ? Map<String, dynamic>.from(cbData) : {};
          });
        }
      } else {
        Msg.error(context, "Gagal memuat data dashboard");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReloading = false;
        });
      }
    }
  }

  void _selectPeriod(String value) {
    setState(() {
      _selectedPeriod = value;
    });

    final now = DateTime.now();
    if (value == 'today') {
      _tglAwal = DateFormat('yyyy-MM-dd').format(now);
      _tglAkhir = _tglAwal;
      _fetchData();
    } else if (value == 'month') {
      _tglAwal = DateFormat('yyyy-MM-01').format(now);
      _tglAkhir =
          DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));
      _fetchData();
    } else if (value == 'year') {
      _tglAwal = DateFormat('yyyy-01-01').format(now);
      _tglAkhir = DateFormat('yyyy-12-31').format(now);
      _fetchData();
    } else if (value == 'custom') {
      _showCustomDateRangePicker();
    }
  }

  Future<void> _showCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tglAwal = DateFormat('yyyy-MM-dd').format(picked.start);
        _tglAkhir = DateFormat('yyyy-MM-dd').format(picked.end);
      });
      _fetchData();
    }
  }

  void _toggleAutoReload() {
    setState(() {
      _autoReloadEnabled = !_autoReloadEnabled;
    });

    if (_autoReloadEnabled) {
      _startAutoReload();
      Msg.success(context, "Auto-reload aktif (30s)");
    } else {
      _stopAutoReload();
      Msg.info(context, "Auto-reload nonaktif");
    }
  }

  void _startAutoReload() {
    _stopAutoReload();
    _reloadTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchData();
    });
  }

  void _stopAutoReload() {
    _reloadTimer?.cancel();
    _reloadTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Dashboard RS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: TextButton.icon(
              onPressed: _toggleAutoReload,
              icon: Icon(
                _autoReloadEnabled
                    ? Icons.sync_rounded
                    : Icons.sync_disabled_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                _autoReloadEnabled ? "AUTO" : "OFF",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor:
                    _autoReloadEnabled ? Colors.green[600] : Colors.grey[400],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterBar(),
              if (_isLoading || _isReloading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      minHeight: 2,
                    ),
                  ),
                ),
              _buildDateInfo(),
              const SizedBox(height: 20),
              _isLoading && _stats.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryGrid(),
                        const SizedBox(height: 24),
                        _buildSectionHeader("🏥 Statistik Pasien"),
                        _buildPatientPoliBreakdown(),
                        const SizedBox(height: 24),
                        _buildSectionHeader("🛏️ Ketersediaan Kamar"),
                        _buildBedStats(),
                        const SizedBox(height: 24),
                        _buildSectionHeader("👥 Kepegawaian & Cuti"),
                        _buildStaffStats(),
                        const SizedBox(height: 24),
                        _buildSectionHeader("🚑 Jadwal Code Blue"),
                        _buildCodeBlueSchedule(),
                        const SizedBox(height: 40),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterItem("Hari Ini", 'today', Icons.calendar_today_rounded),
            _buildFilterItem(
                "Bulan Ini", 'month', Icons.calendar_month_rounded),
            _buildFilterItem(
                "Tahun Ini", 'year', Icons.calendar_view_day_rounded),
            _buildFilterItem("Custom", 'custom', Icons.tune_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterItem(String label, String value, IconData icon) {
    bool isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => _selectPeriod(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo() {
    String start = "";
    String end = "";

    try {
      DateTime startDate = DateTime.parse(_tglAwal);
      DateTime endDate = DateTime.parse(_tglAkhir);

      start = DateFormat('dd MMM yyyy').format(startDate);
      end = DateFormat('dd MMM yyyy').format(endDate);
    } catch (e) {
      return const SizedBox();
    }

    String periodText = start == end ? start : "$start - $end";

    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Text(
            "Periode: $periodText",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    final pasien = _stats['pasien'] ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          "Total Pasien",
          pasien['total']?.toString() ?? "0",
          Colors.blue,
          Icons.people_alt_rounded,
        ),
        _buildSummaryCard(
          "Rawat Inap",
          pasien['ranap']?.toString() ?? "0",
          Colors.orange,
          Icons.hotel_rounded,
        ),
        _buildSummaryCard(
          "Rawat Jalan",
          pasien['ralan']?.toString() ?? "0",
          Colors.teal,
          Icons.directions_walk_rounded,
        ),
        _buildSummaryCard(
          "IGD",
          pasien['igd']?.toString() ?? "0",
          Colors.red,
          Icons.medical_services_rounded,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientPoliBreakdown() {
    final perPoli =
        _stats['pasien']?['per_poli'] as Map<String, dynamic>? ?? {};
    if (perPoli.isEmpty)
      return _buildEmptyState("Belum ada data poli hari ini");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: perPoli.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final entry = perPoli.entries.elementAt(index);
          return ListTile(
            dense: true,
            title: Text(entry.key,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.value.toString(),
                style:
                    TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBedStats() {
    final bed = _stats['bed'] ?? {};
    final total = bed['total'] ?? 0;
    final terisi = bed['terisi'] ?? 0;
    final tersedia = bed['tersedia'] ?? 0;
    final rate = bed['occupancy_rate'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBedMiniStat("Total", total.toString(), Colors.grey),
              _buildBedMiniStat("Terisi", terisi.toString(), Colors.orange),
              _buildBedMiniStat("Tersedia", tersedia.toString(), Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total > 0 ? terisi / total : 0,
              backgroundColor: Colors.grey[100],
              color: primaryColor,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bed Occupancy Rate",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("$rate%",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBedMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStaffStats() {
    final pegawai = _stats['pegawai'] ?? {};
    final cuti = _stats['cuti'] ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            "Pegawai Aktif",
            pegawai['total']?.toString() ?? "0",
            Icons.groups_rounded,
            Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            "Cuti Bulan Ini",
            cuti['bulan_ini']?.toString() ?? "0",
            Icons.event_busy_rounded,
            Colors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCodeBlueSchedule() {
    if (_codeBlue.isEmpty) {
      return _buildEmptyState("Belum ada jadwal Code Blue");
    }

    return Column(
      children: [
        _buildShiftCard("🌅 PAGI", _codeBlue['pagi']),
        const SizedBox(height: 12),
        _buildShiftCard("🌇 SIANG", _codeBlue['siang']),
        const SizedBox(height: 12),
        _buildShiftCard("🌃 MALAM", _codeBlue['malam']),
      ],
    );
  }

  Widget _buildShiftCard(String title, dynamic staffData) {
    // Safety check: staffData must be a Map
    if (staffData == null || staffData is! Map) {
      return const SizedBox.shrink();
    }

    final staff = staffData as Map<String, dynamic>;
    final leader = staff['LEADER']?['nama'] ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blueAccent)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text("Leader: ",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Expanded(
                  child: Text(leader, style: const TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: List.generate(5, (i) {
              final member = staff['ANGGOTA ${i + 1}']?['nama'];
              if (member == null) return const SizedBox();
              return Chip(
                label: Text(member, style: const TextStyle(fontSize: 10)),
                backgroundColor: Colors.grey.withOpacity(0.3),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.grey[300], size: 40),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }
}
