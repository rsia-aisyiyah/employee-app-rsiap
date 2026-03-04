import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:intl/intl.dart';

class CardSuratInternal extends StatelessWidget {
  final Map dataSurat;
  final VoidCallback onTap;

  const CardSuratInternal({
    super.key,
    required this.dataSurat,
    required this.onTap,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      // Split by 'T' to get just the date part, and ignore timezone if present
      final dateOnly = dateStr.split('T')[0].split(' ')[0];
      final date = DateTime.parse(dateOnly);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
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

  String _getStatusText(String? status) {
    if (status == null || status.isEmpty) return 'Draft';
    // Capitalize first letter
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(dataSurat['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: primaryColor.withOpacity(0.1),
          highlightColor: primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: No Surat & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.text_snippet_rounded,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dataSurat['no_surat'] ?? '(Belum Terbit)',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _getStatusText(dataSurat['status']),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title (Perihal)
                Text(
                  dataSurat['perihal'] ?? 'Tanpa Perihal',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Footer: Date & PJ
                Row(
                  children: [
                    // Date
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(dataSurat['tgl_terbit']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      height: 12,
                      width: 1,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),

                    // PJ
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dataSurat['penanggung_jawab']?['nama'] ??
                                  dataSurat['penanggungJawab']?['nama'] ??
                                  '-',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
