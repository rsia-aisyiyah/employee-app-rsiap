import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class PerbaikanService extends StatefulWidget {
  const PerbaikanService({super.key});

  @override
  State<PerbaikanService> createState() => _PerbaikanServiceState();
}

class _PerbaikanServiceState extends State<PerbaikanService>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final box = GetStorage();

  // Permintaan masuk (belum diperbaiki)
  List _permintaanList = [];
  bool _loadingPermintaan = false;

  // Riwayat perbaikan
  List _riwayatList = [];
  bool _loadingRiwayat = false;
  DateTime _filterStart =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _filterEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPermintaan();
    _tabController.addListener(() {
      if (_tabController.index == 1 && _riwayatList.isEmpty) {
        _loadRiwayat();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Load Permintaan ───────────────────────────────────────────
  Future<void> _loadPermintaan() async {
    setState(() => _loadingPermintaan = true);
    try {
      final res = await Api().getData(
          '/aset/permintaan-perbaikan?limit=50&sort_by=tanggal&order=desc');
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        final all =
            body['data'] is List ? body['data'] : (body['data']['data'] ?? []);
        // Filter: hanya yang belum ada perbaikan
        setState(() {
          _permintaanList = (all as List)
              .where((item) => item['perbaikan_inventaris'] == null)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) Msg.error(context, 'Gagal memuat permintaan');
    } finally {
      if (mounted) setState(() => _loadingPermintaan = false);
    }
  }

  // ─── Load Riwayat Perbaikan ────────────────────────────────────
  Future<void> _loadRiwayat() async {
    setState(() => _loadingRiwayat = true);
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_filterStart);
      final endStr = DateFormat('yyyy-MM-dd').format(_filterEnd);
      final res = await Api().getData(
          '/aset/perbaikan-inventaris?limit=50&sort_by=tanggal&order=desc&tgl_awal=$startStr&tgl_akhir=$endStr');
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _riwayatList = body['data'] is List
              ? body['data']
              : (body['data']['data'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) Msg.error(context, 'Gagal memuat riwayat');
    } finally {
      if (mounted) setState(() => _loadingRiwayat = false);
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
      _loadRiwayat();
    }
  }

  // ─── Submit Perbaikan ──────────────────────────────────────────
  void _showPerbaikanForm(Map<String, dynamic> permintaan) {
    final formKey = GlobalKey<FormState>();
    final uraianCtrl = TextEditingController();
    final biayaCtrl = TextEditingController(text: '0');
    final keteranganCtrl = TextEditingController();
    String pelaksana = 'Teknisi Rumah Sakit';
    String status = 'Bisa Diperbaiki';
    bool submitting = false;

    final namaBarang = permintaan['inventaris']?['barang']?['nama_barang'] ??
        permintaan['no_inventaris'] ??
        '-';
    final deskripsi = permintaan['deskripsi_kerusakan'] ?? '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.home_repair_service_rounded,
                            color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Form Perbaikan',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info Barang
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(namaBarang,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Kerusakan: $deskripsi',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Uraian Kegiatan
                  const Text('Uraian Kegiatan',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: uraianCtrl,
                    maxLines: 3,
                    decoration: _inputDeco('Jelaskan kegiatan perbaikan...'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Status
                  const Text('Status Perbaikan',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statusChip(
                          'Bisa Diperbaiki', status, const Color(0xFF10B981),
                          (v) {
                        setModalState(() => status = v);
                      }),
                      const SizedBox(width: 8),
                      _statusChip('Tidak Bisa Diperbaiki', status,
                          const Color(0xFFEF4444), (v) {
                        setModalState(() => status = v);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pelaksana
                  const Text('Pelaksana',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: pelaksana,
                    decoration: _inputDeco(null),
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
                    onChanged: (v) {
                      setModalState(() => pelaksana = v!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Biaya
                  const Text('Biaya (Rp)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: biayaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('0'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Keterangan
                  const Text('Keterangan',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: keteranganCtrl,
                    maxLines: 2,
                    decoration: _inputDeco('Keterangan tambahan...'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => submitting = true);

                              final nip = box.read('sub')?.toString() ?? '';
                              final data = {
                                'no_permintaan': permintaan['no_permintaan'],
                                'tanggal': DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                'uraian_kegiatan': uraianCtrl.text.trim(),
                                'nip': nip,
                                'pelaksana': pelaksana,
                                'biaya': double.tryParse(biayaCtrl.text) ?? 0,
                                'keterangan': keteranganCtrl.text.trim(),
                                'status': status,
                              };

                              try {
                                final res = await Api().postData(
                                    data, '/aset/perbaikan-inventaris');
                                final body = json.decode(res.body);
                                if (res.statusCode == 201 ||
                                    res.statusCode == 200) {
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    Msg.success(
                                        context, body['message'] ?? 'Berhasil');
                                    _loadPermintaan();
                                  }
                                } else {
                                  if (mounted) {
                                    Msg.error(context,
                                        body['message'] ?? 'Gagal menyimpan');
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  Msg.error(context, 'Gagal koneksi ke server');
                                }
                              } finally {
                                setModalState(() => submitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                          submitting ? 'Menyimpan...' : 'Simpan Perbaikan',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(
      String label, String current, Color color, Function(String) onTap) {
    final selected = label == current;
    return Expanded(
      child: Material(
        color: selected ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTap(label),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: selected ? color : Colors.grey[200]!, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label.replaceAll('Bisa ', '').replaceAll('Tidak ', '✗ '),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected ? color : Colors.grey[500]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Perbaikan & Service',
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
                icon: Icon(Icons.inbox_rounded, size: 20),
                text: 'Permintaan Masuk'),
            Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPermintaanTab(),
          _buildRiwayatTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 1: PERMINTAAN MASUK
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPermintaanTab() {
    if (_loadingPermintaan) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_permintaanList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Tidak ada permintaan baru',
                style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Semua permintaan sudah ditangani',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPermintaan,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _permintaanList.length,
        itemBuilder: (ctx, i) => _buildPermintaanCard(_permintaanList[i]),
      ),
    );
  }

  Widget _buildPermintaanCard(Map<String, dynamic> item) {
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
    final pegawai = item['pegawai']?['nama'] ?? '-';

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
              color: const Color(0xFFF59E0B).withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B), size: 16),
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
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Menunggu',
                      style: TextStyle(
                          color: Color(0xFFF59E0B),
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
                _detailRow(Icons.person_rounded, 'Pelapor', pegawai),
                const SizedBox(height: 6),
                _detailRow(Icons.tag_rounded, 'No. Permintaan',
                    item['no_permintaan'] ?? '-'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPerbaikanForm(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.build_rounded, size: 16),
                    label: const Text('Tangani Perbaikan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 2: RIWAYAT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRiwayatTab() {
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
                  onTap: _loadRiwayat,
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
          child: _loadingRiwayat
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _riwayatList.isEmpty
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
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRiwayat,
                      color: primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _riwayatList.length,
                        itemBuilder: (ctx, i) =>
                            _buildRiwayatCard(_riwayatList[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> item) {
    final namaBarang = item['permintaan_perbaikan']?['inventaris']?['barang']
            ?['nama_barang'] ??
        item['no_permintaan'] ??
        '-';
    final tanggalRaw = item['tanggal'] ?? '-';
    String tanggal;
    try {
      tanggal = DateFormat('dd MMM yyyy').format(DateTime.parse(tanggalRaw));
    } catch (_) {
      tanggal = tanggalRaw.toString();
    }
    final uraian = item['uraian_kegiatan'] ?? '-';
    final status = item['status'] ?? '-';
    final pelaksana = item['pelaksana'] ?? '-';
    final biaya = item['biaya'] ?? 0;

    final isBisa = status == 'Bisa Diperbaiki';
    final statusColor =
        isBisa ? const Color(0xFF10B981) : const Color(0xFFEF4444);

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
                      isBisa
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
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
                  child: Text(isBisa ? 'Diperbaiki' : 'Tidak Bisa',
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
                Text(uraian,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey[100]),
                const SizedBox(height: 10),
                _detailRow(Icons.calendar_today_rounded, 'Tanggal', tanggal),
                const SizedBox(height: 6),
                _detailRow(Icons.engineering_rounded, 'Pelaksana', pelaksana),
                if (biaya > 0) ...[
                  const SizedBox(height: 6),
                  _detailRow(
                    Icons.payments_rounded,
                    'Biaya',
                    NumberFormat.currency(
                            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                        .format(biaya),
                  ),
                ],
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
