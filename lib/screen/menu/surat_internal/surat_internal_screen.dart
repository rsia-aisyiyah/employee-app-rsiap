import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_surat_internal.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/screen/menu/surat_internal/surat_internal_detail.dart';
import 'package:rsia_employee_app/screen/menu/surat_internal/surat_internal_add_screen.dart';

class SuratInternalScreen extends StatefulWidget {
  const SuratInternalScreen({super.key});

  @override
  State<SuratInternalScreen> createState() => _SuratInternalScreenState();
}

class _SuratInternalScreenState extends State<SuratInternalScreen> {
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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

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
      final box = GetStorage();
      final String? userDept = box.read('dep');

      String url = "/surat/internal/stats";
      if (userDept != null && userDept != '-' && userDept != 'null') {
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
      final box = GetStorage();
      String? dept = box.read('dep');

      var payload = {
        "page": page,
        "limit": 10,
        "sort": [
          {"field": "created_at", "direction": "desc"}
        ],
        "filters": []
      };

      if (dept != null && dept.isNotEmpty && dept != '-' && dept != 'null') {
        (payload['filters'] as List).add({
          "field": "penanggungJawab.departemen",
          "operator": "=",
          "value": dept
        });
      }

      if (_searchQuery.isNotEmpty) {
        (payload['filters'] as List).add({
          "field": "perihal",
          "operator": "like",
          "value": "%$_searchQuery%"
        });
      }

      String url = "/surat/internal/search?include=undangan,penanggungJawab";
      var res = await Api().postData(payload, url);

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
      Msg.error(context, "Gagal memuat data surat internal");
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
                "Surat Internal",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                "Arsip surat masuk & keluar",
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
            hintText: "Cari perihal atau nomor surat...",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _handleSearch('');
                    },
                  )
                : null,
          ),
        ),
      ),
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
              color: primaryColor,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _data.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  _searchController.text.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.inbox_outlined,
                                  size: 80,
                                  color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? "Surat tidak ditemukan"
                                    : "Belum ada surat internal",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _fetchData(page: 1),
                                child: const Text("Segarkan"),
                              )
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _data.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _data.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            var item = _data[index];
                            return CardSuratInternal(
                              dataSurat: item,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SuratInternalDetailScreen(
                                            dataSurat: item),
                                  ),
                                );
                              },
                            );
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
              builder: (context) => const SuratInternalAddScreen(),
            ),
          );

          if (result == true) {
            setState(() {
              _isLoading = true;
              _currentPage = 1;
            });
            _fetchStats();
            _fetchData(page: 1);
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
