import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class PengajuanJadwalTambahan extends StatefulWidget {
  const PengajuanJadwalTambahan({super.key});

  @override
  State<PengajuanJadwalTambahan> createState() => _PengajuanJadwalTambahanState();
}

class _PengajuanJadwalTambahanState extends State<PengajuanJadwalTambahan> {
  final box = GetStorage();
  bool isLoading = true;
  bool isSaving = false;

  List employees = [];
  List filteredEmployees = [];
  List allShifts = [];
  List authorizedDepts = [];

  // Track changes: Map<String employeeId, Map<int day, String shiftCode>>
  Map<String, Map<int, String>> pendingChanges = {};
  Map<String, String> holidays = {}; // Key: YYYY-MM-DD, Value: Holiday Name
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
  final ScrollController _hMatrixHeaderScrollController = ScrollController();
  final ScrollController _vNameScrollController = ScrollController();
  final ScrollController _vGridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    // Link horizontal controllers
    _hMatrixHeaderScrollController.addListener(() {
      double offset = _hMatrixHeaderScrollController.offset;
      if (_hGridScrollController.hasClients && _hGridScrollController.offset != offset) {
        _hGridScrollController.jumpTo(offset);
      }
      if (_hHeaderScrollController.hasClients && _hHeaderScrollController.offset != offset) {
        _hHeaderScrollController.jumpTo(offset);
      }
    });

    _hGridScrollController.addListener(() {
      double offset = _hGridScrollController.offset;
      if (_hMatrixHeaderScrollController.hasClients && _hMatrixHeaderScrollController.offset != offset) {
        _hMatrixHeaderScrollController.jumpTo(offset);
      }
      if (_hHeaderScrollController.hasClients && _hHeaderScrollController.offset != offset) {
        _hHeaderScrollController.jumpTo(offset);
      }
    });

    _hHeaderScrollController.addListener(() {
      double offset = _hHeaderScrollController.offset;
      if (_hMatrixHeaderScrollController.hasClients && _hMatrixHeaderScrollController.offset != offset) {
        _hMatrixHeaderScrollController.jumpTo(offset);
      }
      if (_hGridScrollController.hasClients && _hGridScrollController.offset != offset) {
        _hGridScrollController.jumpTo(offset);
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
    _hMatrixHeaderScrollController.dispose();
    _vNameScrollController.dispose();
    _vGridScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchShifts(),
      _fetchEmployees(),
      _fetchHolidays(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _fetchHolidays() async {
    try {
      var res = await http
          .get(Uri.parse('https://libur.deno.dev/api?year=$selectedYear'))
          .timeout(const Duration(seconds: 5)); // Prevent hanging if API is slow
      if (res.statusCode == 200) {
        List data = json.decode(res.body);
        Map<String, String> fetchedHolidays = {};
        for (var item in data) {
          fetchedHolidays[item['date']] = item['name'];
        }
        setState(() {
          holidays = fetchedHolidays;
        });
      }
    } catch (e) {
      debugPrint("Error fetching holidays (API might be down): $e");
    }
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
          '/sdi/jadwal-tambahan?bulan=$selectedMonth&tahun=$selectedYear&mode=edit';
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

      var res = await Api().postData(payload, '/sdi/jadwal-tambahan');
      if (res.statusCode == 200) {
        Msg.success(context, "Jadwal tambahan berhasil disimpan");
        _fetchEmployees();
      } else {
        var body = json.decode(res.body);
        Msg.error(context, body['message'] ?? "Gagal menyimpan jadwal tambahan");
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

  double _getShiftDuration(String? shift) {
    if (shift == null || shift.isEmpty || shift == '-' || shift.toLowerCase().contains('libur') || shift.toLowerCase().contains('cuti')) {
      return 0.0;
    }
    String lower = shift.toLowerCase();
    
    if (lower == 'pagi1' || lower == 'pagi2' || lower == 'pagi9' || lower == 'midle pagi4') {
      return 6.0;
    }
    if (lower == 'midle pagi2') {
      return 5.0;
    }
    if (lower == 'midle pagi5') {
      return 12.0;
    }
    if (lower == 'siang' || lower == 'siang9' || lower == 'midle siang1') {
      return 6.0;
    }
    if (lower.contains('malam')) {
      return 10.0;
    }
    if (lower.contains('pagi') || lower.contains('siang') || lower.contains('midle')) {
      return 7.0;
    }
    return 7.0;
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
        pagi++; totalHours += _getShiftDuration(shift); totalShift++;
      } else if (lower.contains('siang')) {
        siang++; totalHours += _getShiftDuration(shift); totalShift++;
      } else if (lower.contains('malam')) {
        malam++; totalHours += _getShiftDuration(shift); totalShift++;
      } else if (lower.contains('cuti')) {
        cuti++;
      } else if (lower.contains('libur')) {
        libur++;
      } else {
        totalShift++; totalHours += _getShiftDuration(shift);
      }
    }

    double wajib = 173.0 - (cuti * 7.0);

    return {
      "P": pagi,
      "S": siang,
      "M": malam,
      "T": totalShift,
      "L": libur,
      "C": cuti,
      "H": totalHours,
      "WJ": wajib,
      "O": totalHours - wajib
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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
                          _buildSectionHeader("Pengajuan Jadwal Tambahan"),
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
                Text("Jadwal Tambahan",
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
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showPatternModal(),
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text(
                    "Isi Pola",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    elevation: 0,
                    side: BorderSide(color: primaryColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixView() {
    int days = DateTime(selectedYear, selectedMonth + 1, 0).day;
    double bodyHeight = (filteredEmployees.length * cellHeight).clamp(100.0, 450.0);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameCell("Nama Pegawai / Departemen", isHeader: true),
            Expanded(
              child: SingleChildScrollView(
                controller: _hMatrixHeaderScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (cellWidth * days) + (statsColumnWidth * 9),
                  child: Row(
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
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: bodyHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: nameColumnWidth,
                child: SingleChildScrollView(
                  controller: _vNameScrollController,
                  child: Column(
                    children: filteredEmployees.map((emp) =>
                        _buildNameCell(emp['nama'], subtitle: emp['departemen'])).toList(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _vGridScrollController,
                  child: SingleChildScrollView(
                    controller: _hGridScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: (cellWidth * days) + (statsColumnWidth * 9),
                      child: Column(
                        children: filteredEmployees.map((emp) {
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
                              _buildStatsCell("${stats['WJ'].toInt()} Jam", isBold: true),
                              _buildStatsCell("${stats['O'].toInt()} Jam",
                                  color: stats['O'] >= 0
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  isBold: true),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                  Row(
                    children:
                        List.generate(days, (i) => _buildDateHeader(i + 1)),
                  ),
                  ...types.map((type) => Row(
                        children: [
                          ...List.generate(days, (dIndex) {
                            int day = dIndex + 1;
                            int count = _getDailyShiftCount(day, type);
                            DateTime date =
                                DateTime(selectedYear, selectedMonth, day);
                            bool isSunday = date.weekday == DateTime.sunday;
                            String dateStr = DateFormat('yyyy-MM-dd').format(date);
                            bool isHoliday = holidays.containsKey(dateStr);

                            return Container(
                              width: cellWidth,
                              height: cellHeight * 0.8,
                              decoration: BoxDecoration(
                                color: _getSummaryRowColor(
                                    type, count, isSunday, isHoliday),
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
                                  color: (isSunday || isHoliday)
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }),
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

  Color _getSummaryRowColor(String type, int count, bool isSunday, bool isHoliday) {
    if (isSunday || isHoliday) return Colors.red[50]!;
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
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    bool isHoliday = holidays.containsKey(dateStr);
    String? holidayName = holidays[dateStr];

    return GestureDetector(
      onTap: () {
        if (isHoliday) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Hari Libur: $holidayName"),
              backgroundColor: const Color(0xFFE11D48),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Tooltip(
        message: holidayName ?? (isSunday ? 'Minggu' : ''),
        child: Container(
          width: cellWidth,
          height: cellHeight,
          decoration: BoxDecoration(
            color: (isSunday || isHoliday)
                ? const Color(0xFFFFF1F2)
                : const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 0.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isHoliday)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('dd').format(date),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: (isSunday || isHoliday)
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF334155))),
                  Text(DateFormat('E').format(date).toUpperCase(),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: (isSunday || isHoliday)
                              ? const Color(0xFFE11D48).withOpacity(0.7)
                              : Colors.grey[500])),
                ],
              ),
            ],
          ),
        ),
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
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    bool isHoliday = holidays.containsKey(dateStr);

    return InkWell(
      onTap: () => _showShiftPicker(emp, day),
      child: Container(
        width: cellWidth,
        height: cellHeight,
        decoration: BoxDecoration(
          color: isChanged
              ? primaryColor.withOpacity(0.08)
              : ((isSunday || isHoliday)
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
            color: (isSunday || isHoliday)
                ? const Color(0xFFE11D48)
                : _getShiftColor(currentShift ?? '-'),
          ),
        ),
      ),
    );
  }

  void _showShiftPicker(Map emp, int day) {
    String dateStr = DateFormat('yyyy-MM-dd')
        .format(DateTime(selectedYear, selectedMonth, day));
    bool isHoliday = holidays.containsKey(dateStr);

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
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(
                      "Tanggal $day ${DateFormat('MMMM yyyy').format(DateTime(selectedYear, selectedMonth))}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (isHoliday)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_available,
                                color: Colors.red[700], size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "Libur: ${holidays[dateStr]}",
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: allShifts.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildShiftButton(null, emp, day);
                    if (index == 1) {
                      return _buildShiftButton({'shift': 'Cuti'}, emp, day);
                    }
                    return _buildShiftButton(allShifts[index - 2], emp, day);
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

    String shiftName = (shift?['shift'] ?? 'libur').toString().toLowerCase();
    Color cardColor;
    IconData shiftIcon;
    List<Color> gradient;

    if (shiftName.contains('pagi')) {
      cardColor = Colors.orange;
      shiftIcon = Icons.wb_sunny_rounded;
      gradient = [
        Colors.orange[400]!.withOpacity(0.12),
        Colors.orange[600]!.withOpacity(0.12)
      ];
    } else if (shiftName.contains('siang') ||
        shiftName.contains('sore') ||
        shiftName.contains('siang')) {
      cardColor = Colors.blue;
      shiftIcon = Icons.wb_cloudy_rounded;
      gradient = [
        Colors.blue[400]!.withOpacity(0.12),
        Colors.blue[600]!.withOpacity(0.12)
      ];
    } else if (shiftName.contains('malam')) {
      cardColor = Colors.indigo;
      shiftIcon = Icons.nightlight_round;
      gradient = [
        Colors.indigo[400]!.withOpacity(0.12),
        Colors.indigo[800]!.withOpacity(0.12)
      ];
    } else if (shiftName.contains('cuti')) {
      cardColor = Colors.teal;
      shiftIcon = Icons.beach_access_rounded;
      gradient = [
        Colors.teal[400]!.withOpacity(0.12),
        Colors.teal[600]!.withOpacity(0.12)
      ];
    } else {
      cardColor = Colors.grey;
      shiftIcon = Icons.event_busy_rounded;
      gradient = [
        Colors.grey[300]!.withOpacity(0.12),
        Colors.grey[400]!.withOpacity(0.12)
      ];
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (!pendingChanges.containsKey(empId)) pendingChanges[empId] = {};
          pendingChanges[empId]![day] = shift?['shift'] ?? '';
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(
            color: isSelected ? cardColor : cardColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: cardColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(
                  shiftIcon,
                  size: 45,
                  color: cardColor.withOpacity(0.06),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 8),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(shiftIcon, color: cardColor, size: 14),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift?['shift'] ?? "Libur / Kosong",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isSelected ? cardColor : Colors.black87,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (shift != null && shift['jam_masuk'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_filled_rounded,
                                    size: 12, color: cardColor.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  "${shift['jam_masuk']?.toString().substring(0, 5) ?? '00:00'} - ${shift['jam_pulang']?.toString().substring(0, 5) ?? '00:00'}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blueGrey[800],
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (shift == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              "Tidak ada jadwal",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
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
                              childCount: 5,
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
                    bool yearChanged = selectedYear != tempYear;
                    selectedMonth = tempMonth;
                    selectedYear = tempYear;
                    if (yearChanged) {
                      _fetchHolidays();
                    }
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

  void _showPatternModal() {
    List<String?> patternRules = List.filled(7, null);
    final List<String> dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
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
                      const Text("Isi Pola Otomatis",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        "Atur pola shift berdasarkan hari. Pola ini akan diterapkan ke ${filteredEmployees.length} pegawai yang sedang tampil.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 7,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dayNames[index],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Container(
                              width: 220,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: patternRules[index],
                                  hint: const Text("- Tidak Diubah -",
                                      style: TextStyle(fontSize: 13)),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem(
                                        value: null,
                                        child: Text("- Tidak Diubah -",
                                            style: TextStyle(fontSize: 13))),
                                    const DropdownMenuItem(
                                        value: 'EMPTY',
                                        child: Text("❌ Libur / Kosong",
                                            style: TextStyle(fontSize: 13))),
                                    const DropdownMenuItem(
                                        value: 'Cuti',
                                        child: Text("🏖️ Cuti",
                                            style: TextStyle(fontSize: 13))),
                                    ...allShifts.map(
                                      (shift) => DropdownMenuItem(
                                        value: shift['shift'],
                                        child: Text(
                                            "${shift['shift']} (${shift['jam_masuk']}-${shift['jam_pulang']})",
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ),
                                    )
                                  ],
                                  onChanged: (val) {
                                    setModalState(() {
                                      patternRules[index] = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ]),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyPattern(patternRules);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Terapkan Pola",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _applyPattern(List<String?> patternRules) {
    int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    setState(() {
      for (var emp in filteredEmployees) {
        String empId = emp['id'].toString();
        if (!pendingChanges.containsKey(empId)) {
          pendingChanges[empId] = {};
        }

        for (int d = 1; d <= daysInMonth; d++) {
          DateTime date = DateTime(selectedYear, selectedMonth, d);
          int weekdayIndex = date.weekday - 1;

          String? rule = patternRules[weekdayIndex];
          if (rule != null) {
            pendingChanges[empId]![d] = rule == 'EMPTY' ? '' : rule;
          }
        }
      }
    });

    Msg.success(context, "Pola berhasil diterapkan! Klik Simpan di bawah.");
  }
}
