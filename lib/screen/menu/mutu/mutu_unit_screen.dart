import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/mutu_api.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/models/inmut_model.dart';

class MutuUnitScreen extends StatefulWidget {
  final String? initialDepId;
  final int? initialBulan;
  final int? initialTahun;

  const MutuUnitScreen({
    super.key,
    this.initialDepId,
    this.initialBulan,
    this.initialTahun,
  });

  @override
  State<MutuUnitScreen> createState() => _MutuUnitScreenState();
}

class _MutuUnitScreenState extends State<MutuUnitScreen> {
  bool _isLoadingUnits = true;
  bool _isLoadingData = false;

  List<InmutUnitItem> _units = [];
  InmutUnitItem? _selectedUnit;

  late int _selectedBulan;
  late int _selectedTahun;

  List<InmutValidationItem> _indicators = [];
  String _activeFilter = 'Semua';

  final List<String> _bulanNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to previous month if day <= 10 (validation cycle), otherwise current month
    if (widget.initialBulan != null && widget.initialTahun != null) {
      _selectedBulan = widget.initialBulan!;
      _selectedTahun = widget.initialTahun!;
    } else if (now.day <= 10 && now.month > 1) {
      _selectedBulan = now.month - 1;
      _selectedTahun = now.year;
    } else if (now.day <= 10 && now.month == 1) {
      _selectedBulan = 12;
      _selectedTahun = now.year - 1;
    } else {
      _selectedBulan = now.month;
      _selectedTahun = now.year;
    }

    _loadMyUnits();
  }

  Future<void> _loadMyUnits() async {
    setState(() => _isLoadingUnits = true);
    final units = await MutuApi.getMyUnits(bulan: _selectedBulan, tahun: _selectedTahun);
    if (!mounted) return;

    setState(() {
      _units = units;
      if (units.isNotEmpty) {
        if (widget.initialDepId != null) {
          _selectedUnit = units.firstWhere(
            (u) => u.depId == widget.initialDepId,
            orElse: () => units.first,
          );
        } else {
          _selectedUnit = units.first;
        }
      } else {
        _selectedUnit = null;
      }
      _isLoadingUnits = false;
    });

    if (_selectedUnit != null) {
      _fetchIndicators();
    }
  }

  Future<void> _fetchIndicators() async {
    if (_selectedUnit == null) return;
    setState(() => _isLoadingData = true);

    final list = await MutuApi.getValidasiList(
      depId: _selectedUnit!.depId,
      bulan: _selectedBulan,
      tahun: _selectedTahun,
    );

    if (!mounted) return;
    setState(() {
      _indicators = list;
      _isLoadingData = false;
    });
  }

  List<InmutValidationItem> get _filteredIndicators {
    switch (_activeFilter) {
      case 'Belum Validasi':
        return _indicators.where((i) => i.status != 'verified').toList();
      case 'Terverifikasi':
        return _indicators.where((i) => i.status == 'verified').toList();
      case 'Valid (AR ≥ 90%)':
        return _indicators.where((i) => i.isAgreementValid).toList();
      case 'Perhatian (AR < 90%)':
        return _indicators.where((i) => !i.isAgreementValid).toList();
      default:
        return _indicators;
    }
  }

  void _changePeriod(int deltaMonth) {
    var b = _selectedBulan + deltaMonth;
    var t = _selectedTahun;
    if (b > 12) {
      b = 1;
      t++;
    } else if (b < 1) {
      b = 12;
      t--;
    }
    setState(() {
      _selectedBulan = b;
      _selectedTahun = t;
    });
    _loadMyUnits();
  }

  Future<void> _handleRequestValidation() async {
    if (_selectedUnit == null) return;
    final unit = _selectedUnit!;

    if (!unit.isAllFilled) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Entri Belum Lengkap', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            'Terdapat ${unit.unfilledIndicators} dari ${unit.totalIndicators} indikator yang belum diisi datanya sama sekali.\n\nHarap lengkapi entri seluruh indikator sebelum meminta validasi.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    if (unit.isPremature) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Periode Belum Berakhir', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            'Pengajuan validasi untuk bulan berjalan baru dapat dilakukan mulai tanggal 25 (hari ini tanggal ${DateTime.now().day}).\n\nSilakan selesaikan pengumpulan data harian terlebih dahulu.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Pre-Submit Safety Checklist BottomSheet
    final noteController = TextEditingController();
    bool isAgreed = false;

    final submit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Konfirmasi Pengajuan Validasi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildAuditRow('Unit / Ruang', unit.namaRuang),
                      const Divider(height: 12),
                      _buildAuditRow('Periode', '${_bulanNames[_selectedBulan - 1]} $_selectedTahun'),
                      const Divider(height: 12),
                      _buildAuditRow('Kelengkapan', '${unit.filledIndicators}/${unit.totalIndicators} Indikator (100% Lengkap)'),
                      const Divider(height: 12),
                      _buildAuditRow('Validator Tujuan', unit.namaValidator ?? 'Validator Unit'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Catatan untuk Validator (Opsional):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan catatan tambahan jika ada...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setModalState(() => isAgreed = !isAgreed),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isAgreed,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (v) => setModalState(() => isAgreed = v ?? false),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Saya menyatakan seluruh data mutu harian bulan ini sudah lengkap dan siap divalidasi oleh validator.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: isAgreed ? () => Navigator.pop(ctx, true) : null,
                        child: const Text('Kirim Validasi →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (submit == true) {
      final res = await MutuApi.requestValidation(
        depId: unit.depId,
        bulan: _selectedBulan,
        tahun: _selectedTahun,
        catatan: noteController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Notifikasi terkirim'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (res['success'] == true) {
        _loadMyUnits();
      }
    }
  }

  Future<void> _handleCancelValidation() async {
    if (_selectedUnit == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tarik Pengajuan?'),
        content: const Text(
          'Status akan dikembalikan ke Draft sehingga Anda dapat mengoreksi data sebelum diajukan kembali ke Validator.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tarik Pengajuan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await MutuApi.cancelValidation(
        depId: _selectedUnit!.depId,
        bulan: _selectedBulan,
        tahun: _selectedTahun,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Pengajuan ditarik'),
          backgroundColor: res['success'] == true ? Colors.blueGrey : Colors.red,
        ),
      );
      if (res['success'] == true) {
        _loadMyUnits();
      }
    }
  }

  Future<void> _handleReturnRevision() async {
    if (_selectedUnit == null) return;
    final revController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_return_rounded, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Kembalikan ke PIC', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kembalikan data mutu unit ${_selectedUnit!.namaRuang} ke PIC (${_selectedUnit!.namaPic ?? 'PIC'}) untuk perbaikan.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text('Alasan / Catatan Perbaikan (Wajib):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: revController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Mohon periksa tanggal 14, denominator masih 0...',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () {
              if (revController.text.trim().length < 5) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Catatan perbaikan minimal 5 karakter')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Kembalikan Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await MutuApi.returnRevision(
        depId: _selectedUnit!.depId,
        bulan: _selectedBulan,
        tahun: _selectedTahun,
        catatan: revController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Data dikembalikan ke PIC'),
          backgroundColor: res['success'] == true ? Colors.deepOrange : Colors.red,
        ),
      );
      if (res['success'] == true) {
        _loadMyUnits();
      }
    }
  }

  Widget _buildAuditRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indikator Mutu Unit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              'Validasi & Analisa Capaian (PMKP)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _fetchIndicators,
          ),
        ],
      ),
      body: _isLoadingUnits
          ? const Center(child: CircularProgressIndicator())
          : _units.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildHeaderBar(),
                    Expanded(
                      child: _isLoadingData
                          ? const Center(child: CircularProgressIndicator())
                          : RefreshIndicator(
                              onRefresh: _fetchIndicators,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                children: [
                                  _buildSummaryKpiCard(),
                                  const SizedBox(height: 12),
                                  if (_selectedUnit != null) ...[
                                    _buildStatusBanner(),
                                    const SizedBox(height: 12),
                                  ],
                                  _buildFilterChips(),
                                  const SizedBox(height: 12),
                                  if (_filteredIndicators.isEmpty)
                                    _buildEmptyIndicatorList()
                                  else
                                    ..._filteredIndicators.map((item) => _buildIndicatorCard(item)),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Unit Terdaftar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Akun Anda belum terdaftar sebagai PIC maupun Validator pada Master Unit Mutu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Row 1: Unit Selector Dropdown
          Row(
            children: [
              const Icon(Icons.business_outlined, size: 20, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<InmutUnitItem>(
                      value: _selectedUnit,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      items: _units.map((unit) {
                        return DropdownMenuItem<InmutUnitItem>(
                          value: unit,
                          child: Text(
                            unit.namaRuang,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedUnit = val);
                          _fetchIndicators();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedUnit?.isValidator == true ? 'Validator' : 'PIC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Month / Year Period Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left, size: 22),
                onPressed: () => _changePeriod(-1),
              ),
              InkWell(
                onTap: _showMonthYearPicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF475569)),
                      const SizedBox(width: 6),
                      Text(
                        '${_bulanNames[_selectedBulan - 1]} $_selectedTahun',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right, size: 22),
                onPressed: () => _changePeriod(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        int tempBulan = _selectedBulan;
        int tempTahun = _selectedTahun;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setModalState(() => tempTahun--),
                      ),
                      Text(
                        '$tempTahun',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setModalState(() => tempTahun++),
                      ),
                    ],
                  ),
                  const Divider(),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, idx) {
                      final m = idx + 1;
                      final isSelected = m == tempBulan;
                      return InkWell(
                        onTap: () {
                          setModalState(() => tempBulan = m);
                          setState(() {
                            _selectedBulan = tempBulan;
                            _selectedTahun = tempTahun;
                          });
                          Navigator.pop(ctx);
                          _loadMyUnits();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _bulanNames[idx],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryKpiCard() {
    final total = _indicators.length;
    final verified = _indicators.where((i) => i.status == 'verified').length;
    final pending = total - verified;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildKpiItem('Total Indikator', '$total', const Color(0xFF3B82F6), Icons.list_alt_rounded),
          Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
          _buildKpiItem('Tervalidasi', '$verified', const Color(0xFF10B981), Icons.check_circle_outline),
          Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
          _buildKpiItem('Menunggu', '$pending', const Color(0xFFF59E0B), Icons.schedule_outlined),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_selectedUnit == null) return const SizedBox.shrink();
    final unit = _selectedUnit!;
    final status = unit.submissionStatus;
    final isPic = unit.isPic;
    final isValidator = unit.isValidator;

    // 1. Tervalidasi Penuh
    if (status == 'verified') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_rounded, size: 22, color: Color(0xFF059669)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tervalidasi Penuh (100%)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                  ),
                  Text(
                    'Seluruh indikator telah disahkan oleh validator unit.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF047857)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Status Revisi (Dikembalikan Validator)
    if (status == 'revision') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment_return_rounded, size: 22, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perlu Revisi / Perbaikan Data',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                  ),
                  Text(
                    unit.revisionNote != null && unit.revisionNote!.isNotEmpty
                        ? 'Catatan: ${unit.revisionNote}'
                        : 'Validator meminta perbaikan data pada bulan ini.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFFB91C1C)),
                  ),
                ],
              ),
            ),
            if (isPic) ...[
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _handleRequestValidation,
                child: const Text('Ajukan Ulang', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      );
    }

    // 3. Status Menunggu Respon Validator (Requested)
    if (status == 'requested') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 22, color: Color(0xFFD97706)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menunggu Respon Validator',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                  ),
                  Text(
                    unit.requestedAt != null
                        ? 'Diajukan ${unit.requestedAt}'
                        : 'Permintaan validasi sedang diproses validator.',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            if (isPic && unit.canCancel) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _handleCancelValidation,
                child: const Text('Batal Kirim', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
            if (isValidator) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _handleReturnRevision,
                child: const Text('Minta Revisi', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      );
    }

    // 4. Status Draft
    if (isPic) {
      if (!unit.isAllFilled) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 22, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entri Belum Lengkap',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    Text(
                      '${unit.filledIndicators} dari ${unit.totalIndicators} indikator terisi. Lengkapi data untuk mengajukan validasi.',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _handleRequestValidation,
                child: const Text('Info', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ),
            ],
          ),
        );
      }

      if (unit.isPremature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 22, color: Color(0xFF16A34A)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengajuan Buka Mulai Tgl 25',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                    ),
                    Text(
                      'Selesaikan pengumpulan data harian hingga akhir bulan.',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _handleRequestValidation,
                child: const Text('Jadwal', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
              ),
            ],
          ),
        );
      }

      // Siap Minta Validasi
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF93C5FD)),
        ),
        child: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, size: 22, color: Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Siap Divalidasi',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                  ),
                  Text(
                    'Kirimkan notifikasi langsung ke ${unit.namaValidator ?? 'Validator Unit'}',
                    style: TextStyle(fontSize: 10.5, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _handleRequestValidation,
              child: const Text('Minta Validasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    // Default for Validator in draft mode
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tahap Entri Harian (Draft)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
                Text(
                  'PIC (${unit.namaPic ?? 'PIC'}) masih dalam proses pengumpulan data bulan ini.',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'Semua',
      'Belum Validasi',
      'Terverifikasi',
      'Valid (AR ≥ 90%)',
      'Perhatian (AR < 90%)'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _activeFilter = f);
              },
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                ),
              ),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyIndicatorList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.filter_list_off, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Tidak ada indikator mutu pada filter ini',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(InmutValidationItem item) {
    final isVerified = item.status == 'verified';
    final ar = item.agreementRate;
    final isArValid = item.isAgreementValid;

    Color arColor = isArValid ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Indicator Card
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.kategoriUtama != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.kategoriUtama!,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Target: ${item.targetSymbol} ${item.standar}%',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.namaInmut,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isVerified ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified ? Icons.check_circle : Icons.access_time_filled,
                        size: 11,
                        color: isVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isVerified ? 'Tervalidasi' : 'Pending',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Side-by-side comparison box (P1 vs P2 + AR)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // P1: PIC Input
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'P1 (Akumulasi PIC)',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${item.p1}%',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${item.sumNum}/${item.sumDenum})',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 10),

                // P2: Validator Verification
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'P2 (Hasil Validasi)',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${item.p2}%',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isVerified ? const Color(0xFF10B981) : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${item.numValidasi}/${item.denumValidasi})',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // AR Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: arColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: arColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'AR: $ar%',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: arColor),
                      ),
                      Text(
                        isArValid ? 'Valid' : 'Invalid',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: arColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Row(
              children: [
                // Button 1: Validasi Angka
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: primaryColor, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.rule_folder_outlined, size: 15, color: primaryColor),
                    label: Text(
                      isVerified ? 'Edit Validasi' : 'Validasi Data',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: primaryColor),
                    ),
                    onPressed: () => _openValidationDialog(item),
                  ),
                ),
                const SizedBox(width: 8),

                // Button 2: Analisa & Tindak Lanjut
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.analytics_outlined, size: 15),
                    label: const Text(
                      'Analisa Capaian',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _openAnalisaDialog(item),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── VALIDATION MODAL (P2 ADJUSTMENT) ──────────────────────────────────────
  void _openValidationDialog(InmutValidationItem item) {
    int numVal = item.numValidasi > 0 ? item.numValidasi : item.sumNum;
    int denumVal = item.denumValidasi > 0 ? item.denumValidasi : item.sumDenum;
    final catatanController = TextEditingController(text: item.catatan ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Calculate live P2 & AR
            final liveP1 = item.p1;
            final liveP2 = denumVal > 0 ? double.parse(((numVal / denumVal) * 100).toStringAsFixed(2)) : 0.0;
            double liveAr = 100.0;
            if (liveP1 > 0 || liveP2 > 0) {
              final minP = liveP1 < liveP2 ? liveP1 : liveP2;
              final maxP = liveP1 > liveP2 ? liveP1 : liveP2;
              liveAr = maxP > 0 ? double.parse(((minP / maxP) * 100).toStringAsFixed(2)) : 100.0;
            }
            final liveArValid = liveAr >= 90.0;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Validasi Data Indikator',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.sync, size: 14),
                          label: const Text('Samakan P1', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setModalState(() {
                              numVal = item.sumNum;
                              denumVal = item.sumDenum;
                            });
                          },
                        ),
                      ],
                    ),
                    Text(
                      item.namaInmut,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),

                    // Side-by-side verification editor
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // P1 Reference (Read-only)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Data Awal PIC (P1)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Num: ${item.sumNum} | Denum: ${item.sumDenum}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      'Capaian: ${item.p1}%',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 44, color: const Color(0xFFCBD5E1)),
                              const SizedBox(width: 12),

                              // P2 Inputs
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Validasi (P2)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          height: 32,
                                          child: TextFormField(
                                            initialValue: '$numVal',
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.zero,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                            onChanged: (val) {
                                              setModalState(() => numVal = int.tryParse(val) ?? 0);
                                            },
                                          ),
                                        ),
                                        const Text(' / ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(
                                          width: 50,
                                          height: 32,
                                          child: TextFormField(
                                            initialValue: '$denumVal',
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.zero,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                            onChanged: (val) {
                                              setModalState(() => denumVal = int.tryParse(val) ?? 0);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Capaian P2: $liveP2%',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Agreement Rate (AR P2/P1):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: liveArValid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: liveArValid ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                ),
                                child: Text(
                                  '$liveAr% (${liveArValid ? 'VALID' : 'INVALID'})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: liveArValid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Catatan Validator
                    const Text('Catatan Validasi (Opsional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: catatanController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Misal: Terdapat koreksi 3 sampel yang tidak memenuhi kriteria...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          final res = await MutuApi.storeValidasi(
                            idInmut: item.idInmut,
                            depId: _selectedUnit!.depId,
                            bulan: _selectedBulan,
                            tahun: _selectedTahun,
                            numValidasi: numVal,
                            denumValidasi: denumVal,
                            status: 'verified',
                            catatan: catatanController.text,
                          );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Validasi disimpan'),
                              backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                            ),
                          );
                          _fetchIndicators();
                        },
                        child: const Text('Simpan & Verifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── ANALISA & TINDAK LANJUT MODAL ─────────────────────────────────────────
  void _openAnalisaDialog(InmutValidationItem item) async {
    final yyyyMm = '${_selectedTahun.toString().padLeft(4, '0')}-${_selectedBulan.toString().padLeft(2, '0')}';
    
    // Fetch existing analysis if any
    final existing = await MutuApi.getAnalisa(
      depId: _selectedUnit!.depId,
      yyyyMm: yyyyMm,
      idInmut: item.idInmut,
    );

    if (!mounted) return;

    final analisaCtrl = TextEditingController(text: existing?.analisa ?? '');
    final tindakLanjutCtrl = TextEditingController(text: existing?.tindakLanjut ?? '');

    final numVal = item.numValidasi > 0 ? item.numValidasi : item.sumNum;
    final denumVal = item.denumValidasi > 0 ? item.denumValidasi : item.sumDenum;
    final finalScore = item.p2 > 0 ? item.p2 : item.p1;
    final isTargetMet = item.isTargetAchieved;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Analisa & Tindak Lanjut',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isTargetMet ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isTargetMet ? 'Target Tercapai ✅' : 'Belum Tercapai ⚠️',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isTargetMet ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.namaInmut} (Capaian: $finalScore% | Target: ${item.targetSymbol} ${item.standar}%)',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),

                    // Quick Template Buttons
                    const Text('Pilih Template Analisa Instan:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildTemplateChip(
                          label: '🟢 Target Tercapai (SOP Patuh)',
                          onTap: () {
                            setModalState(() {
                              analisaCtrl.text =
                                  'Capaian indikator ${item.namaInmut} pada periode ${_bulanNames[_selectedBulan - 1]} $_selectedTahun sebesar $finalScore% telah memenuhi target standar RS (${item.targetSymbol} ${item.standar}%). Pelaksanaan pelayanan dan kepatuhan petugas terhadap SOP terpelihara dengan baik.';
                              tindakLanjutCtrl.text =
                                  'Pertahankan konsistensi kepatuhan petugas dan lakukan pengawasan monitoring berkala.';
                            });
                          },
                        ),
                        _buildTemplateChip(
                          label: '🟡 Belum Tercapai (Beban Kerja/SDM)',
                          onTap: () {
                            setModalState(() {
                              analisaCtrl.text =
                                  'Capaian indikator ${item.namaInmut} sebesar $finalScore% belum mencapai target standar RS (${item.targetSymbol} ${item.standar}%). Kendala dipicu oleh tingginya beban kerja unit dan keterbatasan personil pada jam sibuk.';
                              tindakLanjutCtrl.text =
                                  'Evaluasi redistribusi penugasan, koordinasi jadwal jaga, serta refresh edukasi kepatuhan SOP.';
                            });
                          },
                        ),
                        _buildTemplateChip(
                          label: '🔴 Belum Tercapai (Sarana/BHP)',
                          onTap: () {
                            setModalState(() {
                              analisaCtrl.text =
                                  'Capaian indikator ${item.namaInmut} sebesar $finalScore% belum mencapai target standar RS (${item.targetSymbol} ${item.standar}%). Kendala teknis terkait ketersediaan dan kecepatan pasokan logistik/sarana penunjang.';
                              tindakLanjutCtrl.text =
                                  'Koordinasi dengan bagian terkait untuk optimalisasi ketersediaan sarana dan penyediaan buffer stock.';
                            });
                          },
                        ),
                        _buildTemplateChip(
                          label: '⚪ Nihil / 0 Kasus',
                          onTap: () {
                            setModalState(() {
                              analisaCtrl.text =
                                  'Pada periode ${_bulanNames[_selectedBulan - 1]} $_selectedTahun tidak ditemukan kejadian/kasus (0 kejadian). Target mutu terpenuhi.';
                              tindakLanjutCtrl.text =
                                  'Pertahankan sistem pencegahan dan lakukan pencatatan aktif setiap ada tindakan.';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Analisa Text Field
                    const Text('Uraian Analisa Capaian:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: analisaCtrl,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan analisa hasil pengumpulan data...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tindak Lanjut Text Field
                    const Text('Rencana Tindak Lanjut:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: tindakLanjutCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan rencana aksi perbaikan mutu...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Committee Feedback (if exists)
                    if (existing?.supervisi != null || existing?.rekomendasi != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_outlined, size: 14, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text(
                                  'Rekomendasi Komite PMKP',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                            if (existing?.supervisi != null) ...[
                              const SizedBox(height: 4),
                              Text('Supervisi: ${existing!.supervisi}', style: const TextStyle(fontSize: 11)),
                            ],
                            if (existing?.rekomendasi != null) ...[
                              const SizedBox(height: 2),
                              Text('Rekomendasi: ${existing!.rekomendasi}', style: const TextStyle(fontSize: 11)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (analisaCtrl.text.trim().isEmpty || tindakLanjutCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Analisa dan Tindak Lanjut wajib diisi.')),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          final res = await MutuApi.storeAnalisa(
                            idInmut: item.idInmut,
                            analisa: analisaCtrl.text,
                            tindakLanjut: tindakLanjutCtrl.text,
                            jmlNum: numVal,
                            jmlDenum: denumVal,
                            yyyyMm: yyyyMm,
                          );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Analisa berhasil disimpan'),
                              backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                            ),
                          );
                          _fetchIndicators();
                        },
                        child: const Text('Simpan Analisa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTemplateChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
      ),
    );
  }
}
