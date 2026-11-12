import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/models/tindak_lanjut_model.dart';
import 'package:rsia_employee_app/screen/menu/tindak_lanjut/tindak_lanjut_detail_screen.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class TindakLanjutScreen extends StatefulWidget {
  const TindakLanjutScreen({super.key});

  @override
  State<TindakLanjutScreen> createState() => _TindakLanjutScreenState();
}

class _TindakLanjutScreenState extends State<TindakLanjutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<TindakLanjutItem> _allItems = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final List<String> _tabs = [
    'Semua',
    'Aktif',
    'Pending',
    'In Progress',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await Api().getData('/undangan/tindak-lanjut/saya?status=all');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        List rawList = body['data'] ?? [];
        final items = rawList
            .map((e) => TindakLanjutItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        if (mounted) {
          setState(() {
            _allItems = items;
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Msg.error(context, 'Gagal memuat tindak lanjut: $e');
      }
    }
  }

  List<TindakLanjutItem> _getFilteredItems() {
    final tabIndex = _tabController.index;
    final tabName = _tabs[tabIndex];

    var list = _allItems.where((item) {
      if (tabName == 'Aktif') {
        return item.status.toLowerCase() != 'selesai' &&
            item.status.toLowerCase() != 'dibatalkan';
      } else if (tabName == 'Pending') {
        return item.status.toLowerCase() == 'pending';
      } else if (tabName == 'In Progress') {
        return item.status.toLowerCase() == 'in_progress';
      } else if (tabName == 'Selesai') {
        return item.status.toLowerCase() == 'selesai';
      }
      return true; // Semua
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) {
        final matchPerihal = item.perihalRapat.toLowerCase().contains(q);
        final matchSurat = item.suratNomor.toLowerCase().contains(q);
        final matchDeskripsi = item.deskripsi.toLowerCase().contains(q);
        final matchPic = item.picNama.toLowerCase().contains(q);
        return matchPerihal || matchSurat || matchDeskripsi || matchPic;
      }).toList();
    }

    return list;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF10B981);
      case 'in_progress':
        return primaryColor;
      case 'dibatalkan':
        return Colors.redAccent;
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredItems();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tindak Lanjut Rapat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Segarkan',
            onPressed: _fetchData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelColor: primaryColor,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: _tabs.map((t) {
                // Count badge
                int count = 0;
                if (t == 'Semua') {
                  count = _allItems.length;
                } else if (t == 'Aktif') {
                  count = _allItems
                      .where((i) =>
                          i.status.toLowerCase() != 'selesai' &&
                          i.status.toLowerCase() != 'dibatalkan')
                      .length;
                } else if (t == 'Pending') {
                  count = _allItems.where((i) => i.status.toLowerCase() == 'pending').length;
                } else if (t == 'In Progress') {
                  count = _allItems.where((i) => i.status.toLowerCase() == 'in_progress').length;
                } else if (t == 'Selesai') {
                  count = _allItems.where((i) => i.status.toLowerCase() == 'selesai').length;
                }
                return Tab(
                  child: Row(
                    children: [
                      Text(t),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
                decoration: InputDecoration(
                  hintText: 'Cari tugas, rapat, atau nomor surat...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: primaryColor,
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _buildTaskCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.task_alt_outlined, size: 48, color: primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada tugas tindak lanjut',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ditemukan tugas yang cocok dengan kata kunci pencarian.'
                  : 'Anda belum memiliki tugas tindak lanjut rapat yang ditugaskan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TindakLanjutItem item) {
    final statusColor = _getStatusColor(item.status);
    final deadline = item.deadlineDate;
    final isOverdue = item.isOverdue;
    final pct = item.progressPercent.clamp(0, 100);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TindakLanjutDetailScreen(
              id: item.id,
              initialItem: item,
            ),
          ),
        );
        _fetchData();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOverdue ? Colors.red.withOpacity(0.4) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Nomor Surat & Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.suratNomor,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatusLabel(item.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Perihal Rapat
            Text(
              item.perihalRapat,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            // Deskripsi Tindak Lanjut
            Text(
              item.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100.0,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom meta: Deadline & Feedbacks count
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 13,
                  color: isOverdue ? Colors.red : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  deadline != null
                      ? 'Target: ${DateFormat('dd MMM yyyy').format(deadline)}'
                      : 'Tanpa tenggat',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOverdue ? Colors.red : Colors.grey.shade600,
                    fontWeight: isOverdue ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Overdue',
                      style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                if (item.feedbacksCount > 0) ...[
                  Icon(Icons.chat_bubble_outline, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(
                    '${item.feedbacksCount} respon',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
