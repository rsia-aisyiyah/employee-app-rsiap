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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Validasi'),
        content: Text(
          'Kirimkan notifikasi permintaan validasi data bulan ${_bulanNames[_selectedBulan - 1]} $_selectedTahun ke Validator unit (${_selectedUnit!.namaValidator ?? 'Validator'})?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim Notifikasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await MutuApi.requestValidation(
        depId: _selectedUnit!.depId,
        bulan: _selectedBulan,
        tahun: _selectedTahun,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Notifikasi terkirim'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ),
      );
    }
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
                                  if (_selectedUnit?.isPic == true) ...[
                                    _buildPicActionBar(),
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

  Widget _buildPicActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, size: 20, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Siap Divalidasi?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                ),
                Text(
                  'Kirim notifikasi langsung ke validator unit',
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
            child: const Text('Kirim Notif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
