import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart'; // Ensure intl is added to pubspec.yaml
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Assuming 'sub' stores the NIK or ID needed. API expects NIK in URL.
    // If 'sub' is ID, we might need NIK. Let's assume 'sub' is sufficient or we get NIK from profile first.
    // For now, let's try using the stored 'username' or fetch profile to get NIK if needed.
    // Assuming box.read('sub') gives the ID/NIK used in consistent manner. (Checking profile.dart: /pegawai/{sub} works, so let's try that first or assume we have 'nik' stored).
    // Actually profile.dart reads 'sub' (ID) then fetches profile to get 'nik'.
    // To be safe, we should fetch profile or if NIK is stored.
    // Let's assume we can use the same endpoint pattern as others or fetch profile first if needed.
    // WAIT: API route is /diklat/pegawai/{nik}. 'sub' is usually the ID (e.g. 123).
    // Let's check if we have NIK. If not, we might need to fetch profile first.
    // Quick fix: Fetch profile simplified or check if we can store NIK.
    // For now, I'll fetch the profile briefly to get NIK if I can't find it.
    // BUT, let's try to fetch user details first to be safe.

    // fetching user details to get NIK
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
            dataSertifikasi = body['data'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Header Background
          Container(
            height: MediaQuery.of(context).size.height *
                0.35, // Adjust height as needed
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                      ),
                      const Text(
                        "Sertifikasi & Diklat",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const SkeletonList(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          cardHeight: 120)
                      : SmartRefresher(
                          controller: _refreshController,
                          onRefresh: _fetchData,
                          child: dataSertifikasi.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  itemCount: dataSertifikasi.length,
                                  itemBuilder: (context, index) {
                                    return _buildSertifikatCard(
                                        dataSertifikasi[index]);
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
    // New Proxy Endpoint
    String baseUrl = '$apiUrl/diklat/download/';
    String url = "$baseUrl$filename";

    // Get Token
    var token = box.read('token');

    try {
      // Check Permissions
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      // Get Directory
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
          Icon(Icons.card_membership, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada data sertifikasi",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section: Icon + Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.workspace_premium,
                      color: primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaKegiatan,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nomor,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic),
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
            child: Divider(color: Colors.grey[200], height: 20),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildDetailRow(
                    Icons.calendar_today_outlined, "Tanggal", periode),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.place_outlined, "Tempat", tempat),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.verified_user_outlined, "Penyelenggara",
                    kegiatan['penyelenggara'] ?? '-'),
              ],
            ),
          ),

          // Action Button (if file exists)
          if (data['berkas'] != null && data['berkas'] != '') ...[
            Container(
              decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(15))),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _openCertificate(data['berkas']);
                  },
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          "Lihat Sertifikat",
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
          ] else ...[
            const SizedBox(height: 6),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 8),
        SizedBox(
          width: 70, // Fixed width for labels alignment
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }
}
