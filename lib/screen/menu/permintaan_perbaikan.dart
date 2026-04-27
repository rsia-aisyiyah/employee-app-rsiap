import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class PermintaanPerbaikan extends StatefulWidget {
  final String? initialNoInventaris;
  const PermintaanPerbaikan({super.key, this.initialNoInventaris});

  @override
  State<PermintaanPerbaikan> createState() => _PermintaanPerbaikanState();
}

class _PermintaanPerbaikanState extends State<PermintaanPerbaikan>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();

  // Scanner state
  bool _scanning = false;
  bool _scannedOnce = false;
  String? _noInventaris;
  Map<String, dynamic>? _inventarisInfo;
  bool _loadingInfo = false;

  // Form
  final _deskripsiController = TextEditingController();
  bool _submitting = false;

  // History
  List _history = [];
  bool _loadingHistory = false;
  DateTime _filterStart =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _filterEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _history.isEmpty) {
        _loadHistory();
      }
    });

    // Pre-fill jika datang dari Emergency Maintenance
    if (widget.initialNoInventaris != null) {
      _noInventaris = widget.initialNoInventaris;
      _loadInventarisInfo(widget.initialNoInventaris!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  // ─── Load Inventaris Info ──────────────────────────────────────
  Future<void> _loadInventarisInfo(String noInventaris) async {
    setState(() => _loadingInfo = true);
    try {
      final res = await Api().getData('/aset/inventaris/$noInventaris');
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['data'] != null) {
        setState(() => _inventarisInfo = body['data']);
      } else {
        if (mounted) Msg.error(context, 'Inventaris tidak ditemukan');
      }
    } catch (e) {
      if (mounted) Msg.error(context, 'Gagal koneksi ke server');
    } finally {
      setState(() => _loadingInfo = false);
    }
  }

  // ─── Search Manual ────────────────────────────────────────────
  void _showSearchDialog() {
    final searchCtrl = TextEditingController();
    List searchResults = [];
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> doSearch() async {
            final q = searchCtrl.text.trim();
            if (q.isEmpty) return;
            setModalState(() => searching = true);
            try {
              final res =
                  await Api().getData('/aset/inventaris?search=$q&limit=20');
              final body = json.decode(res.body);
              if (res.statusCode == 200) {
                final data = body['data'] is List
                    ? body['data']
                    : (body['data']['data'] ?? []);
                setModalState(() => searchResults = data);
              }
            } catch (_) {}
            setModalState(() => searching = false);
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Cari nama barang / no inventaris...',
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: Colors.grey[400]),
                          ),
                          onSubmitted: (_) => doSearch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: doSearch,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.search_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: searching
                      ? Center(
                          child: CircularProgressIndicator(color: primaryColor))
                      : searchResults.isEmpty
                          ? Center(
                              child: Text(
                                searchCtrl.text.isEmpty
                                    ? 'Ketik untuk mencari inventaris'
                                    : 'Tidak ditemukan',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: searchResults.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: Colors.grey[100]),
                              itemBuilder: (_, i) {
                                final inv = searchResults[i];
                                final nama =
                                    inv['barang']?['nama_barang'] ?? '-';
                                final noInv = inv['no_inventaris'] ?? '-';
                                final ruang =
                                    inv['ruang']?['nama_ruang'] ?? '-';
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.inventory_2_rounded,
                                        color: primaryColor, size: 20),
                                  ),
                                  title: Text(nama,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  subtitle: Text('$noInv  •  $ruang',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500])),
                                  trailing: Icon(Icons.chevron_right_rounded,
                                      color: Colors.grey[300]),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _noInventaris = noInv;
                                    });
                                    _loadInventarisInfo(noInv);
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Submit ────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_noInventaris == null) {
      Msg.warning(context, 'Scan barcode terlebih dahulu');
      return;
    }

    final nik = box.read('sub')?.toString() ?? '';
    final now = DateTime.now();
    final noPermintaan = 'PP-${DateFormat('yyMMddHHmmss').format(now)}';

    setState(() => _submitting = true);
    try {
      final data = {
        'no_permintaan': noPermintaan,
        'no_inventaris': _noInventaris,
        'nik': nik,
        'tanggal': DateFormat('yyyy-MM-dd').format(now),
        'deskripsi_kerusakan': _deskripsiController.text.trim(),
      };

      final res = await Api().postData(data, '/aset/permintaan-perbaikan');
      final body = json.decode(res.body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (mounted) {
          Msg.success(context, body['message'] ?? 'Berhasil disimpan');
          _resetForm();
        }
      } else {
        if (mounted) {
          Msg.error(context, body['message'] ?? 'Gagal menyimpan');
        }
      }
    } catch (e) {
      if (mounted) Msg.error(context, 'Gagal koneksi ke server');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _noInventaris = null;
      _inventarisInfo = null;
      _deskripsiController.clear();
    });
  }

  // ─── Load History ──────────────────────────────────────────────
  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_filterStart);
      final endStr = DateFormat('yyyy-MM-dd').format(_filterEnd);
      final res = await Api().getData(
          '/aset/permintaan-perbaikan?limit=50&sort_by=tanggal&order=desc&tgl_awal=$startStr&tgl_akhir=$endStr');
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _history = body['data'] is List
              ? body['data']
              : (body['data']['data'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) Msg.error(context, 'Gagal memuat riwayat');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _filterStart, end: _filterEnd),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _filterStart = picked.start;
        _filterEnd = picked.end;
      });
      _loadHistory();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Permintaan Perbaikan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(
                icon: Icon(Icons.add_circle_outline_rounded, size: 20),
                text: 'Input'),
            Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInputTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 1: INPUT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildInputTab() {
    if (_noInventaris == null && !_scanning) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              _buildScanCard(),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text('Cara Penggunaan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[700])),
                    const SizedBox(height: 16),
                    _stepRow(1, 'Scan barcode inventaris yang rusak'),
                    _stepRow(2, 'Periksa informasi barang'),
                    _stepRow(3, 'Deskripsikan kerusakan & kirim permintaan'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scanning ? _buildScannerView() : _buildScanCard(),
          const SizedBox(height: 16),
          if (_loadingInfo) _buildLoadingCard(),
          if (_inventarisInfo != null) ...[
            _buildInventarisCard(),
            const SizedBox(height: 16),
            _buildFormCard(),
          ],
        ],
      ),
    );
  }

  Widget _stepRow(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$step',
                  style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    final hasScan = _noInventaris != null;

    if (hasScan) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Berhasil Discan',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF10B981))),
                  Text(_noInventaris!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontFamily: 'monospace')),
                ],
              ),
            ),
            Material(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _showSearchDialog,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.search_rounded,
                      color: Colors.grey[600], size: 18),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() {
                  _scanning = true;
                  _scannedOnce = false;
                }),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.qr_code_scanner_rounded,
                      color: Colors.grey[600], size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final scanCard = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() {
            _scanning = true;
            _scannedOnce = false;
          }),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan Barang Rusak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap untuk membuka scanner',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        scanCard,
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _showSearchDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Cari Inventaris Manual',
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerView() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            QRView(
              key: GlobalKey(debugLabel: 'QR_permintaan'),
              onQRViewCreated: (controller) {
                controller.scannedDataStream.listen((scanData) {
                  if (!_scannedOnce && scanData.code != null) {
                    _scannedOnce = true;
                    controller.dispose();
                    setState(() {
                      _noInventaris = scanData.code;
                      _scanning = false;
                    });
                    _loadInventarisInfo(scanData.code!);
                  }
                });
              },
              overlay: QrScannerOverlayShape(
                borderColor: primaryColor,
                borderRadius: 12,
                borderLength: 30,
                borderWidth: 8,
                cutOutSize: 220,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _scanning = false),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: CircularProgressIndicator(color: primaryColor)),
    );
  }

  Widget _buildInventarisCard() {
    final barang = _inventarisInfo?['barang'];
    final namaBarang = barang?['nama_barang'] ?? '-';
    final merk =
        _inventarisInfo?['merk']?['nama'] ?? _inventarisInfo?['merk_id'] ?? '-';
    final ruang = _inventarisInfo?['ruang']?['nama_ruang'] ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_rounded,
                      color: primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Informasi Inventaris',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      const Text('Valid',
                          style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow(Icons.label_rounded, 'No. Inventaris',
                    _noInventaris ?? '-'),
                _infoRow(Icons.devices_rounded, 'Nama Barang', namaBarang),
                _infoRow(Icons.branding_watermark_rounded, 'Merk', merk),
                _infoRow(Icons.location_on_rounded, 'Ruangan', ruang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.report_problem_rounded,
                      color: Color(0xFFEF4444), size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Laporan Kerusakan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Deskripsikan kerusakan yang ditemukan',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Deskripsi Kerusakan',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _deskripsiController,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Jelaskan kerusakan barang...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Deskripsi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                          _submitting
                              ? 'Mengirim...'
                              : 'Kirim Permintaan Perbaikan',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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

  // ═══════════════════════════════════════════════════════════════
  // TAB 2: HISTORY
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range_rounded,
                              color: primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${DateFormat('dd MMM yyyy').format(_filterStart)}  —  ${DateFormat('dd MMM yyyy').format(_filterEnd)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _loadHistory,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.search_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingHistory
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Belum ada permintaan',
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _history.length,
                        itemBuilder: (ctx, i) => _buildHistoryCard(_history[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final namaBarang = item['inventaris']?['barang']?['nama_barang'] ??
        item['no_inventaris'] ??
        '-';
    final tanggalRaw = item['tanggal'] ?? '-';
    String tanggal;
    try {
      tanggal = DateFormat('dd MMM yyyy').format(DateTime.parse(tanggalRaw));
    } catch (_) {
      tanggal = tanggalRaw.toString();
    }
    final deskripsi = item['deskripsi_kerusakan'] ?? '-';
    final sudahDiperbaiki = item['perbaikan_inventaris'] != null;

    final statusColor =
        sudahDiperbaiki ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusText = sudahDiperbaiki ? 'Diperbaiki' : 'Menunggu';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                      sudahDiperbaiki
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      color: statusColor,
                      size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(namaBarang,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deskripsi,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey[100]),
                const SizedBox(height: 10),
                _detailRow(Icons.calendar_today_rounded, 'Tanggal', tanggal),
                const SizedBox(height: 6),
                _detailRow(Icons.tag_rounded, 'No. Permintaan',
                    item['no_permintaan'] ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
