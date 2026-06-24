import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_list.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class Sertifikasi extends StatefulWidget {
  const Sertifikasi({super.key});

  @override
  State<Sertifikasi> createState() => _SertifikasiState();
}

class _SertifikasiState extends State<Sertifikasi> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final box = GetStorage();
  bool isLoading = true;
  List dataSertifikasi = [];

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedYear = "Semua";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    var sub = box.read('sub');

    var resUser = await Api().getData("/pegawai/$sub");
    if (resUser.statusCode == 200) {
      var bodyUser = json.decode(resUser.body);
      String nik = bodyUser['data']['nik'];

      var res = await Api().getData("/diklat/pegawai/$nik");

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (mounted) {
          setState(() {
            dataSertifikasi = body['data'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            dataSertifikasi = [];
            isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      Msg.error(context, "Gagal memuat data pengguna");
    }
    _refreshController.refreshCompleted();
  }

  // Get dynamic list of years present in the certificates
  List<String> get yearsList {
    Set<String> years = {'Semua'};
    for (var item in dataSertifikasi) {
      var tgl = item['kegiatan']?['tgl_mulai'];
      if (tgl != null && tgl.toString().length >= 4) {
        String yr = tgl.toString().substring(0, 4);
        years.add(yr);
      }
    }
    var sorted = years.toList();
    // Sort descending with 'Semua' at index 0
    sorted.sort((a, b) {
      if (a == 'Semua') return -1;
      if (b == 'Semua') return 1;
      return b.compareTo(a);
    });
    return sorted;
  }

  // Get filtered data based on search query and selected year
  List get filteredData {
    if (_searchQuery.isEmpty && _selectedYear == "Semua") {
      return dataSertifikasi;
    }
    return dataSertifikasi.where((item) {
      var kegiatan = item['kegiatan'] ?? {};
      String nama = (kegiatan['nama_kegiatan'] ?? '').toString().toLowerCase();
      String nomor = (kegiatan['nomor'] ?? '').toString().toLowerCase();
      String tempat = (kegiatan['tempat'] ?? '').toString().toLowerCase();
      String penyelenggara = (kegiatan['penyelenggara'] ?? '').toString().toLowerCase();
      String tglMulai = (kegiatan['tgl_mulai'] ?? '').toString();

      bool matchesSearch = _searchQuery.isEmpty ||
          nama.contains(_searchQuery.toLowerCase()) ||
          nomor.contains(_searchQuery.toLowerCase()) ||
          tempat.contains(_searchQuery.toLowerCase()) ||
          penyelenggara.contains(_searchQuery.toLowerCase());

      bool matchesYear = true;
      if (_selectedYear != "Semua") {
        matchesYear = tglMulai.startsWith(_selectedYear);
      }

      return matchesSearch && matchesYear;
    }).toList();
  }

  String _detectBadge(String title) {
    final t = title.toLowerCase();
    if (t.contains('webinar')) return 'Webinar';
    if (t.contains('workshop')) return 'Workshop';
    if (t.contains('pelatihan') || t.contains('training')) return 'Pelatihan';
    if (t.contains('seminar')) return 'Seminar';
    if (t.contains('sosialisasi')) return 'Sosialisasi';
    if (t.contains('bimtek')) return 'Bimtek';
    if (t.contains('baitul arqom') || t.contains('arqom')) return 'Keagamaan';
    return 'Diklat';
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'Webinar': return Colors.purple;
      case 'Workshop': return Colors.teal;
      case 'Pelatihan': return Colors.blue;
      case 'Seminar': return Colors.orange;
      case 'Sosialisasi': return Colors.green;
      case 'Bimtek': return Colors.indigo;
      case 'Keagamaan': return Colors.brown;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = filteredData;
    final years = yearsList;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Header Background with subtle gradient
          Container(
            height: 290,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.85),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(32),
                bottomLeft: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          "Sertifikasi & Diklat",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search, Stats and Filters Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Cari nama, nomor, tempat, dll...",
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: primaryColor),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = "";
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Year Chips
                      if (dataSertifikasi.isNotEmpty)
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: years.length,
                            itemBuilder: (context, index) {
                              final yr = years[index];
                              final isSelected = _selectedYear == yr;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedYear = yr;
                                    });
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      yr,
                                      style: TextStyle(
                                        color: isSelected ? primaryColor : Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Results Info / Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Ditemukan: ${listToShow.length} Sertifikat",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _selectedYear != 'Semua')
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = "";
                                  _selectedYear = "Semua";
                                });
                              },
                              child: const Text(
                                "Reset Filter",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // List of Certificates
                Expanded(
                  child: isLoading
                      ? const SkeletonList(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          cardHeight: 120,
                        )
                      : SmartRefresher(
                          controller: _refreshController,
                          onRefresh: _fetchData,
                          child: listToShow.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  itemCount: listToShow.length,
                                  itemBuilder: (context, index) {
                                    return _buildSertifikatCard(listToShow[index]);
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCertificate(String filename) async {
    String baseUrl = '$apiUrl/diklat/download/';
    String url = "$baseUrl$filename";
    var token = box.read('token');

    try {
      String? dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectory())?.path;
      } else {
        dir = (await getApplicationDocumentsDirectory()).path;
      }

      if (dir == null) throw "Directory not found";

      String localPath = "$dir/$filename";
      File file = File(localPath);

      if (await file.exists()) {
        await OpenFilex.open(localPath);
      } else {
        print("DEBUG: Downloading from $url");
        Msg.info(context, "Sedang mengunduh sertifikat...");

        await Dio().download(url, localPath,
            options: Options(headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
            }));

        print("DEBUG: Download Success to $localPath");
        Msg.success(context, "Download selesai");
        await OpenFilex.open(localPath);
      }
    } catch (e) {
      print("DEBUG: Error opening/downloading file: $e");
      Msg.error(context, "Gagal membuka file: $e");
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_membership_rounded, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada data sertifikasi",
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Coba ubah kata kunci pencarian atau filter tahun",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSertifikatCard(Map data) {
    var kegiatan = data['kegiatan'] ?? {};
    String namaKegiatan =
        kegiatan['nama_kegiatan'] ?? 'Nama Kegiatan Tidak Tersedia';
    String tempat = kegiatan['tempat'] ?? '-';
    String tglMulai = kegiatan['tgl_mulai'] ?? '-';
    String? tglAkhir = kegiatan['tgl_akhir'];
    String nomor = kegiatan['nomor'] ?? '-';

    // Format Date range
    String periode = tglMulai;
    if (tglMulai != '-') {
      try {
        DateTime start = DateTime.parse(tglMulai);
        String fStart = DateFormat('d MMM yyyy').format(start);
        if (tglAkhir != null && tglAkhir != tglMulai) {
          DateTime end = DateTime.parse(tglAkhir);
          String fEnd = DateFormat('d MMM yyyy').format(end);
          periode = "$fStart - $fEnd";
        } else {
          periode = fStart;
        }
      } catch (_) {}
    }

    String badge = _detectBadge(namaKegiatan);
    Color badgeColor = _getBadgeColor(badge);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section: Icon + Title + Category Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gold / Amber certificate badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200.withOpacity(0.5), width: 1.5),
                  ),
                  child: Icon(Icons.workspace_premium_rounded,
                      color: Colors.amber.shade700, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              namaKegiatan,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dynamic category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nomor,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey[100], height: 16, thickness: 1),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                _buildDetailRow(
                    Icons.calendar_today_rounded, "Tanggal", periode),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.place_rounded, "Tempat", tempat),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.verified_rounded, "Penyelenggara",
                    kegiatan['penyelenggara'] ?? '-'),
              ],
            ),
          ),

          // Action Button (if file exists)
          if (data['berkas'] != null && data['berkas'] != '') ...[
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.04),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border.fromBorderSide(
                  BorderSide(color: primaryColor.withOpacity(0.05), width: 1)
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _openCertificate(data['berkas']);
                  },
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          "Lihat & Unduh Sertifikat",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 11, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: Colors.blueGrey.shade300),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        )
      ],
    );
  }
}
