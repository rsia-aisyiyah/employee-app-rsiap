import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class DashboardPenyakit extends StatefulWidget {
  const DashboardPenyakit({super.key});

  @override
  State<DashboardPenyakit> createState() => _DashboardPenyakitState();
}

class _DashboardPenyakitState extends State<DashboardPenyakit> {
  final TextEditingController _tglAwalController = TextEditingController();
  final TextEditingController _tglAkhirController = TextEditingController();

  bool _isLoading = true;
  String _status = 'all';
  String _sttsDaftar = 'all';
  String _jk = 'all';

  Map<String, dynamic> _summary = {};
  List _top10 = [];
  List _deadliest = [];

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
      final params = {
        'tgl_awal': _tglAwalController.text,
        'tgl_akhir': _tglAkhirController.text,
        'status': _status,
        'stts_daftar': _sttsDaftar,
        'jk': _jk,
      };

      final List<Future<dynamic>> futures = [
        Api().getData(
            "/laporan/penyakit/summary?${Uri(queryParameters: params).query}"),
        Api().getData(
            "/laporan/penyakit/top10?${Uri(queryParameters: params).query}"),
        Api().getData(
            "/laporan/penyakit/deadliest?${Uri(queryParameters: params).query}"),
      ];

      final responses = await Future.wait(futures);

      if (responses.every((res) => res.statusCode == 200)) {
        setState(() {
          _summary = json.decode(responses[0].body)['data'] ?? {};
          _top10 = json.decode(responses[1].body)['data'] ?? [];
          _deadliest = json.decode(responses[2].body)['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal memuat beberapa data");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("10 Besar Penyakit",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
                          const SizedBox(height: 20),
                          _buildTop10Chart(),
                          const SizedBox(height: 20),
                          _buildDeadliestList(),
                          const SizedBox(height: 100),
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
              Expanded(child: _buildDateInput("Mulai", _tglAwalController)),
              const SizedBox(width: 10),
              Expanded(child: _buildDateInput("Selesai", _tglAkhirController)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildDropdown(
                      "Layanan",
                      _status,
                      {'all': 'Semua', 'Ralan': 'Ralan', 'Ranap': 'Ranap'},
                      (v) => setState(() => _status = v!))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildDropdown(
                      "Status",
                      _sttsDaftar,
                      {'all': 'Semua', 'Baru': 'Baru', 'Lama': 'Lama'},
                      (v) => setState(() => _sttsDaftar = v!))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildDropdown(
                      "Gender",
                      _jk,
                      {'all': 'Semua', 'L': 'L', 'P': 'P'},
                      (v) => setState(() => _jk = v!))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInput(String label, TextEditingController controller) {
    return InkWell(
      onTap: () => _selectDate(context, controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    color: Colors.white.withOpacity(0.7), fontSize: 9)),
            const SizedBox(height: 2),
            Text(controller.text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, Map<String, String> items,
      Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              dropdownColor: primaryColor,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white, size: 16),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              items: items.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (val) {
                onChanged(val);
                _loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard("Total Diagnosa", "${_summary['total_diagnosa'] ?? 0}",
            Icons.assignment_rounded, Colors.blue),
        _buildStatCard("Penyakit Unik", "${_summary['unique_penyakit'] ?? 0}",
            Icons.biotech_rounded, Colors.green),
        _buildStatCard("Ps. Meninggal", "${_summary['total_mati'] ?? 0}",
            Icons.person_off_rounded, Colors.red),
        _buildStatCard("Filtered", "${_summary['total_filtered'] ?? 0}",
            Icons.filter_alt_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
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

  Widget _buildTop10Chart() {
    if (_top10.isEmpty) return const SizedBox.shrink();
    int maxVal = _top10[0]['total'] ?? 1;

    return _buildVisualCard(
      "Distribusi 10 Besar Penyakit",
      Column(
        children: _top10.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          double percent = (item['total'] ?? 0) / maxVal;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                          "${idx + 1}. [${item['kd_penyakit']}] ${item['nm_penyakit']}",
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text("${item['total']} Kasus",
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey[100],
                          color: _getBarColor(idx),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text("L:${item['total_l'] ?? 0} P:${item['total_p'] ?? 0}",
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeadliestList() {
    if (_deadliest.isEmpty) return const SizedBox.shrink();

    return _buildVisualCard(
      "Kematian Terbanyak (by Condition)",
      Column(
        children: _deadliest.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Center(
                      child: Text("${idx + 1}",
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("[${item['kd_penyakit']}] ${item['nm_penyakit']}",
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text("${item['total_kasus']} Kasus Terdeteksi",
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${item['total_mati']}",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.red)),
                    const Text("MENINGGAL",
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.red)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getBarColor(int index) {
    const List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange
    ];
    return colors[index % colors.length].withOpacity(0.7);
  }
}
