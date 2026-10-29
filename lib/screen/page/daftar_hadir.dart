import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../api/request.dart';
import '../../config/colors.dart';
import '../../utils/fonts.dart';
import 'scan.dart';

class DaftarHadirPage extends StatefulWidget {
  final Map dataUdgn;

  const DaftarHadirPage({super.key, required this.dataUdgn});

  @override
  State<DaftarHadirPage> createState() => _DaftarHadirPageState();
}

class _DaftarHadirPageState extends State<DaftarHadirPage> {
  List<dynamic> allPenerima = [];
  List<dynamic> filteredPenerima = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterStatus = 'all'; // 'all', 'hadir', 'belum'
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Check if initial participants are already available in widget data
    final initialList =
        (widget.dataUdgn['peserta'] ?? widget.dataUdgn['penerima']) as List?;
    if (initialList != null && initialList.isNotEmpty) {
      allPenerima = List.from(initialList);
      _applyFilter();
      isLoading = false;
    }

    // Always fetch latest data in background / initial
    fetchUndangan();
  }

  Future<void> fetchUndangan() async {
    final id = widget.dataUdgn['id'] ??
        widget.dataUdgn['undangan_id'] ??
        widget.dataUdgn['surat']?['no_surat'] ??
        widget.dataUdgn['no_surat'];

    try {
      final String url =
          "/undangan/${base64Encode(utf8.encode(id.toString()))}";
      var res = await Api().getData(url);

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        final data = body['data'];
        final list = (data['peserta'] ?? data['penerima'] ?? []) as List;

        if (mounted) {
          setState(() {
            allPenerima = List.from(list);
            _applyFilter();
            isLoading = false;
          });
        }
      } else {
        if (mounted && allPenerima.isEmpty) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && allPenerima.isEmpty) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    filteredPenerima = allPenerima.where((item) {
      final pegawai = item['pegawai'] ?? item['detail'] ?? {};
      final nama = (pegawai['nama'] ?? '').toString().toLowerCase();
      final jbtn = (pegawai['jbtn'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      final matchesSearch = query.isEmpty ||
          nama.contains(query) ||
          jbtn.contains(query);

      final isHadir = item['kehadiran'] != null;
      bool matchesStatus = true;
      if (filterStatus == 'hadir') {
        matchesStatus = isHadir;
      } else if (filterStatus == 'belum') {
        matchesStatus = !isHadir;
      }

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get hadirCount =>
      allPenerima.where((item) => item['kehadiran'] != null).length;
  int get belumHadirCount => allPenerima.length - hadirCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: primaryColor,
              onRefresh: fetchUndangan,
              child: isLoading && allPenerima.isEmpty
                  ? _buildShimmerLoading()
                  : _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRAttendanceScanPage(),
            ),
          );
          if (res == true) {
            fetchUndangan();
          }
        },
        backgroundColor: primaryColor,
        elevation: 4,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: const Text(
          "Scan Presensi",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final perihal = widget.dataUdgn['perihal'] ??
        widget.dataUdgn['surat']?['perihal'] ??
        'Daftar Hadir';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Back Button & Title
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  "Daftar Hadir Undangan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Perihal Event Snippet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_note_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    perihal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                  _applyFilter();
                });
              },
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: "Cari nama pegawai atau jabatan...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                            _applyFilter();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Filter Tabs (Semua / Hadir / Belum)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("Semua (${allPenerima.length})", 'all'),
                const SizedBox(width: 8),
                _buildFilterChip("Hadir ($hadirCount)", 'hadir',
                    badgeColor: Colors.white),
                const SizedBox(width: 8),
                _buildFilterChip("Belum Hadir ($belumHadirCount)", 'belum',
                    badgeColor: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String statusKey,
      {Color? badgeColor}) {
    final isSelected = filterStatus == statusKey;

    return InkWell(
      onTap: () {
        setState(() {
          filterStatus = statusKey;
          _applyFilter();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? primaryColor : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (filteredPenerima.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty
                  ? Icons.person_search_rounded
                  : Icons.people_outline_rounded,
              size: 70,
              color: Colors.grey[350],
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isNotEmpty
                  ? "Tidak ada penerima yang cocok"
                  : "Belum ada daftar penerima",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: fontSemiBold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              searchQuery.isNotEmpty
                  ? "Coba gunakan kata kunci pencarian lain"
                  : "Daftar penerima undangan belum ditentukan",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: filteredPenerima.length,
      itemBuilder: (context, index) {
        final item = filteredPenerima[index];
        final pegawai = item['pegawai'] ?? item['detail'] ?? {};
        final nama = pegawai['nama'] ?? 'Tanpa Nama';
        final jbtn = pegawai['jbtn'] ?? '-';
        final kehadiran = item['kehadiran'];
        final isHadir = kehadiran != null;

        // Ambil inisial nama
        String initials = '?';
        if (nama.isNotEmpty) {
          final parts = nama.toString().trim().split(' ');
          if (parts.length > 1) {
            initials =
                '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          } else {
            initials = parts[0][0].toUpperCase();
          }
        }

        // Format jam kehadiran jika hadir
        String jamHadir = '';
        if (isHadir && kehadiran['created_at'] != null) {
          try {
            final raw = kehadiran['created_at'].toString();
            final parsed = DateTime.parse(raw);
            jamHadir =
                "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')} WIB";
          } catch (_) {
            jamHadir = kehadiran['created_at'].toString().split(' ').last;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHadir
                  ? const Color(0xFF34D399).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isHadir
                        ? const Color(0xFFE6FBF2)
                        : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: isHadir
                            ? const Color(0xFF059669)
                            : primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        jbtn,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: fontNormal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Attendance Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHadir
                        ? const Color(0xFFE6FBF2)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isHadir
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHadir
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            size: 13,
                            color: isHadir
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isHadir ? "Hadir" : "Belum Hadir",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isHadir
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      if (isHadir && jamHadir.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          jamHadir,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 120,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 70,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
