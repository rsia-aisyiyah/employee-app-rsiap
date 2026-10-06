import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/kebugaran_saya.dart';
import 'package:rsia_employee_app/services/health_service.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class CardHealthWidget extends StatefulWidget {
  final bool embedded;
  const CardHealthWidget({super.key, this.embedded = false});

  @override
  State<CardHealthWidget> createState() => _CardHealthWidgetState();
}

class _CardHealthWidgetState extends State<CardHealthWidget> {
  final box = GetStorage();
  bool isLoading = true;
  bool isSyncing = false;
  Map todayData = {};

  @override
  void initState() {
    super.initState();
    _fetchTodaySummary();
  }

  Future<void> _fetchTodaySummary() async {
    final nik = box.read('sub');
    if (nik == null) return;

    try {
      var res = await Api().getData('/sdi/health/summary?nik=$nik');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (body['success'] == true && body['message'] != null) {
          if (mounted) {
            setState(() {
              todayData = body['message']['today'] ?? {};
              isLoading = false;
            });
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _triggerQuickSync() async {
    setState(() {
      isSyncing = true;
    });

    final nik = box.read('sub');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Fetch real metrics from Apple Health / Google Health Connect
    Map<String, dynamic> realHealth = await HealthService.fetchTodayHealthData();
    realHealth['tanggal'] = today;

    final syncPayload = {
      'nik': nik,
      'platform': Theme.of(context).platform == TargetPlatform.iOS ? 'iOS' : 'Android',
      'device_name': realHealth['sumber_device'] ?? 'Smartwatch',
      'logs': [realHealth]
    };

    try {
      var res = await Api().postData(syncPayload, '/sdi/health/sync');
      if (res.statusCode == 200) {
        Msg.success(context, "Berhasil sync Smartwatch!");
        await _fetchTodaySummary();
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
        });
      }
    }
  }

  int _parseNum(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? 0);
    return 0;
  }

  Widget _buildContent(
    BuildContext context,
    bool hasData,
    int steps,
    double progress,
    int hr,
    int sleepMin,
    double sleepHours,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.watch_rounded, color: primaryColor, size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Wellness",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.black87),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.grey[400]),
              ],
            ),
            GestureDetector(
              onTap: isSyncing ? null : _triggerQuickSync,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isSyncing
                    ? SizedBox(width: 10, height: 10, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 1.5))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync_rounded, size: 11, color: primaryColor),
                          const SizedBox(width: 3),
                          Text(
                            "Sync",
                            style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("👟 Langkah", style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                      Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasData ? "${NumberFormat.decimalPattern('id').format(steps)} step" : "0 step",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 10), color: Colors.grey[200]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("❤️ Detak Jtg", style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                  const SizedBox(height: 3),
                  Text(
                    hasData ? "$hr BPM" : "- BPM",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasData ? "Resting: Normal" : "Belum sync",
                    style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 10), color: Colors.grey[200]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("😴 Tidur", style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                  const SizedBox(height: 3),
                  Text(
                    hasData ? "$sleepHours Jam" : "- Jam",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: !hasData ? Colors.grey : (sleepMin < 300 ? Colors.orange : Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    !hasData ? "Belum sync" : (sleepMin < 300 ? "⚠️ Kurang" : "Cukup"),
                    style: TextStyle(
                      fontSize: 8.5,
                      color: !hasData ? Colors.grey : (sleepMin < 300 ? Colors.orange : Colors.green),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlimRow(
    BuildContext context,
    bool hasData,
    int steps,
    int hr,
    int sleepMin,
    double sleepHours,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Watch icon + Kebugaran + Sync icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.watch_rounded, color: primaryColor, size: 12),
            ),
            const SizedBox(width: 5),
            const Text(
              "Wellness",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: isSyncing ? null : _triggerQuickSync,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: isSyncing
                    ? SizedBox(
                        width: 9,
                        height: 9,
                        child: CircularProgressIndicator(
                          color: primaryColor,
                          strokeWidth: 1.5,
                        ),
                      )
                    : Icon(Icons.sync_rounded, size: 11, color: primaryColor),
              ),
            ),
          ],
        ),

        // Right: 👟 0 lgk | ❤️ - bpm | 😴 - j >
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Langkah
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("👟", style: TextStyle(fontSize: 10)),
                const SizedBox(width: 2),
                Text(
                  hasData ? NumberFormat.compact().format(steps) : "0",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: Colors.black87,
                  ),
                ),
                const Text(" step", style: TextStyle(fontSize: 8.5, color: Colors.grey)),
              ],
            ),
            Container(
              width: 1,
              height: 11,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              color: Colors.grey[200],
            ),
            // BPM
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("❤️", style: TextStyle(fontSize: 10)),
                const SizedBox(width: 2),
                Text(
                  hasData ? "$hr" : "-",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: Color(0xFFE11D48),
                  ),
                ),
                const Text(" bpm", style: TextStyle(fontSize: 8.5, color: Colors.grey)),
              ],
            ),
            Container(
              width: 1,
              height: 11,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              color: Colors.grey[200],
            ),
            // Tidur
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("😴", style: TextStyle(fontSize: 10)),
                const SizedBox(width: 2),
                Text(
                  hasData ? "$sleepHours" : "-",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: !hasData ? Colors.grey : (sleepMin < 300 ? Colors.orange : Colors.indigo),
                  ),
                ),
                const Text(" j", style: TextStyle(fontSize: 8.5, color: Colors.grey)),
              ],
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 13, color: Colors.grey[400]),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasData = todayData.isNotEmpty && todayData['jumlah_langkah'] != null;
    int steps = _parseNum(todayData['jumlah_langkah']);
    double progress = (steps / 10000).clamp(0.0, 1.0);
    int hr = _parseNum(todayData['detak_jantung_avg']);
    int sleepMin = _parseNum(todayData['durasi_tidur_menit']);
    double sleepHours = double.parse((sleepMin / 60).toStringAsFixed(1));

    if (widget.embedded) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KebugaranSayaScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: _buildSlimRow(context, hasData, steps, hr, sleepMin, sleepHours),
      );
    }

    final content = _buildContent(context, hasData, steps, progress, hr, sleepMin, sleepHours);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KebugaranSayaScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: primaryColor.withOpacity(0.12)),
        ),
        child: content,
      ),
    );
  }
}
