import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/components/loadingku.dart';

class HelpdeskDashboardScreen extends StatefulWidget {
  const HelpdeskDashboardScreen({super.key});

  @override
  State<HelpdeskDashboardScreen> createState() => _HelpdeskDashboardScreenState();
}

class _HelpdeskDashboardScreenState extends State<HelpdeskDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  
  String _period = 'monthly'; // 'monthly' or 'yearly'
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  final List<Map<String, dynamic>> _monthsList = [
    {'value': 1, 'label': 'Januari'},
    {'value': 2, 'label': 'Februari'},
    {'value': 3, 'label': 'Maret'},
    {'value': 4, 'label': 'April'},
    {'value': 5, 'label': 'Mei'},
    {'value': 6, 'label': 'Juni'},
    {'value': 7, 'label': 'Juli'},
    {'value': 8, 'label': 'Agustus'},
    {'value': 9, 'label': 'September'},
    {'value': 10, 'label': 'Oktober'},
    {'value': 11, 'label': 'November'},
    {'value': 12, 'label': 'Desember'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      String queryParams = "?period=$_period&year=$_selectedYear";
      if (_period == 'monthly') {
        queryParams += "&month=$_selectedMonth";
      }

      final url = "/helpdesk/tiket/dashboard-data$queryParams";
      final res = await Api().getData(url);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _dashboardData = body['data'] ?? {};
          _isLoading = false;
        });
      } else {
        Msg.error(context, "Gagal memuat data statistik dashboard");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan sistem: $e");
      setState(() => _isLoading = false);
    }
  }

  String _getSelectedMonthName() {
    final match = _monthsList.firstWhere(
      (m) => m['value'] == _selectedMonth,
      orElse: () => {'label': ''},
    );
    return match['label'];
  }

  String _formatDuration(dynamic minutes) {
    if (minutes == null) return '0 Menit';
    double minVal = double.tryParse(minutes.toString()) ?? 0;
    if (minVal <= 0) return '0 Menit';
    if (minVal < 60) return '${minVal.round()} Menit';
    int hrs = (minVal / 60).floor();
    int mins = (minVal % 60).round();
    return mins > 0 ? '$hrs Jam $mins Menit' : '$hrs Jam';
  }

  String _getDayName(String dayLabel) {
    if (_period != 'monthly') return '';
    int? dayNum = int.tryParse(dayLabel);
    if (dayNum == null) return '';
    try {
      final date = DateTime(_selectedYear, _selectedMonth, dayNum);
      final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
      return days[date.weekday % 7];
    } catch (_) {
      return '';
    }
  }

  bool _isSunday(String dayLabel) {
    if (_period != 'monthly') return false;
    int? dayNum = int.tryParse(dayLabel);
    if (dayNum == null) return false;
    try {
      final date = DateTime(_selectedYear, _selectedMonth, dayNum);
      return date.weekday == DateTime.sunday;
    } catch (_) {
      return false;
    }
  }

  int _getMonthValFromName(String name) {
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'Mei': 5, 'Jun': 6,
      'Jul': 7, 'Agu': 8, 'Sep': 9, 'Okt': 10, 'Nov': 11, 'Des': 12,
      'Januari': 1, 'Februari': 2, 'Maret': 3, 'April': 4, 'Mei': 5, 'Juni': 6,
      'Juli': 7, 'Agustus': 8, 'September': 9, 'Oktober': 10, 'November': 11, 'Desember': 12
    };
    return months[name] ?? DateTime.now().month;
  }

  // Lookup details when clicking cell numbers
  Future<void> _showLookupBottomSheet(Map<String, dynamic> col, String type) async {
    String typeLabel = '';
    if (type == 'total') typeLabel = 'Total Tiket Masuk';
    if (type == 'responded') typeLabel = 'Tiket Direspon';
    if (type == 'selesai') typeLabel = 'Tiket Selesai';

    String dateLabel = '';
    if (_period == 'monthly') {
      dateLabel = 'Tanggal ${col['label']} ${_getSelectedMonthName()} $_selectedYear';
    } else {
      dateLabel = 'Bulan ${col['label']} $_selectedYear';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LookupTicketsBottomSheet(
        title: '$typeLabel ($dateLabel)',
        year: _selectedYear,
        month: _period == 'monthly' ? _selectedMonth : _getMonthValFromName(col['label'].toString()),
        day: _period == 'monthly' ? int.tryParse(col['label'].toString()) : null,
        type: type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Dashboard Analytics IT",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadDashboardData,
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? Center(child: loadingku(fullPage: false))
                : RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    color: primaryColor,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryStats(),
                          const SizedBox(height: 0),
                          _buildSlaSection(),
                          const SizedBox(height: 20),
                          _buildTrendChartCard(),
                          const SizedBox(height: 20),
                          _buildTrendTableCard(),
                          const SizedBox(height: 20),
                          _buildCategoriesDistributionCard(),
                          const SizedBox(height: 20),
                          _buildTopTechCard(),
                          const SizedBox(height: 20),
                          _buildRecentActivityCard(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 18, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Period Toggle (Bulanan / Tahunan)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _buildPeriodTab('monthly', 'Bulanan'),
                  _buildPeriodTab('yearly', 'Tahunan'),
                ],
              ),
            ),
          ),

          // Month & Year Selectors
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_period == 'monthly') ...[
                _buildDropdownPill(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      dropdownColor: primaryColor,
                      isDense: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      items: _monthsList.map((m) {
                        return DropdownMenuItem<int>(
                          value: m['value'],
                          child: Text(m['label'].substring(0, 3)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedMonth = val);
                          _loadDashboardData();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _buildDropdownPill(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    dropdownColor: primaryColor,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    items: List.generate(4, (i) => DateTime.now().year - i).map((y) {
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text(y.toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYear = val);
                        _loadDashboardData();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownPill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );
  }

  Widget _buildPeriodTab(String period, String label) {
    bool isActive = _period == period;
    return GestureDetector(
      onTap: () {
        if (_period != period) {
          setState(() => _period = period);
          _loadDashboardData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? primaryColor : Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final summary = _dashboardData['summary'] ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 4),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.75,
      children: [
        _buildStatCard("Total Tiket", summary['total_tickets']?.toString() ?? "0", Icons.folder_open, Colors.blue),
        _buildStatCard("Open", summary['open']?.toString() ?? "0", Icons.mail_outline, Colors.cyan),
        _buildStatCard("Proses", summary['proses']?.toString() ?? "0", Icons.sync_rounded, Colors.orange),
        _buildStatCard("Selesai", summary['selesai']?.toString() ?? "0", Icons.check_circle_outline, Colors.green),
        _buildStatCard("Batal", summary['batal']?.toString() ?? "0", Icons.cancel_outlined, Colors.red),
        _buildStatCard("MESSA Wait", summary['waiting_logs']?.toString() ?? "0", Icons.phone_android_rounded, Colors.pink),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 8, offset: const Offset(0, 3))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.07)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.1),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlaSection() {
    final summary = _dashboardData['summary'] ?? {};
    int total = int.tryParse(summary['total_tickets']?.toString() ?? '0') ?? 0;
    int selesai = int.tryParse(summary['selesai']?.toString() ?? '0') ?? 0;
    int open = int.tryParse(summary['open']?.toString() ?? '0') ?? 0;
    int direspon = total - open;

    double responsePercent = total > 0 ? (direspon / total) : 0;
    double resolutionPercent = total > 0 ? (selesai / total) : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSlaCard("Avg Waktu Respon", _formatDuration(summary['avg_response_time']), Icons.bolt, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _buildSlaCard("Avg Waktu Selesai", _formatDuration(summary['avg_resolution_time']), Icons.hourglass_empty_rounded, Colors.purple)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildRateCard("Tiket Direspon", "$direspon / $total", responsePercent, Colors.cyan)),
            const SizedBox(width: 10),
            Expanded(child: _buildRateCard("Tiket Selesai", "$selesai / $total", resolutionPercent, Colors.green)),
          ],
        )
      ],
    );
  }

  Widget _buildSlaCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRateCard(String title, String ratio, double percent, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
              Text("${(percent * 100).round()}%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(ratio, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrendChartCard() {
    final List trend = _dashboardData['trend'] ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    // Prepare chart coordinates
    List<FlSpot> spots = [];
    double maxVal = 5;
    for (int i = 0; i < trend.length; i++) {
      double val = double.tryParse(trend[i]['count'].toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxVal) maxVal = val;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tren Volume Tiket", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(
                _period == 'monthly' ? "${_getSelectedMonthName()} $_selectedYear" : "Tahun $_selectedYear",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
              )
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[100]!, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx >= 0 && idx < trend.length) {
                          // Show labels for every 5 days or all months
                          if (_period == 'monthly' && (idx + 1) % 5 != 0 && idx != 0 && idx != trend.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            trend[idx]['label'].toString(),
                            style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 9),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: trend.length.toDouble() - 1,
                minY: 0,
                maxY: maxVal * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.01)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrendTableCard() {
    final List trend = _dashboardData['trend'] ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Data Rincian Aktivitas (${_period == 'monthly' ? _getSelectedMonthName() + ' ' + _selectedYear.toString() : _selectedYear.toString()})",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text("* Klik angka untuk melihat rincian tiket", style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.grey)),
          const SizedBox(height: 15),
          
          // Horizontal scroll table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Labels Column (Sticky left)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCellLabel(_period == 'monthly' ? "Info / Hari" : "Info / Bulan", isHeader: true),
                    _buildCellLabel("Total Tiket"),
                    _buildCellLabel("Direspon / Total"),
                    _buildCellLabel("Selesai / Total"),
                  ],
                ),
                
                // Data Columns
                ...trend.map((col) {
                  String label = col['label'].toString();
                  String dayName = _getDayName(label);
                  bool sunday = _isSunday(label);

                  int count = int.tryParse(col['count']?.toString() ?? '0') ?? 0;
                  int responded = int.tryParse(col['responded']?.toString() ?? '0') ?? 0;
                  int selesai = int.tryParse(col['selesai']?.toString() ?? '0') ?? 0;

                  return Column(
                    children: [
                      // Header Cell (Day Number + Name)
                      Container(
                        width: 60,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sunday ? Colors.red[50] : const Color(0xFFF8F9FA),
                          border: Border.all(color: Colors.grey[200]!, width: 0.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sunday ? Colors.red : const Color(0xFF1E293B),
                              ),
                            ),
                            if (dayName.isNotEmpty)
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: sunday ? Colors.red[300] : Colors.grey[400],
                                ),
                              )
                          ],
                        ),
                      ),

                      // Row 1: Total Tiket
                      _buildClickableCell(
                        text: count.toString(),
                        hasData: count > 0,
                        textColor: count > 0 ? Colors.white : Colors.grey[400]!,
                        bgColor: count > 0 ? Colors.blue : Colors.grey[50]!,
                        onTap: () => _showLookupBottomSheet(Map<String, dynamic>.from(col), 'total'),
                      ),

                      // Row 2: Direspon / Total
                      _buildClickableCell(
                        text: count > 0 ? "$responded/$count" : "-",
                        hasData: count > 0,
                        textColor: count > 0 ? Colors.cyan[800]! : Colors.grey[400]!,
                        bgColor: count > 0 ? Colors.cyan[50]! : Colors.transparent,
                        onTap: () => _showLookupBottomSheet(Map<String, dynamic>.from(col), 'responded'),
                      ),

                      // Row 3: Selesai / Total
                      _buildClickableCell(
                        text: count > 0 ? "$selesai/$count" : "-",
                        hasData: count > 0,
                        textColor: count > 0 ? Colors.green[800]! : Colors.grey[400]!,
                        bgColor: count > 0 ? Colors.green[50]! : Colors.transparent,
                        onTap: () => _showLookupBottomSheet(Map<String, dynamic>.from(col), 'selesai'),
                      ),
                    ],
                  );
                }).toList()
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCellLabel(String label, {bool isHeader = false}) {
    return Container(
      width: 110,
      height: isHeader ? 45 : 35,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: Colors.grey[200]!, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildClickableCell({
    required String text,
    required bool hasData,
    required Color textColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: hasData ? onTap : null,
      child: Container(
        width: 60,
        height: 35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.grey[200]!, width: 0.5),
        ),
        child: hasData
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: bgColor == Colors.transparent ? Colors.transparent : bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  text,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textColor),
                ),
              )
            : Text(
                text,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: textColor),
              ),
      ),
    );
  }

  Widget _buildCategoriesDistributionCard() {
    final List byCategory = _dashboardData['by_category'] ?? [];
    if (byCategory.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Distribusi Kategori Kendala", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 15),
          ...byCategory.map((cat) {
            String label = cat['kategori'] ?? 'Lainnya';
            int count = int.tryParse(cat['count']?.toString() ?? '0') ?? 0;
            int total = int.tryParse((_dashboardData['summary']?['total_tickets'] ?? 0).toString()) ?? 1;
            double percent = count / (total > 0 ? total : 1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      Text("$count Tiket (${(percent * 100).round()}%)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey[100],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      minHeight: 5,
                    ),
                  )
                ],
              ),
            );
          }).toList()
        ],
      ),
    );
  }

  Widget _buildTopTechCard() {
    final List topTechnicians = _dashboardData['top_technicians'] ?? [];
    if (topTechnicians.isEmpty) return const SizedBox.shrink();

    // Find max value to draw progress bar proportionally
    int maxCount = 1;
    for (var tech in topTechnicians) {
      int cnt = int.tryParse(tech['count']?.toString() ?? '0') ?? 0;
      if (cnt > maxCount) maxCount = cnt;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Detail Kontribusi Tim", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 15),
          ...topTechnicians.map((tech) {
            String name = tech['teknisi']?['nama'] ?? 'Tanpa Nama';
            int count = int.tryParse(tech['count']?.toString() ?? '0') ?? 0;
            double percent = count / maxCount;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, size: 16, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text("$count Selesai", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey[100],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                            minHeight: 6,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          }).toList()
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final List recentTickets = _dashboardData['recent_tickets'] ?? [];
    if (recentTickets.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tiket Terbaru Masuk", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 15),
          ...recentTickets.map((ticket) {
            String noTiket = ticket['no_tiket'] ?? '-';
            String keluhan = ticket['keluhan'] ?? '-';
            String status = (ticket['status'] ?? 'Open').toString().toUpperCase();
            String prioritas = (ticket['prioritas'] ?? 'Medium').toString().toUpperCase();
            String pelapor = ticket['pelapor']?['nama'] ?? 'Non-Pegawai';
            String dep = ticket['departemen']?['nama'] ?? '-';

            Color statusColor = Colors.blue;
            if (status == 'SELESAI') statusColor = Colors.green;
            if (status == 'PROSES') statusColor = Colors.orange;
            if (status == 'BATAL') statusColor = Colors.red;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(noTiket, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: prioritas == 'HIGH' ? Colors.red[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              prioritas,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: prioritas == 'HIGH' ? Colors.red : Colors.blue[800],
                              ),
                            ),
                          )
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9.5),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    keluhan,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155), height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "$pelapor ($dep)",
                          style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          }).toList()
        ],
      ),
    );
  }
}

// Bottom Sheet displaying List of tickets for a specific date / type
class _LookupTicketsBottomSheet extends StatefulWidget {
  final String title;
  final int year;
  final int? month;
  final int? day;
  final String type;

  const _LookupTicketsBottomSheet({
    required this.title,
    required this.year,
    this.month,
    this.day,
    required this.type,
  });

  @override
  State<_LookupTicketsBottomSheet> createState() => _LookupTicketsBottomSheetState();
}

class _LookupTicketsBottomSheetState extends State<_LookupTicketsBottomSheet> {
  bool _loading = true;
  List _ticketsList = [];

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      String queryParams = "?limit=100&type=${widget.type}&year=${widget.year}";
      if (widget.month != null) queryParams += "&month=${widget.month}";
      if (widget.day != null) queryParams += "&day=${widget.day}";

      final res = await Api().getData("/helpdesk/tiket/active$queryParams");
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _ticketsList = body['data']['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 15),
          
          // Header
          Text("🔍 Rincian Laporan Tiket", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 2),
          Text(widget.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 15),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _ticketsList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_number_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 15),
                            const Text("Tidak ada rincian tiket untuk periode ini", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _ticketsList.length,
                        itemBuilder: (context, index) {
                          final ticket = _ticketsList[index];
                          String noTiket = ticket['no_tiket'] ?? '-';
                          String date = ticket['tanggal'] ?? '-';
                          String reporter = ticket['pelapor']?['nama'] ?? 'Non-Pegawai';
                          String dept = ticket['departemen']?['nama'] ?? '-';
                          String complaint = ticket['keluhan'] ?? '-';
                          String solution = ticket['solusi'] ?? '';
                          String status = (ticket['status'] ?? 'Open').toString().toUpperCase();
                          String priority = (ticket['prioritas'] ?? 'Medium').toString().toUpperCase();
                          String techName = ticket['teknisi']?['nama'] ?? '';

                          Color statusColor = Colors.blue;
                          if (status == 'SELESAI') statusColor = Colors.green;
                          if (status == 'PROSES') statusColor = Colors.orange;
                          if (status == 'BATAL') statusColor = Colors.red;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(noTiket, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9.5)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(complaint, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3142), height: 1.4)),
                                if (solution.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green[100]!)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Solusi IT:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                        const SizedBox(height: 4),
                                        Text(solution, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.green[900])),
                                      ],
                                    ),
                                  )
                                ],
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Pelapor", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                                        Text("$reporter ($dept)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text("Waktu", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                                        Text(_formatDate(date), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                      ],
                                    ),
                                  ],
                                ),
                                if (techName.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.engineering_outlined, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text("Teknisi: $techName", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          );
                        },
                      ),
          ),
          
          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF475569),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
