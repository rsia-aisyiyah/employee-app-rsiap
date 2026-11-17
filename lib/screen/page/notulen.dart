import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/helper.dart';

class NotulenPage extends StatefulWidget {
  final Map dataUdgn;

  const NotulenPage({super.key, required this.dataUdgn});

  @override
  State<NotulenPage> createState() => _NotulenPageState();
}

class _NotulenPageState extends State<NotulenPage> {
  Future? _notulenFuture;

  @override
  void initState() {
    super.initState();
    _notulenFuture = fetchNotulen();
  }

  Future fetchNotulen() async {
    final rawId = widget.dataUdgn['id'] ??
        widget.dataUdgn['undangan_id'] ??
        widget.dataUdgn['surat_id'] ??
        widget.dataUdgn['no_surat'];

    final String url =
        "/undangan/${base64Url.encode(utf8.encode(rawId.toString()))}/notulen";

    try {
      var res = await Api().getData(url);

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        return body;
      } else {
        throw Exception('Gagal memuat notulen: ${res.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Notulen Rapat",
          style: TextStyle(
            color: textWhite,
            fontSize: 18,
            fontWeight: fontSemiBold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      body: FutureBuilder(
        future: _notulenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.hasData) {
            final data = snapshot.data['data'] as Map<String, dynamic>?;

            if (data == null || data.isEmpty) {
              return _buildEmptyState();
            }

            // ── Safe Data Extraction ──
            final perihal = (data['perihal'] ??
                    data['surat']?['perihal'] ??
                    widget.dataUdgn['perihal'] ??
                    widget.dataUdgn['surat']?['perihal'] ??
                    '-')
                .toString();

            // Format Tanggal
            final rawDate = data['tanggal'] ??
                data['tgl_terbit'] ??
                widget.dataUdgn['tanggal'] ??
                widget.dataUdgn['tgl_terbit'];
            String tanggalDisplay = '-';
            if (rawDate != null && rawDate.toString().isNotEmpty) {
              try {
                tanggalDisplay = Helper.formatDate(rawDate.toString());
              } catch (_) {
                tanggalDisplay = rawDate.toString();
              }
            }

            // Format Lokasi
            final lokasiDisplay = (data['lokasi'] ??
                    data['tempat'] ??
                    widget.dataUdgn['tempat'] ??
                    widget.dataUdgn['lokasi'] ??
                    '-')
                .toString();

            // Pemimpin Rapat
            String pemimpinRapat = '-';
            final pjObj = data['penanggung_jawab'] ??
                data['pj_detail'] ??
                widget.dataUdgn['penanggung_jawab'];
            if (pjObj is Map && pjObj['nama'] != null) {
              pemimpinRapat = pjObj['nama'].toString();
            } else if (data['pj'] != null) {
              pemimpinRapat = data['pj'].toString();
            }

            // Notulis
            String notulis = '-';
            final notulenObj = data['notulen'];
            if (notulenObj is Map) {
              if (notulenObj['notulis'] is Map &&
                  notulenObj['notulis']['nama'] != null) {
                notulis = notulenObj['notulis']['nama'].toString();
              } else if (notulenObj['nama'] != null) {
                notulis = notulenObj['nama'].toString();
              } else if (notulenObj['notulis_nik'] != null) {
                notulis = notulenObj['notulis_nik'].toString();
              }
            }

            // Pembahasan
            String? pembahasan;
            if (notulenObj is Map &&
                notulenObj['pembahasan'] != null &&
                notulenObj['pembahasan'].toString().trim().isNotEmpty) {
              pembahasan = notulenObj['pembahasan'].toString();
            }

            // Waktu dibuat
            String? dibuatDisplay;
            if (notulenObj is Map && notulenObj['created_at'] != null) {
              try {
                dibuatDisplay =
                    Helper.formatDate(notulenObj['created_at'].toString());
              } catch (_) {
                dibuatDisplay = notulenObj['created_at'].toString();
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // ── Metadata Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.description_rounded,
                                  color: primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "NOTULEN RAPAT",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          perihal,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: fontSemiBold,
                            color: textColor,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 15, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tanggalDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lokasiDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Content Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPersonRow("Pemimpin Rapat", pemimpinRapat),
                        const SizedBox(height: 14),
                        _buildPersonRow("Notulis", notulis),
                        const SizedBox(height: 22),
                        const Text(
                          "Pembahasan",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (pembahasan != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0), width: 1),
                            ),
                            child: HtmlWidget(
                              pembahasan,
                              textStyle: const TextStyle(
                                height: 1.6,
                                fontSize: 13.5,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (dibuatDisplay != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              "Dibuat: $dibuatDisplay",
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0), width: 1),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.edit_note_rounded,
                                    size: 42, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text(
                                  "Belum ada pembahasan notulen",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Hasil rapat belum ditambahkan oleh notulis.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildShimmerLoading();
        },
      ),
    );
  }

  Widget _buildPersonRow(String label, String? name) {
    final displayName = (name != null && name.trim().isNotEmpty) ? name : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: fontSemiBold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              "Data Notulen Tidak Ditemukan",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Notulen belum tersedia untuk rapat ini.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            const Text(
              "Gagal Memuat Notulen",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Terjadi kendala saat mengambil data notulen rapat.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _notulenFuture = fetchNotulen();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ── Shimmer Skeleton Loading Elegan (Pengganti Loading Lottie Kotak) ──
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Column(
          children: [
            // Skeleton Metadata Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 110,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 220,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 160,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 200,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Skeleton Content Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 90,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 180,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 70,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 160,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
