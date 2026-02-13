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
  String _selectedPoli = 'all';
  String _selectedDokter = 'all';
  String _selectedPoliName = 'Semua Unit/Poli';
  String _selectedDokterName = 'Semua Dokter';

  List<dynamic> _poliList = [];
  List<dynamic> _dokterList = [];

  // Mode and year for yearly period
  bool _showFilters = true;
  String _mode = 'harian'; // 'harian' or 'tahunan'
  int _selectedYear = DateTime.now().year;

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
      String queryParams;
      String filterParams =
          "&status_lanjut=$_statusLanjut&kd_poli=$_selectedPoli&kd_dokter=$_selectedDokter";

      if (_mode == 'tahunan') {
        queryParams = "?mode=tahunan&tahun=$_selectedYear$filterParams";
      } else {
        queryParams =
            "?mode=harian&tgl_awal=${_tglAwalController.text}&tgl_akhir=${_tglAkhirController.text}$filterParams";
      }

      final url = "/dashboard/visits$queryParams";
      final res = await Api().getData(url);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _data = body['data'];
          _poliList = _data['poli_list'] ?? [];
          _dokterList = _data['dokter_list'] ?? [];
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
                          // Monthly chart for yearly mode
                          if (_mode == 'tahunan') ...[
                            _buildMonthlyChart(),
                            const SizedBox(height: 20),
                          ],
                          _buildTrendIndicator(),
                          const SizedBox(height: 20),
                          // Daily chart only for harian mode
                          if (_mode == 'harian') ...[
                            _buildVisitChart(),
                            const SizedBox(height: 20),
                          ],
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
                          if (_selectedDokter == 'all') ...[
                            _buildTopDoctorsList(),
                            const SizedBox(height: 20),
                          ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filter Statistik",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _showFilters = !_showFilters),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _showFilters
                        ? Colors.white.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    _showFilters ? Icons.tune : Icons.filter_list,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showFilters
                ? Column(
                    children: [
                      // Mode Selector
                      Row(
                        children: [
                          Expanded(
                            child: _buildModeButton(
                                'harian', 'Harian', Icons.calendar_today),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModeButton(
                                'tahunan', 'Tahunan', Icons.event_note),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Parameter Content
                      _mode == 'harian'
                          ? _buildHarianSection()
                          : _buildTahunanSection(),

                      const SizedBox(height: 12),

                      // Status and Poliklinik (Side by side)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusDropdown(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPoliPicker(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dokter Selection
                      _buildDokterPicker(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHarianSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDateInput("Mulai", _tglAwalController),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDateInput("Selesai", _tglAkhirController),
        ),
      ],
    );
  }

  Widget _buildTahunanSection() {
    return _buildYearPicker();
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.layers_outlined, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusLanjut,
                dropdownColor: primaryColor,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
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

  Widget _buildPoliPicker() {
    return GestureDetector(
      onTap: () => _showPoliSearch(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_hospital_outlined,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedPoliName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showPoliSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PoliSearchSheet(
        poliList: _poliList,
        onSelected: (kd, name) {
          setState(() {
            _selectedPoli = kd;
            _selectedPoliName = name;
          });
          _loadData();
        },
      ),
    );
  }

  Widget _buildDokterPicker() {
    return GestureDetector(
      onTap: () => _showDokterSearch(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_search, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedDokterName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showDokterSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DokterSearchSheet(
        dokterList: _dokterList,
        onSelected: (kd, name) {
          setState(() {
            _selectedDokter = kd;
            _selectedDokterName = name;
          });
          _loadData();
        },
      ),
    );
  }

  Widget _buildModeButton(String mode, String label, IconData icon) {
    bool isActive = _mode == mode;
    return InkWell(
      onTap: () {
        setState(() => _mode = mode);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? primaryColor : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? primaryColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearPicker() {
    List<int> years = List.generate(11, (i) => DateTime.now().year - 5 + i);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: primaryColor,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          items: years.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text("Tahun $year"),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedYear = val);
              _loadData();
            }
          },
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

  Widget _buildMonthlyChart() {
    List monthlyData = _data['monthly_breakdown'] ?? [];

    // Empty state widget
    if (monthlyData.isEmpty) {
      return _buildVisualCard(
        "Tren Kunjungan Bulanan ($_selectedYear)",
        Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "Tidak ada data kunjungan",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "untuk tahun $_selectedYear",
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    // Create bar chart data
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < monthlyData.length; i++) {
      var item = monthlyData[i];
      double value = (item['total'] ?? 0).toDouble();
      if (value > maxY) maxY = value;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: primaryColor,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return _buildVisualCard(
      "Tren Kunjungan Bulanan ($_selectedYear)",
      Column(
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2, // Add 20% padding
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey[800]!,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String month =
                          monthlyData[group.x.toInt()]['nama_bulan'] ?? '';
                      return BarTooltipItem(
                        '$month\n${rod.toY.toInt()} Pasien',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= monthlyData.length) {
                          return const SizedBox.shrink();
                        }
                        // Show abbreviated month names
                        List<String> monthAbbr = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'Mei',
                          'Jun',
                          'Jul',
                          'Agu',
                          'Sep',
                          'Okt',
                          'Nov',
                          'Des'
                        ];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            monthAbbr[idx],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[100],
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
          const SizedBox(height: 15),
          _buildMonthlyInsights(monthlyData),
        ],
      ),
    );
  }

  Widget _buildMonthlyInsights(List monthlyData) {
    if (monthlyData.isEmpty) return const SizedBox.shrink();

    // Find max and min months
    var maxMonth = monthlyData
        .reduce((a, b) => (a['total'] ?? 0) > (b['total'] ?? 0) ? a : b);
    var minMonth = monthlyData
        .reduce((a, b) => (a['total'] ?? 0) < (b['total'] ?? 0) ? a : b);

    return Column(
      children: [
        _buildMonthlyInsightRow(
          "Puncak Kunjungan",
          maxMonth['nama_bulan'] ?? '-',
          "${maxMonth['total'] ?? 0} Pasien",
          Colors.green,
          Icons.trending_up_rounded,
        ),
        const SizedBox(height: 8),
        _buildMonthlyInsightRow(
          "Terendah",
          minMonth['nama_bulan'] ?? '-',
          "${minMonth['total'] ?? 0} Pasien",
          Colors.orange,
          Icons.trending_down_rounded,
        ),
      ],
    );
  }

  Widget _buildMonthlyInsightRow(
      String label, String month, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8),
                  ),
                ),
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoliSearchSheet extends StatefulWidget {
  final List<dynamic> poliList;
  final Function(String, String) onSelected;

  const _PoliSearchSheet({
    required this.poliList,
    required this.onSelected,
  });

  @override
  State<_PoliSearchSheet> createState() => _PoliSearchSheetState();
}

class _PoliSearchSheetState extends State<_PoliSearchSheet> {
  List<dynamic> _filteredList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredList = widget.poliList;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = widget.poliList;
      } else {
        _filteredList = widget.poliList
            .where((p) => p['nm_poli']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Poliklinik / Unit",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _searchController,
                    onChanged: _filter,
                    decoration: InputDecoration(
                      hintText: "Cari nama poli...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _filteredList.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[100],
                        child: const Icon(Icons.local_hospital,
                            color: Colors.grey),
                      ),
                      title: const Text("Semua Unit / Poli"),
                      onTap: () {
                        widget.onSelected('all', 'Semua Unit / Poli');
                        Navigator.pop(context);
                      },
                    );
                  }

                  var poli = _filteredList[index - 1];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.local_hospital_outlined,
                          color: primaryColor),
                    ),
                    title: Text(poli['nm_poli']),
                    onTap: () {
                      widget.onSelected(
                        poli['kd_poli'].toString(),
                        poli['nm_poli'].toString(),
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DokterSearchSheet extends StatefulWidget {
  final List<dynamic> dokterList;
  final Function(String, String) onSelected;

  const _DokterSearchSheet({
    required this.dokterList,
    required this.onSelected,
  });

  @override
  State<_DokterSearchSheet> createState() => _DokterSearchSheetState();
}

class _DokterSearchSheetState extends State<_DokterSearchSheet> {
  List<dynamic> _filteredList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredList = widget.dokterList;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = widget.dokterList;
      } else {
        _filteredList = widget.dokterList.where((d) {
          final name = d['nm_dokter'].toString().toLowerCase();
          final sps =
              (d['spesialis']?['nm_sps'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || sps.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Dokter Spesialis",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _searchController,
                    onChanged: _filter,
                    decoration: InputDecoration(
                      hintText: "Cari nama atau spesialis...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _filteredList.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[100],
                        child: const Icon(Icons.people, color: Colors.grey),
                      ),
                      title: const Text("Semua Dokter"),
                      onTap: () {
                        widget.onSelected('all', 'Semua Dokter');
                        Navigator.pop(context);
                      },
                    );
                  }

                  var dokter = _filteredList[index - 1];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: primaryColor),
                    ),
                    title: Text(dokter['nm_dokter']),
                    subtitle: Text(
                      dokter['spesialis']?['nm_sps'] ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      widget.onSelected(
                        dokter['kd_dokter'].toString(),
                        dokter['nm_dokter'].toString(),
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
