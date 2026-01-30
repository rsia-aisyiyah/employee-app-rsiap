import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class DashboardStatistikRanap extends StatefulWidget {
  const DashboardStatistikRanap({super.key});

  @override
  State<DashboardStatistikRanap> createState() =>
      _DashboardStatistikRanapState();
}

class _DashboardStatistikRanapState extends State<DashboardStatistikRanap> {
  final TextEditingController _tglAwalController = TextEditingController();
  final TextEditingController _tglAkhirController = TextEditingController();
  bool _isLoading = true;
  bool _isYearlyMode = false;
  int _selectedYear = DateTime.now().year;
  Map<String, dynamic> _period = {};
  Map<String, dynamic> _overallData = {};
  List<dynamic> _breakdownData = [];
  Map<String, dynamic> _currentData = {};
  List<dynamic> _yearlyMonths = [];
  String _activeCategory = "Gabungan";
  String _selectedMetric = "BOR";

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    DateTime firstDay = DateTime(now.year, now.month, 1);
    _tglAwalController.text = DateFormat('yyyy-MM-dd').format(firstDay);
    _tglAkhirController.text = DateFormat('yyyy-MM-dd').format(now);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_isYearlyMode) {
        final params = {
          'tahun': _selectedYear.toString(),
          'kategori': _activeCategory,
        };

        final response = await Api().getData(
            "/laporan/statistik/ranap/indicators/yearly?${Uri(queryParameters: params).query}");

        if (response.statusCode == 200) {
          final resData = json.decode(response.body)['data'] ?? {};
          setState(() {
            _yearlyMonths = resData['months'] ?? [];
            _isLoading = false;
          });
        } else {
          throw Exception("Gagal memuat data statistik tahunan");
        }
      } else {
        final params = {
          'tgl_awal': _tglAwalController.text,
          'tgl_akhir': _tglAkhirController.text,
        };

        final response = await Api().getData(
            "/laporan/statistik/ranap/indicators?${Uri(queryParameters: params).query}");

        if (response.statusCode == 200) {
          final resData = json.decode(response.body)['data'] ?? {};
          setState(() {
            _period = resData['period'] ?? {};
            _overallData = resData['overall'] ?? {};
            _breakdownData = resData['breakdown'] ?? [];

            // Update current data based on active category
            if (_activeCategory == "Gabungan") {
              _currentData = _overallData;
            } else {
              _currentData = _breakdownData.firstWhere(
                (element) => element['category'] == _activeCategory,
                orElse: () => {},
              );
            }

            _isLoading = false;
          });
        } else {
          throw Exception("Gagal memuat data statistik");
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Msg.error(context, "Terjadi kesalahan: $e");
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(controller.text),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> tabs = [
      "Gabungan",
      "Anak",
      "Kandungan",
      "BYC",
      "ICU",
      "Isolasi"
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Statistik Rawat Inap",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            onTap: (index) {
              setState(() {
                _activeCategory = tabs[index];
                if (!_isYearlyMode) {
                  if (_activeCategory == "Gabungan") {
                    _currentData = Map<String, dynamic>.from(_overallData);
                  } else {
                    final found = _breakdownData.firstWhere(
                      (element) => element['category'] == _activeCategory,
                      orElse: () => null,
                    );
                    _currentData =
                        found != null ? Map<String, dynamic>.from(found) : {};
                  }
                } else {
                  _loadData();
                }
              });
            },
            tabs: tabs.map((e) => Tab(text: e)).toList(),
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
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: _isYearlyMode
                            ? _buildYearlySection()
                            : (_currentData.isEmpty
                                ? const Center(
                                    child: Padding(
                                    padding: EdgeInsets.only(top: 100),
                                    child: Text(
                                        "Data tidak tersedia untuk kategori ini",
                                        style: TextStyle(color: Colors.grey)),
                                  ))
                                : Column(
                                    children: [
                                      _buildMainIndicatorCard(),
                                      const SizedBox(height: 20),
                                      _buildSecondaryIndicatorsGrid(),
                                      const SizedBox(height: 20),
                                      _buildDataDetailCard(),
                                      const SizedBox(height: 40),
                                    ],
                                  )),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlySection() {
    if (_yearlyMonths.isEmpty) {
      return const Center(child: Text("Data tahunan tidak tersedia"));
    }

    return Column(
      children: [
        _buildMetricSelector(),
        const SizedBox(height: 15),
        _buildTrendChart(),
        const SizedBox(height: 15),
        _buildChartAnalysis(),
        const SizedBox(height: 25),
        _buildMonthlyList(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTrendChart() {
    String unit = _selectedMetric == "BOR" ? "%" : "Hari";
    if (_selectedMetric == "BTO") unit = "Kali";

    double maxY = 100;
    if (_selectedMetric != "BOR") {
      double maxVal = 0;
      for (var m in _yearlyMonths) {
        double val = (m[_selectedMetric.toLowerCase()] ?? 0).toDouble();
        if (val > maxVal) maxVal = val;
      }
      maxY = (maxVal * 1.2).ceilToDouble();
      if (maxY == 0) maxY = 10;
    }

    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tren $_selectedMetric ($unit)",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey)),
          const SizedBox(height: 25),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200],
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style =
                            TextStyle(color: Colors.grey, fontSize: 10);
                        String text = '';
                        switch (value.toInt()) {
                          case 1:
                            text = 'Jan';
                            break;
                          case 3:
                            text = 'Mar';
                            break;
                          case 5:
                            text = 'Mei';
                            break;
                          case 7:
                            text = 'Jul';
                            break;
                          case 9:
                            text = 'Sep';
                            break;
                          case 11:
                            text = 'Nov';
                            break;
                        }
                        return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(text, style: style));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: 12,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _yearlyMonths.map((e) {
                      return FlSpot(e['month'].toDouble(),
                          (e[_selectedMetric.toLowerCase()] ?? 0).toDouble());
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                        colors: [primaryColor, Colors.blue.shade700]),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.3),
                          primaryColor.withOpacity(0.0)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    List<String> metrics = ["BOR", "AVLOS", "TOI", "BTO"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: metrics.map((m) {
        bool isSelected = _selectedMetric == m;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedMetric = m),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade300),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                child: Text(
                  m,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Data Bulanan - $_activeCategory",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[50]),
                children: [
                  _TableHeaderCell("Bulan"),
                  _TableHeaderCell("BOR (%)"),
                  _TableHeaderCell("AVLOS"),
                  _TableHeaderCell("TOI"),
                  _TableHeaderCell("BTO"),
                ],
              ),
              ..._yearlyMonths.map((e) {
                return TableRow(
                  children: [
                    _TableCell(e['month_name'].toString().substring(0, 3)),
                    _TableCell("${e['bor']}%",
                        isBold: true, color: _getBorColor(e['bor'])),
                    _TableCell(e['avlos'].toString()),
                    _TableCell(e['toi'].toString()),
                    _TableCell(e['bto'].toString()),
                  ],
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Color _getBorColor(dynamic bor) {
    double val = (bor is int) ? bor.toDouble() : (bor as double? ?? 0.0);
    if (val < 60) return Colors.orange;
    if (val > 85) return Colors.red;
    return Colors.green;
  }

  Widget _TableHeaderCell(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _TableCell(String text, {bool isBold = false, Color? color}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
            fontSize: 12,
          ),
        ),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMonthDayToggle("Harian", !_isYearlyMode,
                  () => setState(() => _isYearlyMode = false)),
              const SizedBox(width: 10),
              _buildMonthDayToggle("Tahunan", _isYearlyMode,
                  () => setState(() => _isYearlyMode = true)),
            ],
          ),
          const SizedBox(height: 15),
          if (!_isYearlyMode)
            Row(
              children: [
                Expanded(child: _buildDateInput("Mulai", _tglAwalController)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildDateInput("Selesai", _tglAkhirController)),
              ],
            )
          else
            _buildYearInput(),
        ],
      ),
    );
  }

  Widget _buildMonthDayToggle(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        onTap();
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? primaryColor : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildYearInput() {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Pilih Tahun"),
            content: SizedBox(
              width: 300,
              height: 300,
              child: YearPicker(
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                selectedDate: DateTime(_selectedYear),
                onChanged: (DateTime dateTime) {
                  setState(() => _selectedYear = dateTime.year);
                  Navigator.pop(context);
                  _loadData();
                },
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tahun Analisis",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 10)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(_selectedYear.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ],
        ),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 10)),
            const SizedBox(height: 4),
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

  Widget _buildMainIndicatorCard() {
    final indicators = _currentData['indicators'] ?? {};
    final bor = indicators['bor'] ?? 0.0;

    Color borColor = Colors.green;
    if (bor < 60) borColor = Colors.orange;
    if (bor > 85) borColor = Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          const Text("BOR (Bed Occupancy Ratio)",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: (bor / 100).clamp(0.0, 1.0),
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[100],
                  color: borColor,
                ),
              ),
              Column(
                children: [
                  Text("$bor%",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: borColor)),
                  const Text("Okupansi",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
                color: borColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              bor >= 60 && bor <= 85
                  ? "Ideal (60-85%)"
                  : (bor < 60 ? "Terlalu Rendah" : "Over Capacity"),
              style: TextStyle(
                  color: borColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryIndicatorsGrid() {
    final indicators = _currentData['indicators'] ?? {};
    final metrics =
        _currentData['metrics'] ?? _currentData['raw_metrics'] ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _buildSmallIndicatorCard(
            "AVLOS",
            "${indicators['avlos'] ?? 0}",
            "Hari",
            "Rata-rata rawat",
            Icons.calendar_month_rounded,
            Colors.blue,
            "Rata-rata Rawat"),
        _buildSmallIndicatorCard(
            "TOI",
            "${indicators['toi'] ?? 0}",
            "Hari",
            "Tenggang bed",
            Icons.hourglass_empty_rounded,
            Colors.orange,
            "Tenggang Bed"),
        _buildSmallIndicatorCard(
            "BTO",
            "${indicators['bto'] ?? 0}",
            "Kali",
            "Frekuensi bed",
            Icons.sync_rounded,
            Colors.purple,
            "Perputaran Bed"),
        _buildSmallIndicatorCard(
            "HP",
            "${metrics['HP'] ?? 0}",
            "Hari",
            "Total perawatan",
            Icons.airline_seat_flat_rounded,
            Colors.teal,
            "Volume Layanan"),
      ],
    );
  }

  Widget _buildSmallIndicatorCard(String title, String value, String unit,
      String desc, IconData icon, Color color, String standard) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400])),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(standard,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildDataDetailCard() {
    final raw = _currentData['metrics'] ?? _currentData['raw_metrics'] ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Detail Komponen Data",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black54)),
          const SizedBox(height: 15),
          _buildDetailRow(
              "Kapasitas Bed (A)", "${raw['A'] ?? 0} Bed", Icons.bed_rounded),
          const Divider(height: 20),
          _buildDetailRow("Pasien Keluar (D)", "${raw['D'] ?? 0} Orang",
              Icons.logout_rounded),
          const Divider(height: 20),
          _buildDetailRow("Durasi Periode (t)", "${_period['days'] ?? 0} Hari",
              Icons.timer_rounded),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!)),
          child: Icon(icon, size: 14, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryColor)),
      ],
    );
  }

  Widget _buildChartAnalysis() {
    if (_yearlyMonths.isEmpty) return const SizedBox();

    String metricKey = _selectedMetric.toLowerCase();
    Map<String, dynamic>? maxData;
    Map<String, dynamic>? minData;

    // Filter to only include months up to current if it's the current year
    bool isCurrentYear = _selectedYear == DateTime.now().year;
    int currentMonth = DateTime.now().month;

    for (var m in _yearlyMonths) {
      if (isCurrentYear && m['month'] > currentMonth) continue;

      double val = (m[metricKey] ?? 0.0).toDouble();

      if (maxData == null || val > (maxData[metricKey] ?? 0.0).toDouble()) {
        maxData = m;
      }

      if (minData == null || val < (minData[metricKey] ?? 0.0).toDouble()) {
        minData = m;
      }
    }

    if (maxData == null || minData == null) return const SizedBox();

    String unit = _selectedMetric == "BOR" ? "%" : " Hari";
    if (_selectedMetric == "BTO") unit = " Kali";

    return Row(
      children: [
        Expanded(
          child: _buildAnalysisCard(
            "Tertinggi",
            "${maxData[metricKey]}$unit",
            maxData['month_name'],
            Icons.trending_up_rounded,
            Colors.green,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildAnalysisCard(
            "Terendah",
            "${minData[metricKey]}$unit",
            minData['month_name'],
            Icons.trending_down_rounded,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(
      String label, String value, String month, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(month,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
        ],
      ),
    );
  }
}
