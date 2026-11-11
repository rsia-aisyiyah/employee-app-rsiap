import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:intl/intl.dart';

class SuratInternalDetailScreen extends StatefulWidget {
  final Map dataSurat;

  const SuratInternalDetailScreen({
    super.key,
    required this.dataSurat,
  });

  @override
  State<SuratInternalDetailScreen> createState() =>
      _SuratInternalDetailScreenState();
}

class _SuratInternalDetailScreenState extends State<SuratInternalDetailScreen> {
  bool isRecipientsLoading = false;
  List recipients = [];
  late Map currentDataSurat;
  bool isProcessingApproval = false;
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    currentDataSurat = Map.from(widget.dataSurat);
    // If it's an invitation, fetch recipients
    if (currentDataSurat['undangan'] != null) {
      _fetchRecipients(currentDataSurat['undangan']['id']);
    }
  }

  bool get isCurrentUserPJ {
    final myNik = box.read('sub')?.toString();
    final pjNik = (currentDataSurat['pj'] ?? currentDataSurat['penanggung_jawab']?['nik'])?.toString();
    return myNik != null && pjNik != null && myNik == pjNik;
  }

  bool get canApproveAsPJ {
    final status = (currentDataSurat['status'] ?? 'pengajuan').toString().toLowerCase();
    final isApproved = currentDataSurat['pj_approved_at'] != null;
    return isCurrentUserPJ && status == 'pengajuan' && !isApproved;
  }

  Future<void> _fetchRecipients(dynamic undanganId) async {
    setState(() {
      isRecipientsLoading = true;
    });

    try {
      var res = await Api().getData('/undangan/penerima/$undanganId');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        setState(() {
          recipients = body['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching recipients: $e");
    } finally {
      if (mounted) {
        setState(() {
          isRecipientsLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dateOnly = dateStr.split('T')[0].split(' ')[0];
      final date = DateTime.parse(dateOnly);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      // Handle the 'T' separator if it exists
      final normalizedDate = dateStr.replaceFirst(' ', 'T');
      final date = DateTime.parse(normalizedDate);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'pengajuan':
      default:
        return Colors.orange;
    }
  }

  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 25,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Detail Surat",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Informasi Lengkap Surat Internal",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isStatus = false, bool isMuted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(value).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _getStatusColor(value).withOpacity(0.3)),
              ),
              child: Text(
                value[0].toUpperCase() + value.substring(1).toLowerCase(),
                style: TextStyle(
                  color: _getStatusColor(value),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 14,
                color: isMuted ? Colors.grey[600] : Colors.black87,
                fontWeight: isMuted ? FontWeight.normal : FontWeight.w500,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPjStatusBadge() {
    final isApproved = currentDataSurat['pj_approved_at'] != null;
    final isRejected = (currentDataSurat['status'] ?? '').toString().toLowerCase() == 'ditolak';

    if (isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 13, color: Color(0xFF047857)),
            SizedBox(width: 4),
            Text(
              "Disetujui PJ",
              style: TextStyle(
                color: Color(0xFF047857),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 13, color: Color(0xFFB91C1C)),
            SizedBox(width: 4),
            Text(
              "Ditolak",
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 13, color: Color(0xFFB45309)),
            SizedBox(width: 4),
            Text(
              "Menunggu PJ",
              style: TextStyle(
                color: Color(0xFFB45309),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handlePjApproval(String action, {String? catatan}) async {
    setState(() => isProcessingApproval = true);
    try {
      final suratId = currentDataSurat['id'];
      final res = await Api().postData({
        'action': action,
        'catatan': catatan,
      }, '/surat/internal/$suratId/approval-pj');

      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          Msg.success(context, body['message'] ?? 'Berhasil memproses persetujuan');
          setState(() {
            if (action == 'setujui') {
              currentDataSurat['pj_approved_at'] = DateTime.now().toIso8601String();
              currentDataSurat['pj_approved_by'] = box.read('sub');
            } else {
              currentDataSurat['status'] = 'ditolak';
              currentDataSurat['catatan_penolakan'] = catatan;
            }
          });
        }
      } else {
        if (mounted) {
          Msg.error(context, body['message'] ?? 'Gagal memproses persetujuan');
        }
      }
    } catch (e) {
      if (mounted) {
        Msg.error(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) setState(() => isProcessingApproval = false);
    }
  }

  void _showRejectDialog() {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text("Tolak Pengajuan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tuliskan catatan atau alasan penolakan surat/undangan ini:",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Contoh: Jadwal bentrok, atau belum ada konfirmasi unit...",
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handlePjApproval('tolak', catatan: noteCtrl.text.trim());
            },
            child: const Text("Tolak Surat", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalActionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.verified_user_outlined, color: Colors.blue.shade700, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Persetujuan Penanggung Jawab",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                    Text(
                      "Anda ditunjuk sebagai PJ. Silakan tinjau dan berikan persetujuan.",
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: isProcessingApproval ? null : _showRejectDialog,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("Tolak", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                  onPressed: isProcessingApproval
                      ? null
                      : () => _handlePjApproval('setujui'),
                  icon: isProcessingApproval
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                    isProcessingApproval ? "Menyimpan..." : "Setujui Kegiatan",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientList() {
    if (isRecipientsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (recipients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                "Tidak ada penerima terdaftar",
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recipients.map((rec) {
        String name = rec['detail']?['nama'] ??
            rec['pegawai']?['nama'] ??
            rec['penerima'] ??
            'Unknown';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 14, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = currentDataSurat;
    final bool hasUndangan = d['undangan'] != null;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Approval Card (If logged-in user is PJ and pending)
                  if (canApproveAsPJ) _buildApprovalActionCard(),

                  // Main Detail Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:
                                  Icon(Icons.receipt_long, color: primaryColor),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Identitas Surat",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    d['no_surat'] ?? '(Draft / Belum Terbit)',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Divider(height: 1),
                        ),
                        _buildInfoRow("Perihal", d['perihal'] ?? '-'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow("Tanggal Terbit",
                                  _formatDate(d['tgl_terbit'])),
                            ),
                            Expanded(
                              child: _buildInfoRow(
                                  "Status Surat", d['status'] ?? 'Draft',
                                  isStatus: true),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                  "Penanggung Jawab",
                                  d['penanggung_jawab']?['nama'] ??
                                      d['penanggungJawab']?['nama'] ??
                                      d['pj'] ??
                                      '-'),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PERSETUJUAN PJ",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[500],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildPjStatusBadge(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (d['catatan'] != null &&
                            d['catatan'].toString().isNotEmpty)
                          _buildInfoRow("Catatan Khusus", d['catatan'],
                              isMuted: true),
                        if (d['catatan_penolakan'] != null &&
                            d['catatan_penolakan'].toString().isNotEmpty)
                          _buildInfoRow("Alasan Penolakan", d['catatan_penolakan'],
                              isMuted: false),
                      ],
                    ),
                  ),

                  // Meeting Info Card (If exists)
                  if (hasUndangan) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.event,
                                    color: Colors.amber.shade800),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Informasi Pertemuan",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    Text(
                                      "Agenda & Undangan Rapat",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoRow("Waktu Acara",
                                    _formatDateTime(d['undangan']['tanggal'])),
                              ),
                              Expanded(
                                child: _buildInfoRow("Lokasi Acara",
                                    d['undangan']['lokasi'] ?? '-'),
                              ),
                            ],
                          ),
                          if (d['undangan']['deskripsi'] != null &&
                              d['undangan']['deskripsi'].toString().isNotEmpty)
                            _buildInfoRow("Agenda", d['undangan']['deskripsi'],
                                isMuted: true),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          Text(
                            "DAFTAR PENERIMA UNDANGAN",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRecipientList(),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
