import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_list.dart';

class ApprovalLemburScreen extends StatefulWidget {
  const ApprovalLemburScreen({super.key});

  @override
  State<ApprovalLemburScreen> createState() => _ApprovalLemburScreenState();
}

class _ApprovalLemburScreenState extends State<ApprovalLemburScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final box = GetStorage();
  
  bool _isLoading = true;
  List _allData = [];
  List _departments = [];
  Map _bio = {};
  
  // Filters
  bool _isDeptLocked = false;
  String? _selectedDept = 'all';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _showFilters = true;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _isLoading = true);
        _loadData().then((_) {
          if (mounted) setState(() => _isLoading = false);
        });
      }
    });
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _loadBio();
    await _loadDepartments();
    await _loadData();
    setState(() => _isLoading = false);
  }

  Future<void> _loadBio() async {
    try {
      final res = await Api().getData("/pegawai/${box.read('sub')}");
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        _bio = body['data'] ?? {};
        
        final String? userDept = _bio['departemen']?.toString();
        // Lock department if it is not '-' (only SDI with '-' can select other units)
        if (userDept != null && userDept != '-') {
          _isDeptLocked = true;
          _selectedDept = userDept;
        } else {
          _isDeptLocked = false;
          _selectedDept = 'all';
        }
      }
    } catch (e) {
      debugPrint("Error loading bio in ApprovalLembur: $e");
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final res = await Api().getData("/sdi/departemen?limit=100");
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _departments = body['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error loading departments: $e");
    }
  }

  Future<void> _loadData() async {
    final String status = _getStatusByTabIndex(_tabController.index);
    
    // Build parameters
    String url = "/sdi/lembur/approval?limit=100&status=$status&month=$_selectedMonth&year=$_selectedYear";
    
    if (_selectedDept != null && _selectedDept != 'all') {
      url += "&departemen=$_selectedDept";
    }
    
    if (_searchController.text.isNotEmpty) {
      url += "&search=${Uri.encodeComponent(_searchController.text.trim())}";
    }

    try {
      final res = await Api().getData(url);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          // Response is paginated under data.data
          _allData = body['data']?['data'] ?? [];
        });
      } else {
        final body = json.decode(res.body);
        Msg.error(context, body['message'] ?? "Gagal memuat data lembur");
      }
    } catch (e) {
      debugPrint("Connection error: $e");
    }
  }

  String _getStatusByTabIndex(int index) {
    switch (index) {
      case 0: return 'PENGAJUAN';
      case 1: return 'ACC1';
      case 2: return 'ACC2';
      case 3: return 'DITOLAK';
      default: return 'PENGAJUAN';
    }
  }

  bool _canApprove(Map item) {
    final String status = item['status']?.toString() ?? 'PENGAJUAN';
    final String? userDept = _bio['departemen']?.toString();
    final String? employeeDept = item['pegawai']?['departemen']?.toString();
    final String? employeeNik = item['pegawai']?['nik']?.toString();

    if (status == 'PENGAJUAN') {
      // Coordinator level approval
      if (!_isDeptLocked) return true; // SDI / Admin bypass
      
      // Exception: Allow DM5 (Kamar Operasi) coordinator to approve Eni Rusmawati (nik 2.401.0502)
      if (userDept == 'DM5' && employeeNik == '2.401.0502') {
        return true;
      }
      
      return userDept == employeeDept;
    }
    if (status == 'ACC1') {
      // SDI level approval (unlocked accounts only)
      return !_isDeptLocked;
    }
    return false;
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = true);
        _loadData().then((_) {
          if (mounted) setState(() => _isLoading = false);
        });
      }
    });
  }

  Future<void> _handleReject(Map item) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Tolak Pengajuan Lembur", style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text("Apakah Anda yakin ingin menolak pengajuan lembur dari ${item['pegawai']?['nama']}?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Ya, Tolak", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final payload = {
        'id': item['id'],
        'jam_datang': item['jam_datang'],
      };

      final res = await Api().postData(payload, '/sdi/lembur/reject');
      final body = json.decode(res.body);

      if (res.statusCode == 200) {
        Msg.success(context, body['message'] ?? "Berhasil menolak pengajuan lembur");
        _loadData();
      } else {
        Msg.error(context, body['message'] ?? "Gagal menolak pengajuan lembur");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan sistem");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Parse HH:mm:ss to minutes
  int _parseToMinutes(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty || durationStr == '-') return 0;
    try {
      if (durationStr.contains(':')) {
        final parts = durationStr.split(':');
        final int hours = int.parse(parts[0]);
        final int minutes = int.parse(parts[1]);
        return (hours * 60) + minutes;
      }
      return int.parse(durationStr.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (_) {
      return 0;
    }
  }

  // Format minutes back to HH:mm:ss
  String _minutesToTime(int totalMinutes) {
    final int hrs = totalMinutes ~/ 60;
    final int mins = totalMinutes % 60;
    final String padH = hrs.toString().padLeft(2, '0');
    final String padM = mins.toString().padLeft(2, '0');
    return "$padH:$padM:00";
  }

  Future<void> _handleApprove(Map item) async {
    final String currentStatus = item['status']?.toString() ?? 'PENGAJUAN';
    final String targetStatus = currentStatus == 'PENGAJUAN' ? 'ACC1' : 'ACC2';

    // Calculate default duration in minutes
    final int defaultMinutes = _parseToMinutes(item['durasi_pengajuan']);
    
    final TextEditingController kegiatanCtrl = TextEditingController(
      text: item['kegiatan'] == '-' ? '' : item['kegiatan']
    );
    final TextEditingController durasiCtrl = TextEditingController(
      text: defaultMinutes.toString()
    );

    final formKey = GlobalKey<FormState>();

    final bool confirm = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: greenColor),
                  const SizedBox(width: 8),
                  const Text("Setujui Lembur", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Staff summary box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['pegawai']?['nama'] ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['pegawai']?['nik'] ?? '-',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                  Text(
                                    "Durasi: ${Helper.getDuration(item['jam_datang'], item['jam_pulang'])}",
                                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Kegiatan input
                        const Text("Detail Kegiatan Lembur *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: kegiatanCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Isi detail pekerjaan yang dilakukan...",
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Kegiatan wajib diisi";
                            }
                            if (val.trim().length > 200) {
                              return "Maksimal 200 karakter";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Duration input
                        const Text("Durasi Disetujui (Menit) *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: durasiCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Masukkan angka dalam menit",
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Durasi wajib diisi";
                            }
                            final int? mins = int.tryParse(val);
                            if (mins == null || mins < 0) {
                              return "Input menit tidak valid";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Ya, Setujui", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final int approvedMins = int.parse(durasiCtrl.text);
      final String durasiAccStr = _minutesToTime(approvedMins);

      final payload = {
        'id': item['id'],
        'jam_datang': item['jam_datang'],
        'status': targetStatus,
        'durasi_acc': durasiAccStr,
        'kegiatan': kegiatanCtrl.text.trim(),
      };

      final res = await Api().postData(payload, '/sdi/lembur/approve');
      final body = json.decode(res.body);

      if (res.statusCode == 200) {
        Msg.success(context, body['message'] ?? "Lembur berhasil disetujui!");
        _loadData();
      } else {
        Msg.error(context, body['message'] ?? "Gagal menyetujui lembur");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan sistem: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openManageSpl() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const SplManagementSheet();
      },
    ).then((_) {
      // Reload on close in case changes were made
      setState(() => _isLoading = true);
      _loadData().then((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCutoffBanner(),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _showFilters ? _buildFilterPanel() : const SizedBox.shrink(),
          ),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const SkeletonList(padding: EdgeInsets.all(16))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: primaryColor,
                    child: _buildListView(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openManageSpl,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.draw_rounded, color: Colors.white),
        label: const Text("Kelola SPL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "Approval Lembur",
        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
      ),
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt, color: Colors.white),
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
      ],
    );
  }

  Widget _buildCutoffBanner() {
    return Container(
      width: double.infinity,
      color: Colors.amber[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber[800], size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Batas Cutoff: Lembur bulan lalu maksimal disetujui tgl 2 pukul 23:59 bulan ini.",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Month Selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(_months[index]),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedMonth = val;
                            _isLoading = true;
                          });
                          _loadData().then((_) {
                            if (mounted) setState(() => _isLoading = false);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Year Selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                      items: [
                        DateTime.now().year - 1,
                        DateTime.now().year,
                        DateTime.now().year + 1
                      ].map((y) {
                        return DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedYear = val;
                            _isLoading = true;
                          });
                          _loadData().then((_) {
                            if (mounted) setState(() => _isLoading = false);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // Unit/Department Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _isDeptLocked ? Colors.grey[200] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDept,
                      isExpanded: true,
                      disabledHint: Text(
                        _departments.firstWhere(
                          (d) => d['dep_id'] == _selectedDept,
                          orElse: () => {'nama': _selectedDept ?? ''},
                        )['nama'],
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                      items: _isDeptLocked
                          ? null
                          : [
                              const DropdownMenuItem(value: 'all', child: Text("Semua Unit")),
                              ..._departments.map((d) {
                                return DropdownMenuItem(
                                  value: d['dep_id'].toString(),
                                  child: Text(d['nama'].toString(), overflow: TextOverflow.ellipsis),
                                );
                              }),
                            ],
                      onChanged: _isDeptLocked
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDept = val;
                                  _isLoading = true;
                                });
                                _loadData().then((_) {
                                  if (mounted) setState(() => _isLoading = false);
                                });
                              }
                            },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Search box
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Cari Nama/NIK...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _isLoading = true);
                                _loadData().then((_) {
                                  if (mounted) setState(() => _isLoading = false);
                                });
                              },
                              child: const Icon(Icons.clear, size: 18),
                            )
                          : const Icon(Icons.search, size: 18, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey[500],
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: "Koord"),
          Tab(text: "SDI"),
          Tab(text: "Setuju"),
          Tab(text: "Tolak"),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_allData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Tidak ada pengajuan lembur",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _allData.length,
      itemBuilder: (context, index) {
        final item = _allData[index];
        return _buildOvertimeCard(item);
      },
    );
  }

  Widget _buildOvertimeCard(Map item) {
    final bool canAction = _canApprove(item);
    final String status = item['status']?.toString() ?? 'PENGAJUAN';

    Color statusColor = Colors.blue;
    String statusLabel = status;
    if (status == 'PENGAJUAN') {
      statusColor = Colors.orange;
      statusLabel = "Menunggu Koordinator";
    } else if (status == 'ACC1') {
      statusColor = Colors.purple;
      statusLabel = "Menunggu SDI";
    } else if (status == 'ACC2') {
      statusColor = Colors.green;
      statusLabel = "Disetujui";
    } else if (status == 'DITOLAK') {
      statusColor = Colors.red;
      statusLabel = "Ditolak";
    }

    String initials = "?";
    final String? empName = item['pegawai']?['nama']?.toString();
    if (empName != null && empName.isNotEmpty) {
      initials = empName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                radius: 22,
                child: Text(
                  initials,
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empName ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          item['pegawai']?['nik'] ?? '-',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['pegawai']?['dep']?['nama'] ?? '-',
                            style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Details grid
          _buildInfoRow(
            Icons.login_rounded,
            "Masuk",
            item['jam_datang'] != null ? Helper.formatDate(item['jam_datang']) : '-',
            iconColor: Colors.green[400]!,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.logout_rounded,
            "Pulang",
            item['jam_pulang'] != null ? Helper.formatDate(item['jam_pulang']) : '-',
            iconColor: Colors.orange[400]!,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.hourglass_empty,
                  "Pengajuan",
                  _formatDurationText(item['durasi_pengajuan']),
                ),
              ),
              if (status != 'PENGAJUAN' && status != 'DITOLAK') ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoRow(
                    Icons.check_circle_outline,
                    "Disetujui",
                    _formatDurationText(item['durasi_acc']),
                    textColor: Colors.green[800]!,
                    iconColor: greenColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          _buildInfoRow(
            Icons.work_history_outlined,
            "Kegiatan",
            item['kegiatan'] ?? '-',
          ),
          const SizedBox(height: 12),

          // SPL Info Badge
          _buildSplBadge(item),

          // Actions
          if (canAction) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(item),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("Tolak", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(item),
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text("Setujui", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? textColor, Color iconColor = Colors.black45}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDurationText(dynamic durationStr) {
    if (durationStr == null || durationStr == '-' || durationStr == '00:00:00') return '-';
    final String durStr = durationStr.toString();
    if (durStr.contains(':')) {
      final parts = durStr.split(':');
      final int hours = int.parse(parts[0]);
      final int minutes = int.parse(parts[1]);
      final int totalMins = (hours * 60) + minutes;
      if (hours > 0) {
        return "$totalMins mnt (${hours}j ${minutes}m)";
      }
      return "$totalMins menit";
    }
    return "$durStr menit";
  }

  Widget _buildSplBadge(Map item) {
    final String? noSpl = item['no_spl']?.toString();
    final String? kegiatanSpl = item['kegiatan_spl']?.toString();

    if (noSpl != null && noSpl.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: Colors.green[700], size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "SPL: $noSpl ${kegiatanSpl != null ? '($kegiatanSpl)' : ''}",
                style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Missing SPL
    return InkWell(
      onTap: () {
        // Automatically open the add SPL form prefilled with date and employee
        _openAddSplPrefilled(item);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 14),
                const SizedBox(width: 6),
                Text(
                  "Tanpa SPL (Klik untuk membuat)",
                  style: TextStyle(color: Colors.amber[850], fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.amber[700], size: 10),
          ],
        ),
      ),
    );
  }

  void _openAddSplPrefilled(Map overtimeItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Extract date YYYY-MM-DD
        String initialDate = DateTime.now().toString().substring(0, 10);
        if (overtimeItem['jam_datang'] != null) {
          initialDate = overtimeItem['jam_datang'].toString().substring(0, 10);
        }
        
        final Map employee = {
          'nik': overtimeItem['pegawai']?['nik']?.toString() ?? '',
          'nama': overtimeItem['pegawai']?['nama']?.toString() ?? '',
          'departemen': overtimeItem['pegawai']?['departemen']?.toString() ?? '',
        };

        return SplManagementSheet(
          initialTab: 1, // Start on Add tab
          prefilledDate: initialDate,
          prefilledEmployee: employee,
          prefilledKegiatan: overtimeItem['kegiatan'] == '-' ? '' : overtimeItem['kegiatan'],
        );
      },
    ).then((_) {
      setState(() => _isLoading = true);
      _loadData().then((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    });
  }
}

// ==========================================
// SPL Management Sheets Sub-system
// ==========================================
class SplManagementSheet extends StatefulWidget {
  final int initialTab;
  final String? prefilledDate;
  final Map? prefilledEmployee;
  final String? prefilledKegiatan;

  const SplManagementSheet({
    super.key,
    this.initialTab = 0,
    this.prefilledDate,
    this.prefilledEmployee,
    this.prefilledKegiatan,
  });

  @override
  State<SplManagementSheet> createState() => _SplManagementSheetState();
}

class _SplManagementSheetState extends State<SplManagementSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final box = GetStorage();
  
  // List Tab State
  List _splList = [];
  bool _listLoading = false;
  String _listDate = DateTime.now().toString().substring(0, 10);
  String _listSearch = '';
  int _currentPage = 1;
  int _lastPage = 1;
  Timer? _searchDebounce;

  // Create Tab Form State
  String _createDate = DateTime.now().toString().substring(0, 10);
  String _generatedSplNo = '';
  bool _noSplLoading = false;
  
  Map? _selectedEmployee;
  final TextEditingController _employeeSearchCtrl = TextEditingController();
  List _employeeSuggestions = [];
  bool _suggestionLoading = false;
  Timer? _empSearchDebounce;
  bool _showDropdown = false;
  
  final TextEditingController _kegiatanCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // Prefills
    if (widget.prefilledDate != null) {
      _listDate = widget.prefilledDate!;
      _createDate = widget.prefilledDate!;
    }
    if (widget.prefilledEmployee != null) {
      _selectedEmployee = widget.prefilledEmployee;
      _employeeSearchCtrl.text = _selectedEmployee!['nama'] ?? '';
    }
    if (widget.prefilledKegiatan != null) {
      _kegiatanCtrl.text = widget.prefilledKegiatan!;
    }

    _fetchSplList();
    if (_tabController.index == 1) {
      _generateSplNumber();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _employeeSearchCtrl.dispose();
    _kegiatanCtrl.dispose();
    _searchDebounce?.cancel();
    _empSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchSplList({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _listLoading = true;
      _currentPage = page;
    });

    // Read user bio for department lock (only coordinators list their own SPLs)
    String? userDept = box.read('departemen');
    if (userDept == null) {
      try {
        final bioRes = await Api().getData("/pegawai/${box.read('sub')}");
        if (bioRes.statusCode == 200) {
          final bioBody = json.decode(bioRes.body);
          userDept = bioBody['data']?['departemen']?.toString();
        }
      } catch (_) {}
    }

    final bool isLocked = userDept != null && userDept != '-' && userDept != 'DM9' && userDept != 'IT';

    String url = "/sdi/lembur/spl?limit=10&page=$page&date=$_listDate";
    if (isLocked) {
      url += "&departemen=$userDept";
    }
    if (_listSearch.isNotEmpty) {
      url += "&search=${Uri.encodeComponent(_listSearch.trim())}";
    }

    try {
      final res = await Api().getData(url);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (mounted) {
          setState(() {
            _splList = body['data']?['data'] ?? [];
            _lastPage = body['data']?['last_page'] ?? 1;
            _listLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching SPLs: $e");
      if (mounted) setState(() => _listLoading = false);
    }
  }

  Future<void> _deleteSpl(Map spl) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Hapus SPL", style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text("Hapus Surat Perintah Lembur untuk ${spl['nama_pegawai']} pada ${spl['tanggal']}?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    if (mounted) setState(() => _listLoading = true);
    try {
      final payload = {
        'id_peg': spl['id_peg'],
        'tanggal': spl['tanggal'],
      };
      
      final res = await Api().deleteData(payload, '/sdi/lembur/spl');
      final body = json.decode(res.body);

      if (res.statusCode == 200) {
        Msg.success(context, body['message'] ?? "SPL berhasil dihapus");
        _fetchSplList(page: _currentPage);
      } else {
        Msg.error(context, body['message'] ?? "Gagal menghapus SPL");
        if (mounted) setState(() => _listLoading = false);
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan sistem");
      if (mounted) setState(() => _listLoading = false);
    }
  }

  // Autocomplete search employees
  void _searchEmployees(String query) {
    _empSearchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _employeeSuggestions = [];
        _showDropdown = false;
      });
      return;
    }

    _empSearchDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _suggestionLoading = true);
      
      // Determine dept lock
      String? userDept = box.read('departemen');
      final bool isLocked = userDept != null && userDept != '-' && userDept != 'DM9' && userDept != 'IT';

      String url = "/sdi/pegawai/list?limit=10&search=${Uri.encodeComponent(query.trim())}";
      if (isLocked) {
        url += "&departemen=$userDept";
      }

      try {
        final res = await Api().getData(url);
        if (res.statusCode == 200) {
          final body = json.decode(res.body);
          if (mounted) {
            setState(() {
              _employeeSuggestions = body['data'] ?? [];
              _showDropdown = _employeeSuggestions.isNotEmpty;
              _suggestionLoading = false;
            });
          }
        }
      } catch (_) {
        if (mounted) setState(() => _suggestionLoading = false);
      }
    });
  }

  // Generate SPL sequence number
  Future<void> _generateSplNumber() async {
    setState(() {
      _noSplLoading = true;
      _generatedSplNo = "Menghitung...";
    });

    final DateTime dateObj = DateTime.parse(_createDate);
    final List<String> romanMonths = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'];
    final String roman = romanMonths[dateObj.month - 1];
    final int year = dateObj.year;

    // Get department code (lock code or employee dept)
    String? userDept = box.read('departemen');
    String deptCode = 'SDI';
    final bool isLocked = userDept != null && userDept != '-' && userDept != 'DM9' && userDept != 'IT';

    if (isLocked) {
      deptCode = userDept;
    } else if (_selectedEmployee != null && _selectedEmployee!['departemen'] != null && _selectedEmployee!['departemen'] != '-') {
      deptCode = _selectedEmployee!['departemen'].toString();
    }

    if (deptCode.toUpperCase() == 'SDI' || deptCode.toUpperCase() == 'DM9') {
      deptCode = 'SDM';
    }

    int seq = 100;
    try {
      final res = await Api().getData('/sdi/lembur/spl/last');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final String lastNo = body['data'].toString();
          final String prefix = lastNo.split('/')[0];
          final int? parsedSeq = int.tryParse(prefix);
          if (parsedSeq != null) {
            seq = parsedSeq + 1;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _generatedSplNo = "$seq/SPKL-${deptCode.toUpperCase()}/$roman/$year";
        _noSplLoading = false;
      });
    }
  }

  Future<void> _saveSpl() async {
    if (_selectedEmployee == null || _kegiatanCtrl.text.trim().isEmpty) {
      Msg.warning(context, "Semua field bertanda bintang wajib diisi");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'no_spl': _generatedSplNo,
        'tanggal': _createDate,
        'nik': _selectedEmployee!['nik']?.toString(),
        'kegiatan': _kegiatanCtrl.text.trim(),
      };

      final res = await Api().postData(payload, '/sdi/lembur/spl');
      final body = json.decode(res.body);

      if (res.statusCode == 200) {
        Msg.success(context, body['message'] ?? "SPL Berhasil disimpan!");
        // Reset form
        setState(() {
          _selectedEmployee = null;
          _employeeSearchCtrl.clear();
          _kegiatanCtrl.clear();
          _tabController.animateTo(0); // Switch to list tab
        });
        _fetchSplList();
      } else {
        Msg.error(context, body['message'] ?? "Gagal menyimpan SPL");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan sistem: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            // Modal Indicator
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 45,
              height: 4.5,
              decoration: BoxDecoration(color: Colors.grey[350], borderRadius: BorderRadius.circular(4)),
            ),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.draw_rounded, color: greenColor, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        "Kelola Surat Perintah Lembur",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),

            // Sub Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "Daftar SPL"),
                Tab(text: "Tambah SPL"),
              ],
            ),

            // Tab Bar View Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSplListTab(),
                  _buildAddSplTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplListTab() {
    return Column(
      children: [
        // List Filters
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Date picker
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(_listDate),
                      firstDate: DateTime(DateTime.now().year - 2),
                      lastDate: DateTime(DateTime.now().year + 2),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(primary: primaryColor),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _listDate = picked.toString().substring(0, 10);
                      });
                      _fetchSplList(page: 1);
                    }
                  },
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _listDate,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        Icon(Icons.calendar_month, size: 16, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Search NIK / Nama / No SPL
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
                  child: TextField(
                    onChanged: (val) {
                      setState(() => _listSearch = val);
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                        _fetchSplList(page: 1);
                      });
                    },
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Cari SPL...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List Content
        Expanded(
          child: _listLoading
              ? const SkeletonList(padding: EdgeInsets.all(16))
              : _splList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feed_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text("Belum ada SPL di tanggal ini", style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _splList.length,
                      itemBuilder: (context, index) {
                        final spl = _splList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey[100]!),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      spl['no_spl']?.toString() ?? '-',
                                      style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      spl['nama_pegawai']?.toString() ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      "${spl['nik_pegawai']} • ${spl['nama_departemen'] ?? '-'}",
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      spl['kegiatan']?.toString() ?? '-',
                                      style: TextStyle(color: Colors.grey[700], fontSize: 11),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _deleteSpl(spl),
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),

        // Pagination Footer
        if (_lastPage > 1 && !_listLoading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Page $_currentPage of $_lastPage", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage == 1 ? null : () => _fetchSplList(page: _currentPage - 1),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100], elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: const Text("Prev", style: TextStyle(color: Colors.black87, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _currentPage == _lastPage ? null : () => _fetchSplList(page: _currentPage + 1),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100], elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: const Text("Next", style: TextStyle(color: Colors.black87, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddSplTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            const Text("Tanggal Lembur *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(_createDate),
                  firstDate: DateTime(DateTime.now().year - 2),
                  lastDate: DateTime(DateTime.now().year + 2),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(primary: primaryColor),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _createDate = picked.toString().substring(0, 10);
                  });
                  _generateSplNumber();
                }
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_createDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Icon(Icons.calendar_month, color: primaryColor, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Generated SPL Number
            const Text("Nomor SPL (Auto)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              height: 48,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.grey[150], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
              alignment: Alignment.centerLeft,
              child: _noSplLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
                  : Text(
                      _generatedSplNo,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green[800]),
                    ),
            ),
            const SizedBox(height: 16),

            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Employee
                    const Text("Pilih Pegawai *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _selectedEmployee != null ? Colors.grey[150] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _employeeSearchCtrl,
                              onChanged: _searchEmployees,
                              enabled: _selectedEmployee == null,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: "Cari Nama atau NIK...",
                                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_suggestionLoading)
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5))
                          else if (_selectedEmployee != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedEmployee = null;
                                  _employeeSearchCtrl.clear();
                                  _employeeSuggestions = [];
                                  _showDropdown = false;
                                });
                                _generateSplNumber();
                              },
                              child: const Icon(Icons.clear, size: 18),
                            )
                        ],
                      ),
                    ),
                    if (_selectedEmployee != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Pegawai Terpilih: ${_selectedEmployee!['nama']} (${_selectedEmployee!['nik']})",
                          style: TextStyle(color: greenColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Kegiatan Input
                    const Text("Kegiatan Lembur *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _kegiatanCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Tuliskan rincian kegiatan / penugasan lembur...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSaving || _selectedEmployee == null || _kegiatanCtrl.text.trim().isEmpty
                          ? null
                          : _saveSpl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Simpan SPL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),

                // Suggestions drop-overlay
                if (_showDropdown)
                  Positioned(
                    top: 68, // just below the Pilih Pegawai text field (12 font + 6 space + 48 container + some space)
                    left: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _employeeSuggestions.length,
                        itemBuilder: (context, index) {
                          final emp = _employeeSuggestions[index];
                          return ListTile(
                            dense: true,
                            title: Text(emp['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${emp['nik']} • ${emp['jbtn'] ?? '-'} (${emp['departemen'] ?? '-'})", style: const TextStyle(fontSize: 10)),
                            onTap: () {
                              setState(() {
                                _selectedEmployee = emp;
                                _employeeSearchCtrl.text = emp['nama'];
                                _showDropdown = false;
                              });
                              _generateSplNumber();
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
