import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class CardCuti extends StatefulWidget {
  final Map dataCuti;
  final Function onDelete;

  const CardCuti({
    super.key,
    required this.dataCuti,
    required this.onDelete,
  });

  @override
  State<CardCuti> createState() => _CardCutiState();
}

class _CardCutiState extends State<CardCuti> {
  @override
  Widget build(BuildContext context) {
    String status = widget.dataCuti['status_cuti'].toString();
    Color statusColor = Colors.blue;
    String statusText = "Pengajuan";

    if (status == "2") {
      statusColor = Colors.green;
      statusText = "Disetujui";
    } else if (status == "1") {
      statusColor = Colors.red;
      statusText = "Ditolak";
    } else {
      statusColor = Colors.blue;
      statusText = "Pengajuan";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  Helper.dayToNum(widget.dataCuti['tanggal_cuti'].toString()),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Helper.daytoMonth(widget.dataCuti['tanggal_cuti'].toString()),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  Helper.daytoYear(widget.dataCuti['tanggal_cuti'].toString()),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.dataCuti['jenis'].toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  Helper.formatDate(widget.dataCuti['tanggal_cuti']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
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
              ],
            ),
          ),

          // Delete Action (Only for Pending)
          if (status == "0")
            IconButton(
              onPressed: () async {
                bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Hapus Pengajuan"),
                        content:
                            const Text("Yakin ingin menghapus pengajuan ini?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Hapus",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (confirm) {
                  widget.onDelete();
                }
              },
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.withOpacity(0.7)),
            ),
        ],
      ),
    );
  }
}

Widget textDisetujui() {
  return const Row(
    children: [
      Text(
        "Disetujui",
        style: TextStyle(
          fontSize: 16,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(width: 10),
      Icon(
        Icons.check_circle_rounded,
        color: Colors.green,
        size: 28,
      )
    ],
  );
}

Widget textPengajuan() {
  return const Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        "Pengajuan",
        style: TextStyle(
          fontSize: 16,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(width: 10),
      Icon(
        Icons.send_rounded,
        color: Colors.blue,
        size: 20,
      )
    ],
  );
}

Widget textDitolak() {
  return const Row(
    children: [
      Text(
        "Ditolak",
        style: TextStyle(
          fontSize: 16,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(width: 10),
      Icon(
        Icons.dangerous,
        color: Colors.red,
        size: 28,
      )
    ],
  );
}
