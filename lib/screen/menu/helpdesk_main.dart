import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/helpdesk_form.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/components/loadingku.dart';

class HelpdeskMainScreen extends StatefulWidget {
  const HelpdeskMainScreen({super.key});

  @override
  State<HelpdeskMainScreen> createState() => _HelpdeskMainScreenState();
}

class _HelpdeskMainScreenState extends State<HelpdeskMainScreen> {
  bool isLoading = true;
  bool isIT = false;
  int activeTab = 0; // 0: Laporan Masuk, 1: Manajemen Tiket

  List allTickets = [];
  List filteredTickets = [];

  List managementTickets = [];
  List filteredManagementTickets = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    // 1. Quick check from storage
    _checkPermissionsFromStorage();

    // 2. Comprehensive check from API (Bio)
    await _getBio();

    // 3. Fetch initial data
    _fetchData();
  }

  void _checkPermissionsFromStorage() {
    final box = GetStorage();
    final String dep = (box.read('dep') ?? "").toString().trim().toUpperCase();
    final String role =
        (box.read('role') ?? "").toString().trim().toUpperCase();
    final String jbtn =
        (box.read('jbtn') ?? "").toString().trim().toUpperCase();

    bool isITUser = false;
    if (dep == 'IT' ||
        dep == 'SIT' ||
        dep.contains('TEKNOLOGI') ||
        dep.contains('SISTEM')) isITUser = true;
    if (role == 'IT' || role.contains('ADMIN')) isITUser = true;
    if (jbtn.contains('IT') || jbtn.contains('SISTEM')) isITUser = true;

    if (isITUser) {
      setState(() => isIT = true);
    }
  }

  Future<void> _getBio() async {
    final box = GetStorage();
    final sub = box.read('sub');
    if (sub == null) return;

    try {
      // Include 'dep' relation to get full department name
      var res = await Api().getData("/pegawai/$sub?include=dep");
      var body = json.decode(res.body);

      if (res.statusCode == 200 && body['data'] != null) {
        var userData = body['data'];

        // Robust check across multiple possible structures
        String deptName =
            (userData['dep']?['nama'] ?? "").toString().toUpperCase();
        String deptCode =
            (userData['departemen'] ?? "").toString().toUpperCase();
        String jbtn = (userData['jbtn'] ?? "").toString().toUpperCase();

        if (deptName.contains('TEKNOLOGI') ||
            deptName.contains('SISTEM') ||
            deptCode == 'IT' ||
            deptCode == 'SIT' ||
            jbtn.contains('IT')) {
          setState(() => isIT = true);
        }
      }
    } catch (e) {
      debugPrint("Error fetching bio for permissions: $e");
    }
  }

  Future<void> _fetchData() async {
    if (activeTab == 0) {
      await _fetchIncomingReports();
    } else {
      await _fetchManagementTickets();
    }
  }

  Future<void> _fetchIncomingReports() async {
    setState(() => isLoading = true);
    try {
      var res = await Api().getData('/helpdesk/tiket/history');
      var body = json.decode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          allTickets = body['data']['data'] ?? [];
          filteredTickets = allTickets;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        Msg.error(context, body['message'] ?? "Gagal memuat data");
      }
    } catch (e) {
      setState(() => isLoading = false);
      Msg.error(context, "Terjadi kesalahan: $e");
    }
  }

  Future<void> _fetchManagementTickets() async {
    setState(() => isLoading = true);
    try {
      var res = await Api().getData('/helpdesk/tiket/active');
      var body = json.decode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          managementTickets = body['data']['data'] ?? [];
          filteredManagementTickets = managementTickets;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        Msg.error(context, body['message'] ?? "Gagal memuat data");
      }
    } catch (e) {
      setState(() => isLoading = false);
      Msg.error(context, "Terjadi kesalahan: $e");
    }
  }

  void _filterData(String query) {
    setState(() {
      if (activeTab == 0) {
        filteredTickets = allTickets.where((ticket) {
          final laporan =
              (ticket['isi_laporan'] ?? '').toString().toLowerCase();
          final noTiket = (ticket['no_tiket'] ?? '').toString().toLowerCase();
          return laporan.contains(query.toLowerCase()) ||
              noTiket.contains(query.toLowerCase());
        }).toList();
      } else {
        filteredManagementTickets = managementTickets.where((ticket) {
          final keluhan = (ticket['keluhan'] ?? '').toString().toLowerCase();
          final noTiket = (ticket['no_tiket'] ?? '').toString().toLowerCase();
          final pelapor =
              (ticket['pelapor']?['nama'] ?? '').toString().toLowerCase();
          return keluhan.contains(query.toLowerCase()) ||
              noTiket.contains(query.toLowerCase()) ||
              pelapor.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _acceptReport(int id) async {
    setState(() => isLoading = true);
    try {
      var res = await Api().postData({
        'temp_log_id': id,
        'prioritas': 'Medium', // Default
      }, '/helpdesk/tiket/create');

      var body = json.decode(res.body);
      if (res.statusCode == 200) {
        Msg.success(context, "Tiket berhasil diterbitkan");
        _fetchIncomingReports();
      } else {
        setState(() => isLoading = false);
        Msg.error(context, body['message'] ?? "Gagal memproses laporan");
      }
    } catch (e) {
      setState(() => isLoading = false);
      Msg.error(context, "Terjadi kesalahan: $e");
    }
  }

  Color _getStatusColor(String status) {
    status = status.toString().trim().toUpperCase();
    switch (status) {
      case 'WAITING':
        return const Color(0xFFFFB300); // Vibrant Amber
      case 'OPEN':
        return const Color(0xFF03A9F4); // Light Blue
      case 'PROSES':
      case 'PROCESS':
      case 'PROCESSED':
        return const Color(0xFF673AB7); // Deep Purple
      case 'SELESAI':
      case 'FINISHED':
      case 'CLOSED':
        return const Color(0xFF00C853); // Emerald Green
      case 'BATAL':
      case 'CANCEL':
      case 'CANCELLED':
        return const Color(0xFFFF5252); // Soft Red
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getStatusIcon(String status) {
    status = status.toString().trim().toUpperCase();
    switch (status) {
      case 'WAITING':
        return Icons.watch_later_outlined;
      case 'OPEN':
        return Icons.mail_outline_rounded;
      case 'PROSES':
      case 'PROCESS':
      case 'PROCESSED':
        return Icons.sync_rounded;
      case 'SELESAI':
      case 'FINISHED':
      case 'CLOSED':
        return Icons.check_circle_rounded;
      case 'BATAL':
      case 'CANCEL':
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? Center(child: loadingku(fullPage: false))
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: primaryColor,
                    child: (activeTab == 0
                                ? filteredTickets
                                : filteredManagementTickets)
                            .isEmpty
                        ? _buildEmptyState()
                        : _buildTicketList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: activeTab == 0
          ? FloatingActionButton.extended(
              heroTag: 'helpdesk-main-fab',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HelpdeskFormScreen()),
                );
                _fetchIncomingReports(); // Refresh after return
              },
              label: const Text(
                "Tiket Baru",
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              icon: const Icon(Icons.add_task),
              backgroundColor: primaryColor,
              elevation: 4,
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 25,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withBlue(210).withGreen(180)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                "Helpdesk IT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          if (isIT) ...[
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  _buildTabItem(0, "Laporan Masuk", Icons.message_rounded),
                  _buildTabItem(1, "Manajemen Tiket", Icons.confirmation_num),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterData,
              decoration: InputDecoration(
                hintText: activeTab == 0
                    ? "Cari nomor tiket atau keluhan..."
                    : "Cari pelapor atau no tiket...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    bool isActive = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            activeTab = index;
            _searchController.clear();
          });
          _fetchData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 4)
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? primaryColor : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color:
                      isActive ? primaryColor : Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    List tickets = activeTab == 0 ? filteredTickets : filteredManagementTickets;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tickets.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildTicketCard(tickets[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    bool isEmptyData =
        (activeTab == 0 ? allTickets : managementTickets).isEmpty;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 100),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Icon(Icons.support_agent_outlined,
                  size: 80, color: Colors.grey[200]),
            ),
            const SizedBox(height: 30),
            Text(
              isEmptyData ? "Belum Ada Tiket" : "Pencarian Tidak Ditemukan",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                isEmptyData
                    ? "Belum ada laporan kendala IT yang masuk saat ini."
                    : "Coba gunakan kata kunci lain untuk mencari tiket.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map ticket) {
    String status = (ticket['status'] ?? 'WAITING').toString().toUpperCase();
    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    String content = activeTab == 0
        ? (ticket['isi_laporan'] ?? '-')
        : (ticket['keluhan'] ?? '-');

    String reporterName = activeTab == 0
        ? (ticket['pegawai']?['nama'] ?? '-')
        : (ticket['pelapor']?['nama'] ?? '-');

    String deptName = activeTab == 0
        ? (ticket['departemen']?['nama'] ?? '-')
        : (ticket['departemen']?['nama'] ?? '-');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 6),
                                Text(
                                  status,
                                  style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            ticket['created_at'] != null
                                ? _formatDate(ticket['created_at'].toString())
                                : ticket['tanggal'] != null
                                    ? _formatDate(ticket['tanggal'].toString())
                                    : '-',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3142),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              "$reporterName ($deptName)",
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (ticket['no_tiket'] != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.confirmation_num_rounded,
                                size: 14, color: primaryColor.withOpacity(0.5)),
                            const SizedBox(width: 6),
                            Text(
                              ticket['no_tiket'].toString(),
                              style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ],
                      if (isIT) ...[
                        const SizedBox(height: 15),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        if (activeTab == 0 && status == 'WAITING')
                          _buildActionButton(
                            "RESPON",
                            Icons.bolt,
                            Colors.orange,
                            () => _acceptReport(ticket['id']),
                          )
                        else if (activeTab == 1)
                          _buildActionButton(
                            "MANAGE",
                            Icons.settings_outlined,
                            primaryColor,
                            () => _showManagementModal(ticket),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          backgroundColor: color.withOpacity(0.05),
        ),
      ),
    );
  }

  void _showManagementModal(Map ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManagementBottomSheet(
        ticket: ticket,
        onSuccess: () {
          _fetchManagementTickets();
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }
}

class _ManagementBottomSheet extends StatefulWidget {
  final Map ticket;
  final VoidCallback onSuccess;

  const _ManagementBottomSheet({required this.ticket, required this.onSuccess});

  @override
  State<_ManagementBottomSheet> createState() => _ManagementBottomSheetState();
}

class _ManagementBottomSheetState extends State<_ManagementBottomSheet> {
  String? selectedStatus;
  String? selectedTechnicianNik;
  String? selectedTechnicianName;
  final TextEditingController _solutionController = TextEditingController();
  final TextEditingController _techSearchController = TextEditingController();
  bool isSaving = false;

  List technicians = [];
  bool isLoadingTech = false;
  DateTime? selectedFinishDateTime;
  final TextEditingController _finishTimeController = TextEditingController();

  String _formatDate(String date) {
    if (date == "null" || date == "") return "-";
    DateTime dt = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.ticket['status'] ?? 'Open';
    _solutionController.text = widget.ticket['solusi'] ?? '';
    selectedTechnicianNik = widget.ticket['nik_teknisi'];
    selectedTechnicianName = widget.ticket['teknisi']?['nama'];
    if (selectedTechnicianName != null) {
      _techSearchController.text = selectedTechnicianName!;
    }

    if (widget.ticket['jam_selesai'] != null) {
      try {
        selectedFinishDateTime =
            DateTime.parse(widget.ticket['jam_selesai'].toString()).toLocal();
        _finishTimeController.text =
            _formatDate(selectedFinishDateTime!.toString());
      } catch (e) {
        debugPrint("Error parsing jam_selesai: $e");
      }
    }
  }

  Future<void> _pickFinishDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedFinishDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(selectedFinishDateTime ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          selectedFinishDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _finishTimeController.text =
              _formatDate(selectedFinishDateTime!.toString());
        });
      }
    }
  }

  Future<void> _searchTechnician(String query) async {
    if (query.length < 3) {
      setState(() => technicians = []);
      return;
    }
    setState(() => isLoadingTech = true);
    try {
      var res = await Api().getData('/pegawai/search?q=$query');
      var body = json.decode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          technicians = body['data'] ?? [];
          isLoadingTech = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingTech = false);
    }
  }

  Future<void> _updateTicket() async {
    // If selectedTechnicianNik is null, try to fallback to widget data
    if (selectedTechnicianNik == null) {
      selectedTechnicianNik = widget.ticket['nik_teknisi']?.toString() ??
          widget.ticket['teknisi']?['nik']?.toString();
    }

    if (selectedTechnicianNik == null || selectedTechnicianNik!.isEmpty) {
      if (_techSearchController.text.isNotEmpty) {
        Msg.error(context, "Klik pada nama teknisi dari hasil pencarian");
      } else {
        Msg.error(context, "Silakan pilih teknisi terlebih dahulu");
      }
      return;
    }

    setState(() => isSaving = true);
    try {
      var res = await Api().putData({
        'status': selectedStatus,
        'nik_teknisi': selectedTechnicianNik,
        'solusi': _solutionController.text,
        'jam_selesai': selectedFinishDateTime != null
            ? selectedFinishDateTime!.toIso8601String()
            : (selectedStatus == 'Selesai'
                ? DateTime.now().toIso8601String()
                : null),
      }, '/helpdesk/tiket/${widget.ticket['id']}/update');

      var body = json.decode(res.body);
      if (res.statusCode == 200) {
        Msg.success(context, "Tiket berhasil diperbarui");
        widget.onSuccess();
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() => isSaving = false);
        Msg.error(context, body['message'] ?? "Gagal memperbarui tiket");
      }
    } catch (e) {
      setState(() => isSaving = false);
      Msg.error(context, "Terjadi kesalahan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Manajemen Detail Tiket",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                      "NOMOR TIKET", widget.ticket['no_tiket'] ?? '-', true),
                ),
                Expanded(
                  child: _buildInfoItem("PELAPOR",
                      widget.ticket['pelapor']?['nama'] ?? '-', false),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoItem("KELUHAN", widget.ticket['keluhan'] ?? '-', false),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              "Status Tiket",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  items: ['Open', 'Proses', 'Selesai', 'Batal']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedStatus = v),
                ),
              ),
            ),
            if (selectedStatus == 'Selesai') ...[
              const SizedBox(height: 25),
              const Text(
                "Tanggal & Jam Selesai",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickFinishDateTime,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _finishTimeController,
                    decoration: InputDecoration(
                      hintText: "Pilih tanggal & jam selesai...",
                      prefixIcon: Icon(Icons.calendar_today,
                          size: 18, color: primaryColor),
                      fillColor: Colors.grey[50],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 25),
            const SizedBox(height: 10),
            _buildTechnicianSelector(),
            const SizedBox(height: 25),
            const Text(
              "Solusi / Keterangan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _solutionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Tuliskan solusi atau langkah perbaikan...",
                fillColor: Colors.grey[50],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSaving ? null : _updateTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Simpan Perubahan",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
            color: isPrimary ? primaryColor : const Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianSelector() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: _techSearchController,
            onChanged: _searchTechnician,
            decoration: InputDecoration(
              hintText: "Cari & Pilih Teknisi...",
              border: InputBorder.none,
              suffixIcon: isLoadingTech
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
            ),
          ),
        ),
        if (technicians.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: technicians.length,
              itemBuilder: (context, index) {
                var tech = technicians[index];
                return ListTile(
                  title: Text(tech['nama'] ?? '-',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(tech['nik'] ?? '-',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  onTap: () {
                    setState(() {
                      final nik = tech['nik']?.toString() ??
                          tech['nip']?.toString() ??
                          tech['id_user']?.toString();

                      selectedTechnicianNik = nik;
                      selectedTechnicianName = tech['nama']?.toString();
                      _techSearchController.text =
                          tech['nama']?.toString() ?? '';
                      technicians = [];
                      FocusManager.instance.primaryFocus?.unfocus();
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
