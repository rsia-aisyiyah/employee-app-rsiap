import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class DashboardKunjungan extends StatefulWidget {
  const DashboardKunjungan({super.key});

  @override
  State<DashboardKunjungan> createState() => _DashboardKunjunganState();
}

class _DashboardKunjunganState extends State<DashboardKunjungan> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  final TextEditingController _tglAwalController = TextEditingController();
  final TextEditingController _tglAkhirController = TextEditingController();
  String _statusLanjut = 'all';

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    _tglAwalController.text = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
    _tglAkhirController.text = DateFormat('yyyy-MM-dd').format(now);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final queryParams =
          "?tgl_awal=${_tglAwalController.text}&tgl_akhir=${_tglAkhirController.text}&status_lanjut=$_statusLanjut";
      final res = await Api().getData("/dashboard/visits$queryParams");

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _data = body['data'];
          _isLoading = false;
        });
      } else {
        Msg.error(context, "Gagal memuat data statistik");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan sistem");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(controller.text),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Dashboard Kunjungan",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(15),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryGrid(),
                          const SizedBox(height: 15),
                          _buildTrendIndicator(),
                          const SizedBox(height: 20),
                          _buildVisitChart(),
                          const SizedBox(height: 20),
                          if (_statusLanjut == 'Ranap' &&
                              _data['inpatient_care'] != null) ...[
                            _buildInpatientStats(),
                            const SizedBox(height: 20),
                          ],
                          _buildRegistrationBreakdown(),
                          const SizedBox(height: 20),
                          _buildDomicileList(),
                          const SizedBox(height: 20),
                          _buildAgeDistribution(),
                          const SizedBox(height: 20),
                          _buildCaraBayarList(),
                          const SizedBox(height: 20),
                          _buildCancellationAnalysis(),
                          const SizedBox(height: 20),
                          _buildTopDoctorsList(),
                          const SizedBox(height: 100), // Extra space for scroll
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateInput("Mulai", _tglAwalController),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateInput("Selesai", _tglAkhirController),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusLanjut,
                dropdownColor: primaryColor,
                isExpanded: true,
                icon:
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text("Semua Layanan")),
                  DropdownMenuItem(value: 'Ralan', child: Text("Rawat Jalan")),
                  DropdownMenuItem(value: 'Ranap', child: Text("Rawat Inap")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _statusLanjut = val);
                    _loadData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInput(String label, TextEditingController controller) {
    return InkWell(
      onTap: () => _selectDate(context, controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 10)),
            const SizedBox(height: 2),
            Text(controller.text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    final summary = _data['summary'] ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: [
        _buildStatCard("Total Kunjungan", summary['total']?.toString() ?? "0",
            Icons.people_rounded, Colors.blue),
        _buildStatCard("Pasien Baru", summary['baru']?.toString() ?? "0",
            Icons.person_add_rounded, Colors.green),
        _buildStatCard("Pasien Lama", summary['lama']?.toString() ?? "0",
            Icons.history_rounded, Colors.orange),
        _buildStatCard(
            "Gender (L:P)",
            "${summary['pria'] ?? 0}:${summary['wanita'] ?? 0}",
            Icons.wc_rounded,
            Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInpatientStats() {
    final care = _data['inpatient_care'] ?? {};
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Statistik Rawat Inap",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInpatientItem(
                  "Hari Perawatan", "${care['hari_perawatan'] ?? 0}"),
              _buildInpatientItem(
                  "Lama Dirawat", "${care['lama_dirawat'] ?? 0}"),
              _buildInpatientItem("ALOS", "${care['avg_lama_dirawat'] ?? 0}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInpatientItem(String label, String val) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRegistrationBreakdown() {
    return _buildVisualCard(
        "Pasien Baru vs Lama",
        Column(
          children: [
            _buildProgressBar(
                "Baru (L)", _getRegCount('Baru', 'L'), Colors.blue),
            _buildProgressBar(
                "Baru (P)", _getRegCount('Baru', 'P'), Colors.pink),
            const SizedBox(height: 10),
            _buildProgressBar(
                "Lama (L)", _getRegCount('Lama', 'L'), Colors.cyan),
            _buildProgressBar(
                "Lama (P)", _getRegCount('Lama', 'P'), Colors.purple),
          ],
        ));
  }

  int _getRegCount(String status, String gender) {
    List reg = _data['registrasi'] ?? [];
    try {
      return reg.firstWhere(
          (r) => r['stts_daftar'] == status && r['jk'] == gender)['total'];
    } catch (e) {
      return 0;
    }
  }

  Widget _buildProgressBar(String label, int val, Color color) {
    int total = _data['summary']?['total'] ?? 1;
    if (total == 0) total = 1;
    double percent = val / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
              Text("$val",
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[100],
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaraBayarList() {
    List caraBayar = _data['cara_bayar'] ?? [];
    return _buildVisualCard(
        "Berdasarkan Cara Bayar",
        Column(
          children: caraBayar
              .map((item) => _buildProgressBar(
                  item['label'], item['total'], Colors.blueAccent))
              .toList(),
        ));
  }

  Widget _buildTopDoctorsList() {
    List doctors = _data['dokter'] ?? [];
    return _buildVisualCard(
        "10 Dokter Teratas",
        Column(
          children: doctors.asMap().entries.map((entry) {
            int idx = entry.key;
            var item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Text("${idx + 1}",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['label'],
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        _buildMiniProgressBar(
                            item['total'], doctors[0]['total']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("${item['total']}",
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ],
              ),
            );
          }).toList(),
        ));
  }

  Widget _buildMiniProgressBar(int val, int max) {
    if (max == 0) max = 1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: val / max,
        backgroundColor: Colors.grey[100],
        color: Colors.green.withOpacity(0.6),
        minHeight: 4,
      ),
    );
  }

  Widget _buildVisualCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87)),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildVisitChart() {
    List charts = _data['charts'] ?? [];
    if (charts.isEmpty) return const SizedBox.shrink();

    List<FlSpot> ralanSpots = [];
    List<FlSpot> ranapSpots = [];

    for (int i = 0; i < charts.length; i++) {
      var item = charts[i];
      if (_statusLanjut == 'all' || _statusLanjut == 'Ralan') {
        ralanSpots.add(FlSpot(i.toDouble(), (item['ralan'] ?? 0).toDouble()));
      }
      if (_statusLanjut == 'all' || _statusLanjut == 'Ranap') {
        ranapSpots.add(FlSpot(i.toDouble(), (item['ranap'] ?? 0).toDouble()));
      }
    }

    return _buildVisualCard(
      "Tren Kunjungan Harian",
      Column(
        children: [
          if (_statusLanjut == 'all')
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem("Rawat Jalan", Colors.blue),
                  const SizedBox(width: 20),
                  _buildLegendItem("Rawat Inap", Colors.orange),
                ],
              ),
            ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[100],
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: charts.length > 7
                          ? (charts.length / 5).ceil().toDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= charts.length) {
                          return const SizedBox.shrink();
                        }
                        String dateStr = charts[idx]['date'];
                        DateTime date = DateTime.parse(dateStr);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            DateFormat('dd/MM').format(date),
                            style:
                                TextStyle(color: Colors.grey[500], fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style:
                                TextStyle(color: Colors.grey[500], fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  if (ralanSpots.isNotEmpty)
                    LineChartBarData(
                      spots: ralanSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.05),
                      ),
                    ),
                  if (ranapSpots.isNotEmpty)
                    LineChartBarData(
                      spots: ranapSpots,
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.05),
                      ),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey[800]!,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        int idx = flSpot.x.toInt();
                        String dateStr = charts[idx]['date'];
                        DateTime date = DateTime.parse(dateStr);
                        String formattedDate =
                            DateFormat('dd/MM/yy').format(date);

                        String type = barSpot.bar.color == Colors.blue
                            ? "Ralan"
                            : "Ranap";

                        // Add date only to the first item for clarity
                        String label = touchedBarSpots.indexOf(barSpot) == 0
                            ? "$formattedDate\n$type: ${flSpot.y.toInt()}"
                            : "$type: ${flSpot.y.toInt()}";

                        return LineTooltipItem(
                          label,
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildChartInsights(charts),
        ],
      ),
    );
  }

  Widget _buildChartInsights(List charts) {
    if (charts.isEmpty) return const SizedBox.shrink();

    Map? maxRalan;
    Map? maxRanap;

    for (var item in charts) {
      if (maxRalan == null || (item['ralan'] ?? 0) > (maxRalan['ralan'] ?? 0)) {
        maxRalan = item;
      }
      if (maxRanap == null || (item['ranap'] ?? 0) > (maxRanap['ranap'] ?? 0)) {
        maxRanap = item;
      }
    }

    return Column(
      children: [
        if (_statusLanjut == 'all' || _statusLanjut == 'Ralan')
          _buildInsightRow(
            "Puncak Rawat Jalan",
            maxRalan?['date'] ?? '-',
            "${maxRalan?['ralan'] ?? 0} Pasien",
            Colors.blue,
          ),
        if (_statusLanjut == 'all') const SizedBox(height: 8),
        if (_statusLanjut == 'all' || _statusLanjut == 'Ranap')
          _buildInsightRow(
            "Puncak Rawat Inap",
            maxRanap?['date'] ?? '-',
            "${maxRanap?['ranap'] ?? 0} Pasien",
            Colors.orange,
          ),
      ],
    );
  }

  Widget _buildInsightRow(
      String label, String date, String value, Color color) {
    String formattedDate = '-';
    try {
      formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.parse(date));
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color.withOpacity(0.8))),
                Text(formattedDate,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildDomicileList() {
    List domiciles = _data['domisili'] ?? [];
    if (domiciles.isEmpty) return const SizedBox.shrink();

    return _buildVisualCard(
        "10 Wilayah (Kecamatan) Teratas",
        Column(
          children: domiciles.asMap().entries.map((entry) {
            int idx = entry.key;
            var item = entry.value;
            int total = domiciles[0]['total'] ?? 1;
            if (total == 0) total = 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Text("${idx + 1}",
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['label'],
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (item['total'] ?? 0) / total,
                            backgroundColor: Colors.grey[100],
                            color: Colors.teal.withOpacity(0.6),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("${item['total']}",
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal)),
                ],
              ),
            );
          }).toList(),
        ));
  }

  Widget _buildTrendIndicator() {
    final trend = _data['trend'] ?? {};
    if (trend.isEmpty) return const SizedBox.shrink();

    final bool isUp = trend['percent'] >= 0;
    final color = isUp ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Trend vs Periode Sebelumnya",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${isUp ? '+' : ''}${trend['percent']}% (${trend['diff'] >= 0 ? '+' : ''}${trend['diff']} Pasien)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Periode Lalu",
                style: TextStyle(fontSize: 9, color: Colors.grey[400]),
              ),
              Text(
                trend['label'] ?? '-',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgeDistribution() {
    List ageGroups = _data['usia'] ?? [];
    if (ageGroups.isEmpty) return const SizedBox.shrink();

    Map<String, Color> ageColors = {
      'Bayi': Colors.blue,
      'Anak': Colors.green,
      'Remaja': Colors.orange,
      'Dewasa': Colors.purple,
      'Lansia': Colors.red,
    };

    return _buildVisualCard(
      "Distribusi Kelompok Usia",
      Column(
        children: ageGroups.map((item) {
          String label = item['label'];
          return _buildProgressBar(
            label,
            item['total'],
            ageColors[label] ?? Colors.grey,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCancellationAnalysis() {
    final batal = _data['batal'] ?? {};
    final int totalBatal = batal['total'] ?? 0;
    if (totalBatal == 0) return const SizedBox.shrink();

    List byPoli = batal['by_poli'] ?? [];
    List byStatus = batal['by_status'] ?? [];

    return _buildVisualCard(
      "Analisis Kunjungan Batal",
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Pembatalan",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Text(
                  "$totalBatal Pasien",
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Top 5 Klinik (Batal Terbanyak)",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...byPoli.map((item) => _buildProgressBar(
              item['label'], item['total'], Colors.redAccent.withOpacity(0.6))),
          const SizedBox(height: 15),
          const Text(
            "Berdasarkan Layanan",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: byStatus.map((item) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item['label'],
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        "${item['total']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
