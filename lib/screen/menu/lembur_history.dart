import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:intl/intl.dart';

class LemburHistoryScreen extends StatefulWidget {
  const LemburHistoryScreen({super.key});

  @override
  State<LemburHistoryScreen> createState() => _LemburHistoryScreenState();
}

class _LemburHistoryScreenState extends State<LemburHistoryScreen> {
  final box = GetStorage();
  List _history = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (_hasMore && !_isLoading) {
          _fetchHistory(page: _currentPage + 1);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      final nik = box.read('sub');
      debugPrint("DEBUG: Fetching lembur history for NIK: $nik, Page: $page");

      final response =
          await Api().getData('/lembur/history?nik=$nik&page=$page&limit=20');

      debugPrint("DEBUG: Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List newItems = body['data']['data'];

        debugPrint("DEBUG: Items found: ${newItems.length}");

        setState(() {
          if (page == 1) {
            _history = newItems;
          } else {
            _history.addAll(newItems);
          }
          _currentPage = page;
          _hasMore = body['data']['next_page_url'] != null;
        });
      } else {
        debugPrint("DEBUG: Response Body: ${response.body}");
      }
    } catch (e) {
      debugPrint("DEBUG: Error fetching history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENGAJUAN':
        return Colors.orange;
      case 'ACC1':
      case 'ACC2':
        return Colors.green;
      case 'DITOLAK':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Lembur"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchHistory(page: 1),
        child: _history.isEmpty && !_isLoading
            ? const Center(child: Text("Belum ada riwayat lembur"))
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _history.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _history.length) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ));
                  }

                  final item = _history[index];
                  final jamDatang = DateTime.parse(item['jam_datang']);
                  final jamPulang = item['jam_pulang'] != null
                      ? DateTime.parse(item['jam_pulang'])
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Date & Status
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE', 'id_ID')
                                        .format(jamDatang),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMMM yyyy', 'id_ID')
                                        .format(jamDatang),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(item['status'])
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: _getStatusColor(item['status'])
                                        .withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  item['status'],
                                  style: TextStyle(
                                    color: _getStatusColor(item['status']),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey[100]!),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                _buildTimeInfo(
                                    "DATANG",
                                    DateFormat('HH:mm').format(jamDatang),
                                    Icons.login_rounded),
                                VerticalDivider(
                                    color: Colors.grey[300],
                                    thickness: 0.5,
                                    indent: 5,
                                    endIndent: 5),
                                _buildTimeInfo(
                                    "PULANG",
                                    jamPulang != null
                                        ? DateFormat('HH:mm').format(jamPulang)
                                        : "--:--",
                                    Icons.logout_rounded),
                                VerticalDivider(
                                    color: Colors.grey[300],
                                    thickness: 0.5,
                                    indent: 5,
                                    endIndent: 5),
                                _buildTimeInfo("DURASI", "${item['durasi']}",
                                    Icons.timer_outlined,
                                    isHighlight: true),
                              ],
                            ),
                          ),
                        ),

                        // Activity Info
                        if (item['kegiatan'] != null &&
                            item['kegiatan'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(Icons.description_outlined,
                                          size: 12, color: primaryColor),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "KEGIATAN",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.grey[600],
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item['kegiatan'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon,
      {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isHighlight ? primaryColor : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isHighlight ? primaryColor : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
