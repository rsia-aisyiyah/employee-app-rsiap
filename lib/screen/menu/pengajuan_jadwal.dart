import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class PengajuanJadwal extends StatefulWidget {
  const PengajuanJadwal({super.key});

  @override
  State<PengajuanJadwal> createState() => _PengajuanJadwalState();
}

class _PengajuanJadwalState extends State<PengajuanJadwal> {
  final box = GetStorage();
  bool isLoading = true;
  bool isSaving = false;

  List employees = [];
  List filteredEmployees = [];
  List allShifts = [];
  List authorizedDepts = [];

  // Track changes: Map<String employeeId, Map<int day, String shiftCode>>
  Map<String, Map<int, String>> pendingChanges = {};
  bool _showFilters = true; // State for toggling filters

  String? selectedDept;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  TextEditingController searchController = TextEditingController();

  final List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  final double nameColumnWidth = 140.0;
  final double cellWidth = 50.0;
  final double cellHeight = 55.0;
  final double statsColumnWidth = 60.0;

  // Sync scroll controllers
  final ScrollController _hHeaderScrollController = ScrollController();
  final ScrollController _hGridScrollController = ScrollController();
  final ScrollController _vNameScrollController = ScrollController();
  final ScrollController _vGridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    // Link horizontal controllers
    _hHeaderScrollController.addListener(() {
      if (_hHeaderScrollController.offset != _hGridScrollController.offset) {
        _hGridScrollController.jumpTo(_hHeaderScrollController.offset);
      }
    });
    _hGridScrollController.addListener(() {
      if (_hGridScrollController.offset != _hHeaderScrollController.offset) {
        _hHeaderScrollController.jumpTo(_hGridScrollController.offset);
      }
    });

    // Link vertical controllers
    _vNameScrollController.addListener(() {
      if (_vNameScrollController.offset != _vGridScrollController.offset) {
        _vGridScrollController.jumpTo(_vNameScrollController.offset);
      }
    });
    _vGridScrollController.addListener(() {
      if (_vGridScrollController.offset != _vNameScrollController.offset) {
        _vNameScrollController.jumpTo(_vGridScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _hHeaderScrollController.dispose();
    _hGridScrollController.dispose();
    _vNameScrollController.dispose();
    _vGridScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchShifts(),
      _fetchEmployees(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _fetchShifts() async {
    try {
      var res = await Api().getData('/sdi/shifts');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        allShifts = body['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching shifts: $e");
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      String url =
          '/sdi/jadwal-pegawai?bulan=$selectedMonth&tahun=$selectedYear';
      if (selectedDept != null && selectedDept != 'all') {
        url += '&departemen=$selectedDept';
      }

      var res = await Api().getData(url);
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        setState(() {
          employees = body['data'] ?? [];
          filteredEmployees = employees;
          authorizedDepts = body['authorized_departments'] ?? [];
          pendingChanges.clear();
        });
      }
    } catch (e) {
      debugPrint("Error fetching employees: $e");
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees.where((emp) {
          final name = emp['nama']?.toString().toLowerCase() ?? '';
          final nik = emp['nik']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              nik.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _saveAllChanges() async {
    if (pendingChanges.isEmpty) return;

    setState(() => isSaving = true);
    try {
      List<Map<String, dynamic>> payloadData = [];
      pendingChanges.forEach((empId, changes) {
        Map<String, dynamic> row = {"id": empId};
        changes.forEach((day, shift) {
          row["h$day"] = shift;
        });
        payloadData.add(row);
      });

      Map<String, dynamic> payload = {
        "bulan": selectedMonth,
        "tahun": selectedYear,
        "data": payloadData
      };

      var res = await Api().postData(payload, '/sdi/jadwal-pegawai');
      if (res.statusCode == 200) {
        Msg.success(context, "Semua jadwal berhasil disimpan");
        _fetchEmployees();
      } else {
        var body = json.decode(res.body);
        Msg.error(context, body['message'] ?? "Gagal menyimpan jadwal");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan: $e");
    } finally {
      setState(() => isSaving = false);
    }
  }

  // --- STATS CALCULATIONS ---

  int _getDailyShiftCount(int day, String type) {
    int count = 0;
    for (var emp in filteredEmployees) {
      String empId = emp['id'].toString();
      String? shift = pendingChanges[empId]?[day] ?? emp['jadwal']?['h$day'];
      if (shift != null && shift.toLowerCase().contains(type.toLowerCase())) {
        count++;
      }
    }
    return count;
  }

  Map<String, dynamic> _getEmployeeStats(Map emp) {
    int pagi = 0, siang = 0, malam = 0, cuti = 0, libur = 0, totalShift = 0;
    double totalHours = 0;
    String empId = emp['id'].toString();

    int days = DateTime(selectedYear, selectedMonth + 1, 0).day;
    for (int d = 1; d <= days; d++) {
      String? shift = pendingChanges[empId]?[d] ?? emp['jadwal']?['h$d'];

      if (shift == null || shift == '' || shift == '-') {
        libur++;
        continue;
      }

      String lower = shift.toLowerCase();
      if (lower.contains('pagi')) {
        pagi++;
        totalHours += 7;
        totalShift++;
      } else if (lower.contains('siang')) {
        siang++;
        totalHours += 7;
        totalShift++;
      } else if (lower.contains('malam')) {
        malam++;
        totalHours += 10;
        totalShift++;
      } else if (lower.contains('cuti')) {
        cuti++;
      } else if (lower.contains('libur')) {
        libur++;
      } else {
        totalShift++;
        totalHours += 7;
      }
    }

    return {
      "P": pagi,
      "S": siang,
      "M": malam,
      "T": totalShift,
      "L": libur,
      "C": cuti,
      "H": totalHours,
      "O": totalHours - 173
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons on light header
        statusBarBrightness: Brightness.light, // For iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Modern soft background
        body: Column(
          children: [
            _buildTopHeader(),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Visibility(
                visible: _showFilters,
                child: _buildFilterAndSearch(),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          _buildSectionHeader("Jadwal Pegawai"),
                          _buildModernContainer(_buildMatrixView()),
                          const SizedBox(height: 30),
                          _buildSectionHeader("Jumlah Shift Per Tanggal"),
                          _buildModernContainer(_buildSummaryTable()),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
            ),
          ],
        ),
        bottomNavigationBar:
            pendingChanges.isNotEmpty ? _buildSaveAction() : null,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey[900],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModernContainer(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 15,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.arrow_back, color: primaryColor, size: 20),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Jadwal Pegawai",
                    style: TextStyle(
                        color: Colors.blueGrey[900],
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text("Gunakan mode landscape untuk tampilan lebih luas",
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _showFilters
                      ? primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  shape: BoxShape.circle),
              child: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: _showFilters ? primaryColor : Colors.grey[600],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickMonthYear(),
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month,
                            color: primaryColor, size: 18),
                        const SizedBox(width: 10),
                        Text("${months[selectedMonth - 1]} $selectedYear",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              if (authorizedDepts.length > 1) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDept ?? 'all',
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                        items: [
                          const DropdownMenuItem(
                              value: 'all', child: Text("Semua Unit")),
                          ...authorizedDepts.map((dept) => DropdownMenuItem(
                                value: dept['id'].toString(),
                                child: Text(dept['name'],
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => selectedDept = val);
                          _fetchEmployees();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: searchController,
              onChanged: _filterEmployees,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Cari nama atau NIK pegawai...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixView() {
    int days = DateTime(selectedYear, selectedMonth + 1, 0).day;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIXED COLUMN (NAMES)
        SizedBox(
          width: nameColumnWidth,
          child: Column(
            children: [
              _buildNameCell("Nama Pegawai / Departemen", isHeader: true),
              ...filteredEmployees.map((emp) =>
                  _buildNameCell(emp['nama'], subtitle: emp['departemen'])),
            ],
          ),
        ),
        // SCROLLABLE MATRIX + STATS
        Expanded(
          child: SingleChildScrollView(
            controller: _hGridScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (cellWidth * days) + (statsColumnWidth * 9),
              child: Column(
                children: [
                  // Dates + Stats Header
                  Row(
                    children: [
                      ...List.generate(days, (i) => _buildDateHeader(i + 1)),
                      _buildStatsHeader("P"),
                      _buildStatsHeader("S"),
                      _buildStatsHeader("M"),
                      _buildStatsHeader("Total"),
                      _buildStatsHeader("Libur"),
                      _buildStatsHeader("Cuti"),
                      _buildStatsHeader("Jam"),
                      _buildStatsHeader("Wajib"),
                      _buildStatsHeader("Lebih"),
                    ],
                  ),
                  // Matrix + Stats Rows
                  ...filteredEmployees.map((emp) {
                    var stats = _getEmployeeStats(emp);
                    return Row(
                      children: [
                        ...List.generate(days, (dayIndex) {
                          int day = dayIndex + 1;
                          return _buildShiftCell(emp, day);
                        }),
                        _buildStatsCell(stats['P'].toString()),
                        _buildStatsCell(stats['S'].toString()),
                        _buildStatsCell(stats['M'].toString()),
                        _buildStatsCell(stats['T'].toString(), isBold: true),
                        _buildStatsCell(stats['L'].toString()),
                        _buildStatsCell(stats['C'].toString()),
                        _buildStatsCell("${stats['H'].toInt()} Jam"),
                        _buildStatsCell("173 Jam", isBold: true),
                        _buildStatsCell("${stats['O'].toInt()} Jam",
                            color: stats['O'] >= 0
                                ? Colors.green[700]
                                : Colors.red[700],
                            isBold: true),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTable() {
    int days = DateTime(selectedYear, selectedMonth + 1, 0).day;
    List<String> types = ["Pagi", "Siang", "Malam", "Cuti"];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels Column
        SizedBox(
          width: nameColumnWidth,
          child: Column(
            children: [
              _buildStatsHeader("Shift", width: nameColumnWidth),
              ...types.map((t) => _buildNameCell(t, isCompact: true)),
            ],
          ),
        ),
        // Scrolled Data
        Expanded(
          child: SingleChildScrollView(
            controller: _hHeaderScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (cellWidth * days) + (statsColumnWidth * 9),
              child: Column(
                children: [
                  // Date Header for Summary
                  Row(
                    children:
                        List.generate(days, (i) => _buildDateHeader(i + 1)),
                  ),
                  // Counts Data
                  ...types.map((type) => Row(
                        children: [
                          ...List.generate(days, (dIndex) {
                            int day = dIndex + 1;
                            int count = _getDailyShiftCount(day, type);
                            DateTime date =
                                DateTime(selectedYear, selectedMonth, day);
                            bool isSunday = date.weekday == DateTime.sunday;

                            return Container(
                              width: cellWidth,
                              height: cellHeight * 0.8,
                              decoration: BoxDecoration(
                                color:
                                    _getSummaryRowColor(type, count, isSunday),
                                border: Border.all(
                                    color: Colors.grey[100]!, width: 0.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: count > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSunday ? Colors.red : Colors.black87,
                                ),
                              ),
                            );
                          }),
                          // Trailing empty for alignment
                          SizedBox(width: statsColumnWidth * 9),
                        ],
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getSummaryRowColor(String type, int count, bool isSunday) {
    if (isSunday) return Colors.red[50]!;
    if (count == 0) return Colors.white;

    switch (type) {
      case "Pagi":
        return const Color(0xFFE0F2FE);
      case "Siang":
        return const Color(0xFFFEF9C3);
      case "Malam":
        return const Color(0xFFDBEAFE);
      case "Cuti":
        return const Color(0xFFFFEDD5);
      default:
        return Colors.white;
    }
  }

  // --- UI ATOMS ---

  Widget _buildNameCell(String? name,
      {String? subtitle, bool isHeader = false, bool isCompact = false}) {
    return Container(
      width: nameColumnWidth,
      height: isCompact ? cellHeight * 0.8 : cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(color: const Color(0xFFF1F5F9), width: 0.5),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isHeader ? 11 : 10,
              fontWeight: isHeader ? FontWeight.w800 : FontWeight.w700,
              color: isHeader ? Colors.blueGrey[800] : const Color(0xFF1E293B),
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 8,
                    color: Colors.blueGrey[400],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(int day) {
    DateTime date = DateTime(selectedYear, selectedMonth, day);
    bool isSunday = date.weekday == DateTime.sunday;

    return Container(
      width: cellWidth,
      height: cellHeight,
      decoration: BoxDecoration(
        color: isSunday ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(DateFormat('dd').format(date),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isSunday
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF334155))),
          Text(DateFormat('E').format(date).toUpperCase(),
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSunday
                      ? const Color(0xFFE11D48).withOpacity(0.7)
                      : Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(String label, {double? width}) {
    return Container(
      width: width ?? statsColumnWidth,
      height: cellHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey[800])),
    );
  }

  Widget _buildStatsCell(String value, {Color? color, bool isBold = false}) {
    return Container(
      width: statsColumnWidth,
      height: cellHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1F5F9), width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(value,
          style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: color ?? const Color(0xFF475569))),
    );
  }

  Widget _buildShiftCell(Map emp, int day) {
    String empId = emp['id'].toString();
    String? currentShift =
        pendingChanges[empId]?[day] ?? emp['jadwal']?['h$day'];
    bool isChanged = pendingChanges[empId]?.containsKey(day) ?? false;

    DateTime date = DateTime(selectedYear, selectedMonth, day);
    bool isSunday = date.weekday == DateTime.sunday;

    return InkWell(
      onTap: () => _showShiftPicker(emp, day),
      child: Container(
        width: cellWidth,
        height: cellHeight,
        decoration: BoxDecoration(
          color: isChanged
              ? primaryColor.withOpacity(0.08)
              : (isSunday
                  ? const Color(0xFFFFF1F2).withOpacity(0.5)
                  : Colors.white),
          border: Border.all(
              color: isChanged ? primaryColor : const Color(0xFFF1F5F9),
              width: isChanged ? 1 : 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          (currentShift == null || currentShift == '' || currentShift == '-')
              ? '-'
              : currentShift,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isChanged ? FontWeight.w900 : FontWeight.w600,
            color: isSunday
                ? const Color(0xFFE11D48)
                : _getShiftColor(currentShift ?? '-'),
          ),
        ),
      ),
    );
  }

  void _showShiftPicker(Map emp, int day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text("Pilih Shift: ${emp['nama']}",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Tanggal $day ${months[selectedMonth - 1]}",
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: allShifts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildShiftButton(null, emp, day);
                    return _buildShiftButton(allShifts[index - 1], emp, day);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftButton(Map? shift, Map emp, int day) {
    String empId = emp['id'].toString();
    String? currentVal = pendingChanges[empId]?[day] ?? emp['jadwal']?['h$day'];
    bool isSelected = shift == null
        ? (currentVal == null || currentVal == '' || currentVal == '-')
        : (currentVal == shift['shift']);

    return InkWell(
      onTap: () {
        setState(() {
          if (!pendingChanges.containsKey(empId)) pendingChanges[empId] = {};
          pendingChanges[empId]![day] = shift?['shift'] ?? '';
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shift?['shift'] ?? "Libur / Kosong",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? primaryColor : Colors.black87),
            ),
            if (shift != null)
              Text("${shift['jam_masuk']} - ${shift['jam_pulang']}",
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveAction() {
    int count = 0;
    pendingChanges.forEach((_, changes) => count += changes.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5))
      ]),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$count perubahan",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text("Belum disimpan",
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: isSaving ? null : _saveAllChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Simpan Semua",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _pickMonthYear() {
    int tempMonth = selectedMonth;
    int tempYear = selectedYear;

    FixedExtentScrollController monthController =
        FixedExtentScrollController(initialItem: tempMonth - 1);
    FixedExtentScrollController yearController = FixedExtentScrollController(
        initialItem: tempYear - (DateTime.now().year - 1));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          height: 350,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
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
              const Text(
                "Pilih Periode",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Highlight Box
                    Container(
                      height: 45,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: primaryColor.withOpacity(0.1), width: 1),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: monthController,
                            itemExtent: 45,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) =>
                                tempMonth = index + 1,
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: months.length,
                              builder: (context, index) => Center(
                                child: Text(
                                  months[index],
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: yearController,
                            itemExtent: 45,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) =>
                                tempYear = DateTime.now().year - 1 + index,
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 5, // Increased range
                              builder: (context, index) => Center(
                                child: Text(
                                  (DateTime.now().year - 1 + index).toString(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedMonth = tempMonth;
                    selectedYear = tempYear;
                  });
                  Navigator.pop(context);
                  _fetchEmployees();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text("Terapkan Periode",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getShiftColor(String shift) {
    String lower = shift.toLowerCase();
    if (lower.contains('pagi')) return Colors.blue[700]!;
    if (lower.contains('siang')) return Colors.orange[800]!;
    if (lower.contains('malam')) return Colors.purple[700]!;
    if (lower.contains('cuti')) return Colors.red[700]!;
    if (lower == '-' || lower == '') return Colors.grey[400]!;
    return primaryColor;
  }
}
