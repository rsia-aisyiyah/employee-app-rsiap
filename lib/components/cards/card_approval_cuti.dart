import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/helper.dart';

class CardApprovalCuti extends StatelessWidget {
  final Map data;
  final Function onApprove;
  final Function onReject;
  final bool isPending;

  const CardApprovalCuti({
    super.key,
    required this.data,
    required this.onApprove,
    required this.onReject,
    this.isPending = true,
  });

  @override
  Widget build(BuildContext context) {
    String status = (data['status'] ?? data['status_cuti']).toString();
    Color statusColor = Colors.blue;
    String statusText = "Menunggu";

    if (status == "2") {
      statusColor = Colors.green;
      statusText = "Disetujui";
    } else if (status == "3") {
      statusColor = Colors.red;
      statusText = "Ditolak";
    } else if (status == "1") {
      statusColor = Colors.grey;
      statusText = "Dibatalkan";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Employee Info
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['nama'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      data['nik'] ?? '-',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Leave Details
          _buildInfoRow(
              Icons.category_outlined, "Jenis Cuti", data['jenis'] ?? '-'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today_outlined, "Tanggal",
              Helper.formatDate(data['tanggal_cuti'])),
          if (data['alasan'] != null &&
              data['alasan'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.notes_outlined, "Alasan", data['alasan']),
          ],

          // Action Buttons
          if (isPending && status == "0") ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReject(),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Tolak"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onApprove(),
                    icon:
                        const Icon(Icons.check, size: 18, color: Colors.white),
                    label: const Text("Setujui",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(
          "$label : ",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
