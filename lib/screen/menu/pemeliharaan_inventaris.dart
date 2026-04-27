import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/screen/menu/permintaan_perbaikan.dart';

class PemeliharaanInventaris extends StatefulWidget {
  const PemeliharaanInventaris({super.key});

  @override
  State<PemeliharaanInventaris> createState() => _PemeliharaanInventarisState();
}

class _PemeliharaanInventarisState extends State<PemeliharaanInventaris>
    with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;

  // Scanner
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR_MAINTENANCE');
  QRViewController? _qrController;
  bool _scanning = false;
  bool _scannedOnce = false;

  // Form
  final _formKey = GlobalKey<FormState>();
  String? _noInventaris;
  Map<String, dynamic>? _inventarisInfo;
  bool _loadingInfo = false;
  bool _submitting = false;
  final _uraianController = TextEditingController();
  String _jenisPemeliharaan = 'Running Maintenance';
  String _pelaksana = 'Teknisi Rumah Sakit';
  final _biayaController = TextEditingController(text: '0');

  // History
  List _history = [];
  bool _loadingHistory = false;
  late DateTime _filterStart;
  late DateTime _filterEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterStart = DateTime(now.year, now.month, 1);
    _filterEnd = now;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _history.isEmpty) {
        _loadHistory();
      }
    });
    _requestPermission();
  }

  @override
  void dispose() {
    _qrController?.dispose();
    _tabController.dispose();
    _uraianController.dispose();
    _biayaController.dispose();
    super.dispose();
  }

  void _requestPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return;
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }
    await [Permission.camera].request();
  }

  // ─── Scanner ──────────────────────────────────────────────────
  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_scannedOnce || scanData.code == null) return;
      _scannedOnce = true;
      _qrController?.pauseCamera();
      _onBarcodeScan(scanData.code!);
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _qrController?.pauseCamera();
    } else if (Platform.isIOS) {
      _qrController?.resumeCamera();
    }
  }

  Future<void> _onBarcodeScan(String code) async {
    setState(() {
      _noInventaris = code;
      _loadingInfo = true;
      _scanning = false;
    });

    try {
      final res = await Api().getData('/aset/inventaris/$code');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _inventarisInfo = body['data'];
          _loadingInfo = false;
        });
      } else {
        setState(() {
          _inventarisInfo = null;
          _loadingInfo = false;
        });
        if (mounted) Msg.error(context, 'Inventaris "$code" tidak ditemukan');
      }
    } catch (e) {
      setState(() {
        _loadingInfo = false;
        _inventarisInfo = null;
      });
      if (mounted) Msg.error(context, 'Gagal koneksi ke server');
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
                                    _onBarcodeScan(noInv);
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

  // ─── Submit ───────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_noInventaris == null) {
      Msg.warning(context, 'Scan barcode terlebih dahulu');
      return;
    }

    final box = GetStorage();
    final nip = box.read('sub')?.toString() ?? '';

    setState(() => _submitting = true);
    try {
      final data = {
        'no_inventaris': _noInventaris,
        'tanggal': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'uraian_kegiatan': _uraianController.text.trim(),
        'nip': nip,
        'pelaksana': _pelaksana,
        'biaya': double.tryParse(_biayaController.text) ?? 0,
        'jenis_pemeliharaan': _jenisPemeliharaan,
      };

      final res = await Api().postData(data, '/aset/pemeliharaan-inventaris');
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
      setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _noInventaris = null;
      _inventarisInfo = null;
      _scannedOnce = false;
      _uraianController.clear();
      _biayaController.text = '0';
      _jenisPemeliharaan = 'Running Maintenance';
      _pelaksana = 'Teknisi Rumah Sakit';
    });
  }

  // ─── History ──────────────────────────────────────────────────
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _filterStart, end: _filterEnd),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _filterStart = picked.start;
        _filterEnd = picked.end;
      });
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final startStr = DateFormat('yyyy-MM-dd').format(_filterStart);
    final endStr = DateFormat('yyyy-MM-dd').format(_filterEnd);
    try {
      final res = await Api().getData(
          '/aset/pemeliharaan-inventaris?limit=50&sort_by=tanggal&order=desc&tgl_awal=$startStr&tgl_akhir=$endStr');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _history = body['data']?['data'] ?? [];
          _loadingHistory = false;
        });
      } else {
        setState(() => _loadingHistory = false);
      }
    } catch (e) {
      setState(() => _loadingHistory = false);
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInputTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Pemeliharaan Inventaris',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(
              icon: Icon(Icons.qr_code_scanner_rounded, size: 20),
              text: 'Input'),
          Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'Riwayat'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 1: INPUT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildInputTab() {
    if (_noInventaris == null && !_scanning) {
      // Empty state — show large centered scan prompt
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              _buildScanCard(),
              const SizedBox(height: 24),
              // Instruction steps
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
                    _stepRow(1, 'Scan barcode pada label inventaris'),
                    _stepRow(2, 'Periksa informasi barang yang muncul'),
                    _stepRow(3, 'Isi form dan simpan pemeliharaan'),
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

    // Compact bar after successful scan
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

    // Large card for initial empty state
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
                  'Scan Barcode Inventaris',
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
            color: Colors.black.withOpacity(0.2),
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
              key: _qrKey,
              onQRViewCreated: _onQRViewCreated,
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
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Text(
                'Arahkan kamera ke barcode inventaris',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
                  ],
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
      padding: const EdgeInsets.all(32),
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
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Memuat informasi inventaris...',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventarisCard() {
    final barang = _inventarisInfo?['barang'];
    final namaBarang = barang?['nama_barang'] ?? '-';
    final merk = _inventarisInfo?['merk']?['nama_merk'] ?? '-';
    final ruang = _inventarisInfo?['ruang']?['nama_ruang'] ?? '-';
    final noInventaris = _inventarisInfo?['no_inventaris'] ?? '-';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_rounded,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informasi Inventaris',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87)),
                      Text(noInventaris,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('✓ Valid',
                      style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow(Icons.devices_rounded, 'Nama Barang', namaBarang),
                _infoRow(Icons.branding_watermark_rounded, 'Merk', merk),
                _infoRow(Icons.room_rounded, 'Ruangan', ruang),
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
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // ─── FORM ─────────────────────────────────────────────────────
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.06),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.build_circle_rounded,
                        color: Color(0xFFF59E0B), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Form Pemeliharaan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87)),
                      Text('Isi detail kegiatan maintenance',
                          style:
                              TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jenis Pemeliharaan
                  _buildLabel('Jenis Pemeliharaan'),
                  const SizedBox(height: 6),
                  _buildJenisSelector(),
                  const SizedBox(height: 16),

                  // Uraian Kegiatan
                  _buildLabel('Uraian Kegiatan'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _uraianController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      hintText: 'Jelaskan kegiatan pemeliharaan...',
                      icon: Icons.description_rounded,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Uraian tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Pelaksana
                  _buildLabel('Pelaksana'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _pelaksana,
                    decoration: _inputDecoration(
                      icon: Icons.engineering_rounded,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Teknisi Rumah Sakit',
                          child: Text('Teknisi Rumah Sakit',
                              style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(
                          value: 'Teknisi Rujukan',
                          child: Text('Teknisi Rujukan',
                              style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(
                          value: 'Pihak ke III',
                          child: Text('Pihak ke III',
                              style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _pelaksana = v!),
                  ),
                  const SizedBox(height: 16),

                  // Biaya
                  _buildLabel('Biaya (Rp)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _biayaController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      hintText: '0',
                      icon: Icons.payments_rounded,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Simpan Pemeliharaan',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJenisSelector() {
    final types = [
      {
        'val': 'Running Maintenance',
        'label': 'Running',
        'icon': Icons.directions_run_rounded,
        'color': const Color(0xFF10B981)
      },
      {
        'val': 'Shut Down Maintenance',
        'label': 'Shut Down',
        'icon': Icons.power_settings_new_rounded,
        'color': const Color(0xFFF59E0B)
      },
      {
        'val': 'Emergency Maintenance',
        'label': 'Emergency',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFEF4444)
      },
    ];

    return Row(
      children: types.map((t) {
        final selected = _jenisPemeliharaan == t['val'];
        final color = t['color'] as Color;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: t != types.last ? 8.0 : 0),
            child: Material(
              color: selected ? color.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    setState(() => _jenisPemeliharaan = t['val'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? color : Colors.grey[200]!,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(t['icon'] as IconData,
                          color: selected ? color : Colors.grey[400], size: 22),
                      const SizedBox(height: 4),
                      Text(
                        t['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                          color: selected ? color : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, IconData? icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon:
          icon != null ? Icon(icon, color: Colors.grey[400], size: 20) : null,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 2: HISTORY
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Date Filter Bar
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
                          Text(
                            '${DateFormat('dd MMM yyyy').format(_filterStart)}  —  ${DateFormat('dd MMM yyyy').format(_filterEnd)}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
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

        // Content
        Expanded(
          child: _loadingHistory
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Belum ada riwayat',
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Tidak ada data pada periode ini',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _history.length,
                        itemBuilder: (ctx, i) {
                          final item = _history[i];
                          return _buildHistoryCard(item);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final jenis = item['jenis_pemeliharaan'] ?? '-';
    Color jenisColor;
    IconData jenisIcon;

    switch (jenis) {
      case 'Running Maintenance':
        jenisColor = const Color(0xFF10B981);
        jenisIcon = Icons.directions_run_rounded;
        break;
      case 'Shut Down Maintenance':
        jenisColor = const Color(0xFFF59E0B);
        jenisIcon = Icons.power_settings_new_rounded;
        break;
      case 'Emergency Maintenance':
        jenisColor = const Color(0xFFEF4444);
        jenisIcon = Icons.warning_amber_rounded;
        break;
      default:
        jenisColor = Colors.grey;
        jenisIcon = Icons.build_rounded;
    }

    final namaBarang =
        item['inventaris']?['barang']?['nama_barang'] ?? item['no_inventaris'];
    final tanggalRaw = item['tanggal'] ?? '-';
    String tanggal;
    try {
      tanggal = DateFormat('dd MMM yyyy').format(DateTime.parse(tanggalRaw));
    } catch (_) {
      tanggal = tanggalRaw.toString();
    }
    final uraian = item['uraian_kegiatan'] ?? '-';
    final pelaksana = item['pelaksana'] ?? '-';
    final petugas = item['petugas']?['nama'] ?? '-';
    final biaya = item['biaya'] ?? 0;

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
          // Header — Nama Barang + Badge Jenis
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: jenisColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: jenisColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(jenisIcon, color: jenisColor, size: 16),
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
                    color: jenisColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jenis.toString().replaceAll(' Maintenance', ''),
                    style: TextStyle(
                        color: jenisColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Uraian
                Text(uraian,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey[100]),
                const SizedBox(height: 10),

                // Detail rows
                _detailRow(Icons.calendar_today_rounded, 'Tanggal', tanggal),
                const SizedBox(height: 6),
                _detailRow(Icons.engineering_rounded, 'Pelaksana', pelaksana),
                const SizedBox(height: 6),
                _detailRow(Icons.person_rounded, 'Petugas', petugas),
                if (biaya > 0) ...[
                  const SizedBox(height: 6),
                  _detailRow(
                    Icons.payments_rounded,
                    'Biaya',
                    NumberFormat.currency(
                            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                        .format(biaya),
                    valueColor: primaryColor,
                  ),
                ],
                // Tombol aksi: Emergency → Ajukan Perbaikan
                if (jenis == 'Emergency Maintenance') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final noInv = item['no_inventaris'] ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PermintaanPerbaikan(
                              initialNoInventaris: noInv,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.assignment_late_rounded, size: 15),
                      label: const Text('Ajukan Permintaan Perbaikan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
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
                  color: valueColor ?? Colors.grey[700],
                  fontWeight:
                      valueColor != null ? FontWeight.bold : FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
