import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_approval_cuti.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_list.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class ApprovalCuti extends StatefulWidget {
  const ApprovalCuti({super.key});

  @override
  State<ApprovalCuti> createState() => _ApprovalCutiState();
}

class _ApprovalCutiState extends State<ApprovalCuti>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final box = GetStorage();
  bool _isLoading = true;
  List _allData = [];
  String _selectedYear = DateTime.now().year.toString();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    var nik = box.read('sub');

    try {
      final res = await Api()
          .getData("/pegawai/$nik/cuti/approval?year=$_selectedYear");
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _allData = body['data'] ?? [];
          _isLoading = false;
        });
      } else {
        final body = json.decode(res.body);
        Msg.error(context, body['message'] ?? "Gagal memuat data approval");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Msg.error(
          context, "Koneksi gagal: Silahkan periksa koneksi internet Anda.");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApproval(String id, bool isApprove) async {
    String action = isApprove ? 'approve' : 'reject';
    String actionIndo = isApprove ? 'menyetujui' : 'menolak';

    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("${isApprove ? 'Setujui' : 'Tolak'} Pengajuan"),
            content:
                Text("Apakah Anda yakin ingin $actionIndo pengajuan cuti ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  isApprove ? "Ya, Setujui" : "Ya, Tolak",
                  style:
                      TextStyle(color: isApprove ? Colors.green : Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    var nik = box.read('sub');

    try {
      final res = await Api().putData({}, "/pegawai/$nik/cuti/$id/$action");
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        Msg.success(
            context, body['message'] ?? "Berhasil memperbarui status cuti");
        _loadData();
      } else {
        final body = json.decode(res.body);
        Msg.error(context, body['message'] ?? "Gagal memperbarui status cuti");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan sistem");
      setState(() => _isLoading = false);
    }
  }

  List _getFilteredData(String status) {
    return _allData.where((item) {
      String itemStatus = (item['status'] ?? item['status_cuti']).toString();
      return itemStatus == status;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildYearFilter(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListView("0"), // Menunggu
                _buildListView("2"), // Disetujui
                _buildListView("3"), // Ditolak
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "Approval Cuti",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildYearFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: primaryColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedYear,
            dropdownColor: primaryColor,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white),
            isExpanded: true,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            items: List.generate(5, (index) {
              final year = (DateTime.now().year - index).toString();
              return DropdownMenuItem(
                value: year,
                child: Text("Tahun Data: $year"),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedYear = value);
                _loadData();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Menunggu"),
                const SizedBox(width: 5),
                _buildTabBadge("0"),
              ],
            ),
          ),
          const Tab(text: "Disetujui"),
          const Tab(text: "Ditolak"),
        ],
      ),
    );
  }

  Widget _buildTabBadge(String status) {
    int count = _getFilteredData(status).length;
    if (count == 0 || _isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        count.toString(),
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildListView(String status) {
    if (_isLoading) {
      return const SkeletonList(padding: EdgeInsets.all(20));
    }

    List data = _getFilteredData(status);

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Tidak ada data pengajuan",
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return CardApprovalCuti(
            data: data[index],
            isPending: status == "0",
            onApprove: () =>
                _handleApproval(data[index]['id_cuti'].toString(), true),
            onReject: () =>
                _handleApproval(data[index]['id_cuti'].toString(), false),
          );
        },
      ),
    );
  }
}
