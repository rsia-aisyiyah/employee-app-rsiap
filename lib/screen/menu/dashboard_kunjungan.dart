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
  String _tglRanap = 'keluar';
  String _selectedPoli = 'all';
  String _selectedDokter = 'all';
  String _selectedPoliName = 'Semua Unit/Poli';
  String _selectedDokterName = 'Semua Dokter';

  List<dynamic> _poliList = [];
  List<dynamic> _dokterList = [];

  // Mode and year for yearly period
  bool _showFilters = false;
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
          "&status_lanjut=$_statusLanjut&kd_poli=$_selectedPoli&kd_dokter=$_selectedDokter&tgl_ranap=$_tglRanap";

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
          _poliList = _data['poli'] ?? [];
          _dokterList = _data['dokter'] ?? [];
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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
                            if (_statusLanjut == 'Ralan') ...[
                              _buildPoliSection(),
                              const SizedBox(height: 25),
                            ],
                          ],
                          _buildTrendIndicator(),
                          const SizedBox(height: 20),
                          // Daily chart only for harian mode
                          if (_mode == 'harian') ...[
                            _buildVisitChart(),
                            const SizedBox(height: 20),
                            if (_statusLanjut == 'Ralan') ...[
                              _buildPoliSection(),
                              const SizedBox(height: 25),
                            ],
                          ],
                           if (_statusLanjut == 'Ranap' &&
                              _data['inpatient_care'] != null) ...[
                            _buildInpatientStats(),
                            const SizedBox(height: 20),
                            _buildKategoriSection(),
                            const SizedBox(height: 20),
                            _buildKelasSection(),
                            const SizedBox(height: 20),
                            _buildBangsalSection(),
                            const SizedBox(height: 20),
                          ],
                          _buildRegistrationBreakdown(),
                          const SizedBox(height: 20),
                          _buildDomicileList(),
                          const SizedBox(height: 20),
                          _buildAgeDistribution(),
                          const SizedBox(height: 20),
                          _buildCaraBayarList(),
                          if (_data['batal'] != null && (_data['batal']['total'] ?? 0) > 0) ...[
                            const SizedBox(height: 20),
                            _buildCancellationAnalysis(),
                          ],
                          if (_selectedDokter == 'all') ...[
                            const SizedBox(height: 25),
                            _buildTopDoctorsList(),
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25, top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter Statistik",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                   const SizedBox(height: 6),
                  Text(
                    _mode == 'harian'
                        ? "Periode: ${_tglAwalController.text} s/d ${_tglAkhirController.text}"
                        : "Periode: Tahun $_selectedYear",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Klik ikon ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 13,
                        ),
                        Text(
                          " untuk mengatur filter",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showFilters = !_showFilters),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    _showFilters ? Icons.keyboard_arrow_up : Icons.tune,
                    color: Colors.white,
                    size: 22,
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
                      if (_statusLanjut == 'Ranap' || _statusLanjut == 'all') ...[
                        const SizedBox(height: 12),
                        _buildBasisRanapDropdown(),
                      ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
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

  Widget _buildBasisRanapDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _tglRanap,
                dropdownColor: primaryColor,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 'keluar', child: Text("Tgl Keluar (Discharge)")),
                  DropdownMenuItem(value: 'masuk', child: Text("Tgl Masuk (Admission)")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _tglRanap = val);
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
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
        if (_mode != mode) {
          setState(() => _mode = mode);
          _loadData();
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          boxShadow: isActive 
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] 
            : null,
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? primaryColor : Colors.white, size: 16),
            const SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.calendar_month, color: Colors.white.withOpacity(0.8), size: 14),
              ],
            ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 8))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
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

  Widget _buildPoliSection() {
    if (_poliList.isEmpty) return const SizedBox.shrink();

    // Sort by total descending
    List sortedPoli = List.from(_poliList);
    sortedPoli.sort((a, b) => (b['total'] ?? 0).compareTo(a['total'] ?? 0));

    final int maxVal = sortedPoli.isNotEmpty ? (sortedPoli[0]['total'] ?? 1) : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Berdasarkan Unit / Poliklinik",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  Text(
                    "Kunjungan pasien per poliklinik/unit",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "Geser",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.swipe_left_rounded,
                    size: 16,
                    color: Colors.lightBlue.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sortedPoli.length,
              itemBuilder: (context, index) {
                final item = sortedPoli[index];
                final String label = item['label'] ?? '-';
                final int val = item['total'] ?? 0;
                final double ratio = (val / maxVal).clamp(0.1, 1.0);
                final double barHeight = ratio * 140;

                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 15),
                  child: Column(
                    children: [
                      const Spacer(),
                      // Number above bar
                      Text(
                        val.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // The Rounded Bar
                      Container(
                        height: barHeight,
                        width: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7DD3FC), // Sky blue bar
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7DD3FC).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Poli Name below bar
                      SizedBox(
                        height: 40,
                        child: Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKelasSection() {
    List kelas = _data['kelas'] ?? [];
    if (kelas.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kunjungan per Kelas",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "Berdasarkan kelas perawatan",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${kelas.length} Kelas",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...kelas.map((item) {
            int total = item['total'] ?? 0;
            int summaryTotal = _data['summary']?['total'] ?? 1;
            if (summaryTotal == 0) summaryTotal = 1;
            double percent = total / summaryTotal;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Icon(
                              Icons.meeting_room_outlined,
                              size: 14,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item['label'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "$total",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBangsalSection() {
    List bangsal = _data['bangsal'] ?? [];
    if (bangsal.isEmpty) return const SizedBox.shrink();

    // Sort by total descending
    bangsal.sort((a, b) => (b['total'] ?? 0).compareTo(a['total'] ?? 0));

    int maxVal = bangsal.isNotEmpty ? (bangsal[0]['total'] ?? 1) : 1;
    if (maxVal == 0) maxVal = 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Berdasarkan Bangsal / Kamar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A), // Darker blue for title
                    ),
                  ),
                  Text(
                    "Kunjungan pasien per bangsal perawatan",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "Geser",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.swipe_left_rounded,
                    size: 16,
                    color: Colors.lightBlue.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: bangsal.length,
              itemBuilder: (context, index) {
                final item = bangsal[index];
                final String label = item['label'] ?? '-';
                final int val = item['total'] ?? 0;
                final double ratio = (val / maxVal).clamp(0.1, 1.0);
                final double barHeight = ratio * 140;

                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 15),
                  child: Column(
                    children: [
                      const Spacer(),
                      // Number above bar
                      Text(
                        val.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // The Rounded Bar
                      Container(
                        height: barHeight,
                        width: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7DD3FC), // Sky blue bar
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7DD3FC).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Ward Name below bar
                      SizedBox(
                        height: 40,
                        child: Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
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

  Widget _buildProgressBar(String label, int val, Color color, {List? details}) {
    int total = _data['summary']?['total'] ?? 1;
    if (total == 0) total = 1;
    double percent = val / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
              Text("$val (${(percent * 100).toStringAsFixed(1)}%)",
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: const Color(0xFFF1F5F9),
              color: color,
              minHeight: 8,
            ),
          ),
          if (details != null && details.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildStackedBar(details, val),
          ],
        ],
      ),
    );
  }

  Widget _buildStackedBar(List details, int parentTotal) {
    if (parentTotal == 0) parentTotal = 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: const Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              width: double.infinity,
              child: Row(
                children: details.map((d) {
                  double segmentPercent = (d['total'] ?? 0) / parentTotal;
                  return Expanded(
                    flex: (segmentPercent * 1000).toInt().clamp(1, 1000),
                    child: Container(
                      color: _getClassColor(d['label']),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: details.map((d) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _getClassColor(d['label']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${d['label']} (${d['total']})",
                    style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getClassColor(String label) {
    switch (label) {
      case 'Kelas 1':
        return Colors.blue;
      case 'Kelas 2':
        return Colors.green;
      case 'Kelas 3':
        return Colors.orange;
      case 'Kelas VIP':
      case 'VIP':
        return Colors.purple;
      case 'Kelas Utama':
      case 'Utama':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCaraBayarList() {
    List caraBayar = _data['cara_bayar'] ?? [];
    return _buildVisualCard(
        "Berdasarkan Cara Bayar",
        Column(
          children: caraBayar
              .map((item) => _buildProgressBar(
                  item['label'], 
                  item['total'], 
                  Colors.blueAccent,
                  details: item['details']))
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
            int maxTotal = doctors.isNotEmpty ? (doctors[0]['total'] ?? 1) : 1;
            
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
                            item['total'], maxTotal),
                        if ((item['details'] != null && (item['details'] as List).isNotEmpty) || (item['status'] != null && (item['status'] as List).isNotEmpty)) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: const Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cara Bayar Section
                                if (item['details'] != null && (item['details'] as List).isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: SizedBox(
                                      height: 5,
                                      width: double.infinity,
                                      child: Row(
                                        children: (item['details'] as List).map((d) {
                                          double segmentPercent = (d['total'] ?? 0) / (item['total'] ?? 1);
                                          return Expanded(
                                            flex: (segmentPercent * 1000).toInt().clamp(1, 1000),
                                            child: Container(
                                              color: _getPaymentColor(d['label']),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: (item['details'] as List).map((d) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: _getPaymentColor(d['label']),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${d['label']} (${d['total']})",
                                            style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Status Pasien Section (Baru/Lama)
                                if (item['status'] != null && (item['status'] as List).isNotEmpty) ...[
                                  const Text("Status Pasien:", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: SizedBox(
                                      height: 5,
                                      width: double.infinity,
                                      child: Row(
                                        children: (item['status'] as List).map((d) {
                                          double segmentPercent = (d['total'] ?? 0) / (item['total'] ?? 1);
                                          return Expanded(
                                            flex: (segmentPercent * 1000).toInt().clamp(1, 1000),
                                            child: Container(
                                              color: _getStatusColor(d['label']),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: (item['status'] as List).map((d) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(d['label']),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Pasien ${d['label']} (${d['total']})",
                                            style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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

  Color _getPaymentColor(String label) {
    String l = label.toLowerCase();
    if (l.contains('non pbi')) return Colors.blue;
    if (l.contains('pbi') && !l.contains('non pbi')) return Colors.orange;
    if (l.contains('umum')) return Colors.purple;
    return Colors.grey;
  }

  Color _getStatusColor(String label) {
    String l = label.toLowerCase();
    if (l == 'baru') return Colors.pink;
    if (l == 'lama') return Colors.lightBlue;
    return Colors.grey;
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

  Widget _buildKategoriSection() {
    List kategori = _data['kategori'] ?? [];
    if (kategori.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kategori Pasien",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "Berdasarkan bangsal perawatan",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${kategori.length} Kategori",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...kategori.map((item) {
            int total = item['total'] ?? 0;
            int summaryTotal = _data['summary']?['total'] ?? 1;
            if (summaryTotal == 0) summaryTotal = 1;
            double percent = total / summaryTotal;

            return InkWell(
              onTap: () => _showDetailPasien(item['label']),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Icon(
                                _getCategoryIcon(item['label']),
                                size: 14,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item['label'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "$total",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percent > 1 ? 1 : percent,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String label) {
    switch (label) {
      case 'Anak':
        return Icons.child_care;
      case 'Kandungan':
        return Icons.pregnant_woman;
      case 'Perina':
        return Icons.baby_changing_station;
      case 'VK':
        return Icons.pregnant_woman_rounded;
      case 'Umum':
        return Icons.people_outline;
      case 'Isolasi':
        return Icons.masks_outlined;
      case 'ICU':
        return Icons.monitor_heart;
      default:
        return Icons.bed_outlined;
    }
  }

  void _showDetailPasien(String category) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailPasienSheet(
        category: category,
        tglAwal: _tglAwalController.text,
        tglAkhir: _tglAkhirController.text,
        kdPoli: _selectedPoli,
        kdDokter: _selectedDokter,
        statusLanjut: _statusLanjut,
        mode: _mode,
        year: _selectedYear,
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

class _DetailPasienSheet extends StatefulWidget {
  final String category;
  final String tglAwal;
  final String tglAkhir;
  final String kdPoli;
  final String kdDokter;
  final String statusLanjut;
  final String mode;
  final int year;

  const _DetailPasienSheet({
    required this.category,
    required this.tglAwal,
    required this.tglAkhir,
    required this.kdPoli,
    required this.kdDokter,
    required this.statusLanjut,
    required this.mode,
    required this.year,
  });

  @override
  State<_DetailPasienSheet> createState() => _DetailPasienSheetState();
}

class _DetailPasienSheetState extends State<_DetailPasienSheet> {
  bool _isLoading = true;
  List<dynamic> _allData = [];
  List<dynamic> _filteredData = [];
  final TextEditingController _searchController = TextEditingController();
  
  String _filterDoctor = 'all';
  String _filterTindakan = 'all';
  String _filterAsalPasien = 'all';
  List<String> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, String> params = {
        'kd_poli': widget.kdPoli,
        'kd_dokter': widget.kdDokter,
        'status_lanjut': widget.statusLanjut,
        'mode': widget.mode,
        'kategori': widget.category,
        'asal_pasien': _filterAsalPasien,
      };

      if (widget.mode == 'tahunan') {
        params['tahun'] = widget.year.toString();
      } else {
        params['tgl_awal'] = widget.tglAwal;
        params['tgl_akhir'] = widget.tglAkhir;
      }

      final url = "/dashboard/visits/details?${Uri(queryParameters: params).query}";
      debugPrint("FETCH DETAILS URL: $url");
      final res = await Api().getData(url);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = body['data'] as List;
        
        // Extract unique doctors
        final docs = data.map((e) => e['nm_dokter'].toString()).toSet().toList();
        docs.sort();

        setState(() {
          _allData = data;
          _filteredData = data;
          _doctors = docs;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredData = _allData.where((p) {
        final matchSearch = p['nm_pasien'].toString().toLowerCase().contains(query) ||
            p['no_rkm_medis'].toString().toLowerCase().contains(query);
        
        final matchDoc = _filterDoctor == 'all' || p['nm_dokter'] == _filterDoctor;
        
        final matchTindakan = _filterTindakan == 'all' || 
            (p['metode_persalinan'] ?? '-') == _filterTindakan;

        return matchSearch && matchDoc && matchTindakan;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
            _buildHeader(),
            _buildFilterSection(),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredData.isEmpty
                      ? const Center(child: Text("Data tidak ditemukan"))
                      : ListView.builder(
                          controller: controller,
                          itemCount: _filteredData.length,
                          itemBuilder: (context, index) => _buildPatientItem(_filteredData[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
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
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Detail Pasien ${widget.category}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${_filteredData.length} Pasien",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Total ditemukan dalam periode ini",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => _applyFilter(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "Cari Nama atau No. Rekam Medis...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: primaryColor),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDoctorDropdown()),
              if (widget.category == 'VK') ...[
                const SizedBox(width: 10),
                Expanded(child: _buildTindakanDropdown()),
              ],
              if (widget.category == 'Perina') ...[
                const SizedBox(width: 10),
                Expanded(child: _buildAsalPasienDropdown()),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterDoctor,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor, size: 20),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: [
            const DropdownMenuItem(value: 'all', child: Text("Semua Dokter")),
            ..._doctors.map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(d, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (v) {
            setState(() => _filterDoctor = v!);
            _applyFilter();
          },
        ),
      ),
    );
  }

  Widget _buildAsalPasienDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterAsalPasien,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor, size: 20),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: 'all', child: Text("Semua Perina")),
            DropdownMenuItem(value: 'BBL', child: Text("BBL")),
            DropdownMenuItem(value: 'Perawatan', child: Text("Perawatan")),
          ],
          onChanged: (v) {
            setState(() => _filterAsalPasien = v!);
            _loadDetails();
          },
        ),
      ),
    );
  }

  Widget _buildTindakanDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterTindakan,
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Colors.black),
          items: const [
            DropdownMenuItem(value: 'all', child: Text("Semua Tindakan")),
            DropdownMenuItem(value: 'SC', child: Text("SC")),
            DropdownMenuItem(value: 'Kuret', child: Text("Kuret")),
            DropdownMenuItem(value: 'Ponek', child: Text("Ponek")),
            DropdownMenuItem(value: 'Partus', child: Text("Partus")),
            DropdownMenuItem(value: '-', child: Text("Tanpa Tindakan")),
          ],
          onChanged: (v) {
            setState(() => _filterTindakan = v!);
            _applyFilter();
          },
        ),
      ),
    );
  }

  Widget _buildPatientItem(var p) {
    String tindakan = p['metode_persalinan'] ?? '-';
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['nm_pasien'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${p['no_rkm_medis']} • ${p['jk']} • ${p['tgl_registrasi']}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.category == 'VK') _buildTindakanBadge(tindakan),
              if (widget.category == 'Perina') _buildAsalPasienBadge(p['asal_pasien'] ?? '-'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.person_rounded, size: 14, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p['nm_dokter'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.meeting_room_rounded, size: 14, color: Colors.orange),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p['nm_bangsal'] ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTindakanBadge(String t) {
    Color bg = Colors.green[50]!;
    Color text = Colors.green[700]!;
    
    if (t == 'SC') { bg = Colors.red[50]!; text = Colors.red[700]!; }
    else if (t == 'Kuret') { bg = Colors.amber[50]!; text = Colors.amber[700]!; }
    else if (t == 'Ponek') { bg = Colors.purple[50]!; text = Colors.purple[700]!; }
    else if (t == '-') { bg = Colors.grey[100]!; text = Colors.grey[600]!; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)),
    );
  }

  Widget _buildAsalPasienBadge(String t) {
    Color bg = Colors.blue[50]!;
    Color text = Colors.blue[700]!;

    if (t == 'BBL') {
      bg = Colors.teal[50]!;
      text = Colors.teal[700]!;
    } else if (t == 'Perawatan') {
      bg = Colors.orange[50]!;
      text = Colors.orange[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)),
    );
  }
}
