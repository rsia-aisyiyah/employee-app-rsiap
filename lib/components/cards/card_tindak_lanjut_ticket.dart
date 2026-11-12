import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/models/tindak_lanjut_model.dart';
import 'package:rsia_employee_app/screen/menu/tindak_lanjut/tindak_lanjut_detail_screen.dart';
import 'package:rsia_employee_app/screen/menu/tindak_lanjut/tindak_lanjut_screen.dart';

/// A sleek, space-efficient Card Strip for Assigned Tindak Lanjut Rapat on Home Screen.
class CardTindakLanjutTicket extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback? onRefresh;

  const CardTindakLanjutTicket({
    super.key,
    required this.items,
    this.onRefresh,
  });

  @override
  State<CardTindakLanjutTicket> createState() => _CardTindakLanjutTicketState();
}

class _CardTindakLanjutTicketState extends State<CardTindakLanjutTicket> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final total = widget.items.length;
    if (_currentIndex >= total) {
      _currentIndex = 0;
    }

    final rawItem = widget.items[_currentIndex];
    final item = TindakLanjutItem.fromJson(rawItem);
    final pct = item.progressPercent.clamp(0, 100);

    final deadline = item.deadlineDate;
    final isOverdue = item.isOverdue;

    Color progressColor = primaryColor;
    if (pct == 100 || item.status == 'selesai') {
      progressColor = const Color(0xFF10B981);
    } else if (isOverdue) {
      progressColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
        border: Border.all(
          color: isOverdue ? Colors.red.withOpacity(0.4) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
            if (widget.onRefresh != null) {
              widget.onRefresh!();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in, size: 12, color: progressColor),
                          const SizedBox(width: 4),
                          Text(
                            'TINDAK LANJUT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: progressColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Text(
                          'OVERDUE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                          ),
                        ),
                      )
                    else if (deadline != null)
                      Text(
                        _getCountdownLabel(deadline),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const Spacer(),

                    // If multiple items, show navigation buttons
                    if (total > 1) ...[
                      InkWell(
                        onTap: () {
                          setState(() {
                            _currentIndex = (_currentIndex - 1 + total) % total;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.chevron_left, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1}/$total',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _currentIndex = (_currentIndex + 1) % total;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.chevron_right, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // View all menu button
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TindakLanjutScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Semua',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Perihal Rapat & Tugas
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.perihalRapat,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.deskripsi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Percentage number
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Mini Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCountdownLabel(DateTime event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(event.year, event.month, event.day);
    final diffDays = eventDay.difference(today).inDays;

    if (diffDays == 0) {
      return "TARGET HARI INI";
    } else if (diffDays == 1) {
      return "TARGET BESOK";
    } else if (diffDays > 1) {
      return "$diffDays HARI LAGI";
    } else {
      return "TERLAMBAT";
    }
  }
}
