import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
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

  @override
  void initState() {
    super.initState();
    // If it's an invitation, fetch recipients
    if (widget.dataSurat['undangan'] != null) {
      _fetchRecipients(widget.dataSurat['undangan']['id']);
    }
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
    final d = widget.dataSurat;
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
                        _buildInfoRow(
                            "Penanggung Jawab",
                            d['penanggung_jawab']?['nama'] ??
                                d['penanggungJawab']?['nama'] ??
                                d['pj'] ??
                                '-'),
                        if (d['catatan'] != null &&
                            d['catatan'].toString().isNotEmpty)
                          _buildInfoRow("Catatan Khusus", d['catatan'],
                              isMuted: true),
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
