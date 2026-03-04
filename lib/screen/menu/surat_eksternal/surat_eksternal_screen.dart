import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/surat_eksternal/surat_eksternal_add_screen.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class SuratEksternalScreen extends StatefulWidget {
  const SuratEksternalScreen({super.key});

  @override
  State<SuratEksternalScreen> createState() => _SuratEksternalScreenState();
}

class _SuratEksternalScreenState extends State<SuratEksternalScreen> {
  final box = GetStorage();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List _data = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'pengajuan': 0,
    'disetujui': 0,
    'ditolak': 0,
  };

  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;

  String _searchQuery = "";
  String _statusFilter = "";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_currentPage < _lastPage && !_isLoadingMore) {
        _fetchMoreData();
      }
    }
  }

  Future<void> _fetchStats() async {
    try {
      final String? userDept = box.read('dep');
      // Logic for koordinator usually checking role, but following web pattern
      // we can pass department if not koordinator.
      // Simplified: current app seems to use 'dep' consistently.

      String url = "/surat/eksternal/stats";
      if (userDept != null && userDept != '-' && userDept != 'null') {
        // check if user has special roles in real implementation
        // for now we assume standard user filtering by department
        url += "?departemen=$userDept";
      }

      var res = await Api().getData(url);
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (body['success']) {
          setState(() {
            _stats = body['data'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  Future<void> _fetchData({int page = 1}) async {
    setState(() {
      if (page == 1) _isLoading = true;
      _currentPage = page;
    });

    try {
      final String? userDept = box.read('dep');
      String url = "/surat/eksternal?page=$page&limit=10";

      if (_searchQuery.isNotEmpty) {
        url += "&search=${Uri.encodeComponent(_searchQuery)}";
      }

      if (_statusFilter.isNotEmpty) {
        url += "&filter[status]=${_statusFilter.toLowerCase()}";
      }

      if (_startDate != null) {
        url +=
            "&filter[tgl_terbit][operator]=>=&filter[tgl_terbit][value]=${DateFormat('yyyy-MM-dd').format(_startDate!)}";
      }

      if (_endDate != null) {
        url +=
            "&filter[tgl_terbit][operator]=<==&filter[tgl_terbit][value]=${DateFormat('yyyy-MM-dd').format(_endDate!)}";
      }

      // Auto-filter by User's Department if not special role
      if (userDept != null && userDept != '-' && userDept != 'null') {
        url += "&departemen=$userDept";
      }

      var res = await Api().getData(url);
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        var newData = body['data'] ?? [];
        var meta = body['meta'] ?? {};

        setState(() {
          if (page == 1) {
            _data = newData;
          } else {
            _data.addAll(newData);
          }
          _lastPage = meta['last_page'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      Msg.error(context, "Gagal memuat data surat eksternal");
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _fetchMoreData() async {
    setState(() => _isLoadingMore = true);
    await _fetchData(page: _currentPage + 1);
  }

  void _handleSearch(String val) {
    setState(() {
      _searchQuery = val;
    });
    _fetchData(page: 1);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter Surat",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _statusFilter = "";
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        child: const Text("Reset"),
                      )
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Status",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: ["", "Pengajuan", "Disetujui", "Ditolak"]
                              .map((s) {
                            return ChoiceChip(
                              label: Text(s.isEmpty ? "Semua" : s),
                              selected: _statusFilter == s,
                              onSelected: (selected) {
                                setModalState(() {
                                  _statusFilter = selected ? s : "";
                                });
                              },
                              selectedColor: primaryColor.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: _statusFilter == s
                                    ? primaryColor
                                    : Colors.black,
                                fontWeight: _statusFilter == s
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text("Rentang Tanggal Terbit",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setModalState(() => _startDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(_startDate == null
                                      ? "Mulai"
                                      : DateFormat('dd/MM/yyyy')
                                          .format(_startDate!)),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("s/d"),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setModalState(() => _endDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(_endDate == null
                                      ? "Selesai"
                                      : DateFormat('dd/MM/yyyy')
                                          .format(_endDate!)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchData(page: 1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Terapkan Filter",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildStatusBar(),
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _fetchStats();
                await _fetchData(page: 1);
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _data.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(15),
                          itemCount: _data.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _data.length) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildSuratCard(_data[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SuratEksternalAddScreen()),
          );
          if (result == true) {
            _fetchStats();
            _fetchData(page: 1);
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 10,
          bottom: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 5),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Surat Eksternal",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                "Arsip surat keluar",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          _buildStatItem("Total", _stats['total'].toString(), Colors.blue),
          const SizedBox(width: 10),
          _buildStatItem(
              "Pengajuan", _stats['pengajuan'].toString(), Colors.orange),
          const SizedBox(width: 10),
          _buildStatItem(
              "Disetujui", _stats['disetujui'].toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _handleSearch,
                decoration: InputDecoration(
                  hintText: "Cari perihal, nomor, alamat...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _showFilterSheet,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: _statusFilter.isNotEmpty || _startDate != null
                    ? primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Icon(
                Icons.filter_list,
                color: _statusFilter.isNotEmpty || _startDate != null
                    ? Colors.white
                    : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("Tidak ada data ditemukan",
              style: TextStyle(color: Colors.grey[600])),
          TextButton(
            onPressed: () => _fetchData(page: 1),
            child: const Text("Segarkan"),
          )
        ],
      ),
    );
  }

  Widget _buildSuratCard(Map item) {
    String status = item['status'] ?? 'pengajuan';
    Color statusColor = Colors.orange;
    if (status == 'disetujui') statusColor = Colors.green;
    if (status == 'ditolak') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailModal(item),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['no_surat'] ?? "(Belum Terbit)",
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['perihal'] ?? "-",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item['alamat'] ?? "-",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Terbit",
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[400])),
                        Text(
                          item['tgl_terbit'] != null
                              ? Helper.formatDate4(item['tgl_terbit'])
                              : "-",
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("PJ",
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[400])),
                        Text(
                          item['penanggung_jawab']?['nama'] ??
                              item['pj'] ??
                              "-",
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailModal(Map item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Detail Surat Eksternal",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildDetailItem(
                  "Nomor Surat", item['no_surat'] ?? "(Belum Terbit)"),
              _buildDetailItem("Perihal", item['perihal']),
              _buildDetailItem("Tujuan / Alamat", item['alamat']),
              _buildDetailItem(
                  "Tanggal Terbit",
                  item['tgl_terbit'] != null
                      ? Helper.formatDate4(item['tgl_terbit'])
                      : "-"),
              _buildDetailItem("Penanggung Jawab",
                  "${item['penanggung_jawab']?['nama'] ?? '-'}\n(${item['pj']})"),
              if (item['catatan'] != null &&
                  item['catatan'].toString().isNotEmpty)
                _buildDetailItem("Catatan", item['catatan']),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SuratEksternalAddScreen(data: item)),
                        );
                        if (result == true) {
                          _fetchStats();
                          _fetchData(page: 1);
                        }
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text("Edit",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDelete(item),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text("Hapus",
                          style: TextStyle(color: Colors.white)),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 5),
          Text(value ?? "-",
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _confirmDelete(Map item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Surat?"),
        content: const Text("Data yang dihapus tidak dapat dikembalikan."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close sheet
              _deleteSurat(item['no_surat']);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSurat(String? noSurat) async {
    if (noSurat == null) return;

    // Encode to base64 if needed by backend (as seen in controller)
    String encodedNo = base64.encode(utf8.encode(noSurat));

    try {
      var res = await Api().deleteWitoutData("/surat/eksternal/$encodedNo");
      if (res.statusCode == 200) {
        Msg.success(context, "Surat berhasil dihapus");
        _fetchStats();
        _fetchData(page: 1);
      } else {
        var body = json.decode(res.body);
        Msg.error(context, body['message'] ?? "Gagal menghapus surat");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan: $e");
    }
  }
}
