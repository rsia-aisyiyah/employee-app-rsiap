import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/lapor_ikp_form.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class LaporIkpHistoryScreen extends StatefulWidget {
  const LaporIkpHistoryScreen({super.key});

  @override
  State<LaporIkpHistoryScreen> createState() => _LaporIkpHistoryScreenState();
}

class _LaporIkpHistoryScreenState extends State<LaporIkpHistoryScreen> {
  List _history = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  int? _selectedUnitId;
  List _units = [];
  bool _isMutuOrAdmin = false;
  bool _showFilterPanel = false;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchHistory();
    _fetchMasterData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (_hasMore && !_isLoading) {
          _fetchHistory(page: _currentPage + 1);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _checkPermissions() {
    final box = GetStorage();
    final String dep = (box.read('dep') ?? "").toString().trim().toUpperCase();
    final String role = (box.read('role') ?? "").toString().trim().toUpperCase();
    final String jbtn = (box.read('jbtn') ?? "").toString().trim().toUpperCase();

    if (dep == 'IT' ||
        dep == 'SIT' ||
        dep.contains('MUTU') ||
        role == 'IT' ||
        role.contains('ADMIN') ||
        role.contains('MUTU') ||
        jbtn.contains('MUTU')) {
      setState(() => _isMutuOrAdmin = true);
    }
  }

  Future<void> _fetchMasterData() async {
    try {
      final res = await Api().getData('/sdi/ikp/master-data');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true) {
          setState(() {
            _units = body['data']['units'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching master data for filters: $e");
    }
  }

  Future<void> _fetchHistory({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      String queryParams = "?page=$page";
      if (_searchController.text.isNotEmpty) {
        queryParams += "&keyword=${Uri.encodeComponent(_searchController.text)}";
      }
      if (_selectedDateRange != null) {
        final start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        final end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
        queryParams += "&start_date=$start&end_date=$end";
      }
      if (_selectedUnitId != null) {
        queryParams += "&unit_id=$_selectedUnitId";
      }

      final response = await Api().getData('/sdi/ikp/history$queryParams');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List newItems = body['data']['data'] ?? [];

        setState(() {
          if (page == 1) {
            _history = newItems;
          } else {
            _history.addAll(newItems);
          }
          _currentPage = page;
          _hasMore = body['data']['next_page_url'] != null;
        });
      } else {
        final body = jsonDecode(response.body);
        Msg.error(context, body['message'] ?? "Gagal memuat riwayat");
      }
    } catch (e) {
      debugPrint("Error fetching IKP history: $e");
      Msg.error(context, "Terjadi kesalahan: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _fetchHistory(page: 1);
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedUnitId = null;
      _searchController.clear();
      _showFilterPanel = false;
    });
    _fetchHistory(page: 1);
  }

  Future<void> _downloadAndPrintPDF(int id) async {
    setState(() => _isDownloadingPdf = true);
    Msg.info(context, "Menyiapkan file PDF...");

    try {
      final baseWebUrl = AppConfig.baseUrl.replaceAll('/rsiapi-v2', '');
      final downloadUrl = "$baseWebUrl/app/insiden/$id/print";

      final dir = Platform.isAndroid
          ? (await getExternalStorageDirectory())?.path
          : (await getApplicationDocumentsDirectory()).path;
      final filePath = "$dir/IKP_Report_$id.pdf";

      Dio dio = Dio();
      await dio.download(downloadUrl, filePath);

      Msg.success(context, "Unduh selesai");
      await OpenFilex.open(filePath);
    } catch (e) {
      debugPrint("Error downloading/printing IKP PDF: $e");
      Msg.error(context, "Gagal mengunduh atau membuka PDF: $e");
    } finally {
      setState(() => _isDownloadingPdf = false);
    }
  }

  Color _getGradingColor(String? grading) {
    if (grading == null) return Colors.grey;
    switch (grading.toUpperCase()) {
      case 'BIRU':
        return Colors.blue;
      case 'HIJAU':
        return Colors.green;
      case 'KUNING':
        return Colors.amber[700]!;
      case 'MERAH':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  void _showDetailBottomSheet(Map item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final grading = item['grading_risiko']?.toString();
        final gradingColor = _getGradingColor(grading);
        final formattingDateMasuk = item['tgl_pasien_masuk'] != null ? _formatDate(item['tgl_pasien_masuk']) : '-';
        final formattingDateInsiden = item['tanggal_insiden'] != null ? _formatDate(item['tanggal_insiden']) : '-';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Indicator Drag Bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Detail Laporan IKP",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 18, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Patient Section
                        _buildSectionHeader("INFORMASI KORBAN / PASIEN", Icons.person_outline),
                        _buildDetailRow("No. Rekam Medis (RM)", item['pasien_id'] == '000000' ? 'Bukan Pasien (000000)' : (item['pasien_id'] ?? '-')),
                        _buildDetailRow("Nama Korban/Pasien", item['nm_pasien'] ?? '-'),
                        _buildDetailRow("Tanggal Lahir", item['tgl_lahir'] != null ? _formatDate(item['tgl_lahir']) : '-'),
                        _buildDetailRow("Jenis Kelamin", item['jk'] == 'L' ? 'Laki-laki' : 'Perempuan'),
                        _buildDetailRow("Tanggal Masuk RS", formattingDateMasuk),
                        
                        const SizedBox(height: 20),

                        // Incident Section
                        _buildSectionHeader("DETAIL INSIDEN", Icons.warning_amber_rounded),
                        _buildDetailRow("Waktu Kejadian", "$formattingDateInsiden - ${item['waktu_insiden'] ?? '-'}"),
                        _buildDetailRow("Insiden yang Terjadi", item['insiden'] ?? '-'),
                        _buildDetailRow("Kronologi Kejadian", _stripHtml(item['kronologi'])),
                        _buildDetailRow("Tempat Kejadian", item['tempat_kejadian'] ?? '-'),
                        _buildDetailRow("Unit Terkait", item['nama_unit'] ?? '-'),

                        const SizedBox(height: 20),

                        // Classifications Section
                        _buildSectionHeader("KLASIFIKASI & PELAPORAN", Icons.category_outlined),
                        _buildDetailRow("Jenis Pelapor", _capitalize(item['jenis_pelapor'] ?? '')),
                        if (item['jenis_pelapor_lainnya'] != null)
                          _buildDetailRow("Jenis Pelapor (Lainnya)", item['jenis_pelapor_lainnya']),
                        _buildDetailRow("Korban Insiden", _capitalize(item['korban_insiden'] ?? '')),
                        if (item['korban_insiden_lainnya'] != null)
                          _buildDetailRow("Korban Insiden (Lainnya)", item['korban_insiden_lainnya']),
                        _buildDetailRow("Layanan Terkait", item['layanan_insiden']?.toString().toUpperCase() ?? '-'),
                        if (item['layanan_insiden_lainnya'] != null)
                          _buildDetailRow("Layanan Terkait (Lainnya)", item['layanan_insiden_lainnya']),
                        _buildDetailRow("Kasus Terkait", _formatKasusTerkait(item['kasus_insiden']?.toString())),
                        if (item['kasus_insiden_lainnya'] != null)
                          _buildDetailRow("Kasus Terkait (Lainnya)", item['kasus_insiden_lainnya']),

                        const SizedBox(height: 20),

                        // Actions & Severity Section
                        _buildSectionHeader("DAMPAK & TINDAKAN", Icons.healing_outlined),
                        _buildDetailRow("Dampak Cedera", _capitalize(item['dampak_insiden'] ?? '')),
                        _buildDetailRow("Tindakan Awal", _stripHtml(item['tindakan_insiden'])),
                        _buildDetailRow("Tindakan Oleh", _capitalize(item['tindakan_oleh'] ?? '')),
                        if (item['tindakan_detail'] != null)
                          _buildDetailRow("Detail Pelaksana", item['tindakan_detail']),
                        
                        const SizedBox(height: 20),

                        // Grading Section
                        _buildSectionHeader("GRADING RISIKO", Icons.shield_outlined),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: gradingColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: gradingColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: gradingColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Grading Akhir: ${item['grading_risiko'] ?? 'Belum Ditentukan'}",
                                style: TextStyle(color: gradingColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 15, 20, MediaQuery.of(context).padding.bottom + 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        // Print Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isDownloadingPdf
                                ? null
                                : () async {
                                    setModalState(() => _isDownloadingPdf = true);
                                    await _downloadAndPrintPDF(item['id']);
                                    setModalState(() => _isDownloadingPdf = false);
                                  },
                            icon: _isDownloadingPdf
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.print_outlined, size: 18),
                            label: const Text("Cetak PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Edit Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context); // Close preview
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LaporIkpFormScreen(existingData: item),
                                ),
                              );
                              if (result == true) {
                                _fetchHistory(page: 1);
                              }
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text("Ubah / Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _stripHtml(String? text) {
    if (text == null) return '-';
    final regExp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    String cleanText = text.replaceAll(regExp, '');
    
    cleanText = cleanText
        .replaceAll('&body;', ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');
        
    return cleanText.trim();
  }

  String _formatKasusTerkait(String? value) {
    if (value == null || value == '-' || value.isEmpty) return '-';
    
    try {
      if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded
              .map((item) => item.toString().replaceAll('-', ' '))
              .join(', ');
        }
      }
    } catch (e) {
      debugPrint("Error parsing kasus_insiden JSON: $e");
    }

    return value
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('-', ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Riwayat IKP Unit",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchHistory(page: 1),
              color: primaryColor,
              child: _history.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length + (_hasMore ? 1 : 0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (index == _history.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          );
                        }

                        final item = _history[index];
                        final grading = item['grading_risiko']?.toString();
                        final gradingColor = _getGradingColor(grading);

                        return GestureDetector(
                          onTap: () => _showDetailBottomSheet(item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item['jenis_alias'] ?? 'IKP',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      if (grading != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: gradingColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: gradingColor.withOpacity(0.3), width: 1),
                                          ),
                                          child: Text(
                                            "Grading: $grading",
                                            style: TextStyle(
                                              color: gradingColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    item['insiden'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[400]),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDate(item['tanggal_insiden'] ?? ''),
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                      const SizedBox(width: 15),
                                      Icon(Icons.meeting_room_outlined, size: 13, color: Colors.grey[400]),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item['nama_unit'] ?? '-',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, thickness: 0.5),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 13, color: Colors.grey[400]),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Korban: ${item['nm_pasien'] ?? '-'}",
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LaporIkpFormScreen()),
          );
          if (result == true || result == null) {
            _fetchHistory(page: 1);
          }
        },
        label: const Text(
          "Lapor IKP",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        icon: const Icon(Icons.add_alert_outlined),
        backgroundColor: primaryColor,
        elevation: 4,
      ),
    );
  }

  Widget _buildFilterHeader() {
    int activeFiltersCount = 0;
    if (_selectedDateRange != null) activeFiltersCount++;
    if (_selectedUnitId != null) activeFiltersCount++;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[500], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (val) => _fetchHistory(page: 1),
                          decoration: const InputDecoration(
                            hintText: "Cari data...",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _fetchHistory(page: 1);
                          },
                          child: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() => _showFilterPanel = !_showFilterPanel);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _showFilterPanel ? primaryColor.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showFilterPanel ? primaryColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: _showFilterPanel ? primaryColor : Colors.grey[600],
                        size: 20,
                      ),
                      if (activeFiltersCount > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              activeFiltersCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showFilterPanel) ...[
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 15),
            _buildFilterOptions(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    String dateRangeLabel = "Pilih Range Tanggal";
    if (_selectedDateRange != null) {
      final startStr = DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start);
      final endStr = DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end);
      dateRangeLabel = "$startStr - $endStr";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Filter Range Tanggal",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range_outlined, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      dateRangeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedDateRange != null ? Colors.black87 : Colors.grey[600],
                        fontWeight: _selectedDateRange != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (_selectedDateRange != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDateRange = null);
                      _fetchHistory(page: 1);
                    },
                    child: Icon(Icons.cancel, color: Colors.grey[400], size: 18),
                  )
                else
                  Icon(Icons.keyboard_arrow_right, color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
        if (_isMutuOrAdmin) ...[
          const SizedBox(height: 15),
          const Text(
            "Filter Unit",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedUnitId,
                isExpanded: true,
                hint: Text(
                  "Pilih Unit Kerja",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text("Semua Unit"),
                  ),
                  ..._units.map((unit) {
                    return DropdownMenuItem<int>(
                      value: unit['id'],
                      child: Text(unit['nama_unit'] ?? '-'),
                    );
                  }).toList(),
                ],
                onChanged: (val) {
                  setState(() => _selectedUnitId = val);
                  _fetchHistory(page: 1);
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text("Reset Filter", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _showFilterPanel = false);
                  _fetchHistory(page: 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text("Terapkan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 150),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                  )
                ],
              ),
              child: Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[300]),
            ),
            const SizedBox(height: 25),
            const Text(
              "Belum Ada Laporan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Tidak ada laporan insiden yang cocok dengan filter pencarian Anda saat ini.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
