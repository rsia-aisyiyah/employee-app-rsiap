import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/lapor_ikp_form.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class LaporIkpHistoryScreen extends StatefulWidget {
  const LaporIkpHistoryScreen({super.key});

  @override
  State<LaporIkpHistoryScreen> createState() => _LaporIkpHistoryScreenState();
}

class _LaporIkpHistoryScreenState extends State<LaporIkpHistoryScreen> {
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
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
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
      final response = await Api().getData('/sdi/ikp/history?page=$page');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List newItems = body['data']['data'] ?? [];

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
        final body = jsonDecode(response.body);
        Msg.error(context, body['message'] ?? "Gagal memuat riwayat");
      }
    } catch (e) {
      debugPrint("Error fetching IKP history: $e");
      Msg.error(context, "Terjadi kesalahan: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getGradingColor(String? grading) {
    if (grading == null) return Colors.grey;
    switch (grading.toUpperCase()) {
      case 'BIRU':
        return Colors.blue;
      case 'HIJAU':
        return Colors.green;
      case 'KUNING':
        return Colors.amber[700]!;
      case 'MERAH':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Riwayat IKP Unit",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchHistory(page: 1),
        color: primaryColor,
        child: _history.isEmpty && !_isLoading
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _history.length + (_hasMore ? 1 : 0),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == _history.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }

                  final item = _history[index];
                  final grading = item['grading_risiko']?.toString();
                  final gradingColor = _getGradingColor(grading);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['jenis_alias'] ?? 'IKP',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              if (grading != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: gradingColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: gradingColor.withOpacity(0.3), width: 1),
                                  ),
                                  child: Text(
                                    "Grading: $grading",
                                    style: TextStyle(
                                      color: gradingColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            item['insiden'] ?? '-',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(item['tanggal_insiden'] ?? ''),
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                              const SizedBox(width: 15),
                              Icon(Icons.meeting_room_outlined, size: 13, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item['nama_unit'] ?? '-',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 13, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Korban: ${item['nm_pasien'] ?? '-'}",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LaporIkpFormScreen()),
          );
          if (result == true || result == null) {
            _fetchHistory(page: 1);
          }
        },
        label: const Text(
          "Lapor IKP",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        icon: const Icon(Icons.add_alert_outlined),
        backgroundColor: primaryColor,
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 150),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                  )
                ],
              ),
              child: Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[300]),
            ),
            const SizedBox(height: 25),
            const Text(
              "Belum Ada Laporan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Belum ada laporan insiden (IKP) yang tercatat untuk unit kerja Anda saat ini.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
