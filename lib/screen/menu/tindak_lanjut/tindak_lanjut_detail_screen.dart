import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/models/tindak_lanjut_model.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class TindakLanjutDetailScreen extends StatefulWidget {
  final int id;
  final TindakLanjutItem? initialItem;

  const TindakLanjutDetailScreen({
    super.key,
    required this.id,
    this.initialItem,
  });

  @override
  State<TindakLanjutDetailScreen> createState() => _TindakLanjutDetailScreenState();
}

class _TindakLanjutDetailScreenState extends State<TindakLanjutDetailScreen> {
  TindakLanjutItem? _item;
  bool _isLoading = true;
  bool _isSubmitting = false;
  final box = GetStorage();

  // Reply / Progress input state
  final TextEditingController _pesanController = TextEditingController();
  int _selectedProgress = 0;
  String _selectedStatus = 'in_progress';
  String _selectedTipe = 'update_progress';
  File? _attachedFile;
  String? _attachedFileName;
  int? _attachedFileSize;

  // File download state
  final Map<int, bool> _downloadingMap = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _item = widget.initialItem;
      _selectedProgress = widget.initialItem!.progressPercent;
      _selectedStatus = widget.initialItem!.status;
    }
    _loadDetail();
  }

  @override
  void dispose() {
    _pesanController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await Api().getData('/undangan/tindak-lanjut/${widget.id}/detail');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['data'] != null) {
          final item = TindakLanjutItem.fromJson(Map<String, dynamic>.from(body['data']));
          if (mounted) {
            setState(() {
              _item = item;
              _selectedProgress = item.progressPercent;
              _selectedStatus = item.status;
              _isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Msg.error(context, 'Gagal memuat detail tindak lanjut: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'zip', 'rar'],
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final f = File(result.files.first.path!);
        setState(() {
          _attachedFile = f;
          _attachedFileName = result.files.first.name;
          _attachedFileSize = result.files.first.size;
        });
      }
    } catch (e) {
      if (mounted) Msg.error(context, 'Gagal memilih berkas: $e');
    }
  }

  void _clearAttachedFile() {
    setState(() {
      _attachedFile = null;
      _attachedFileName = null;
      _attachedFileSize = null;
    });
  }

  Future<void> _submitFeedback() async {
    final pesan = _pesanController.text.trim();
    if (pesan.isEmpty && _attachedFile == null) {
      Msg.warning(context, 'Tulis pesan, catatan, atau lampirkan berkas bukti');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final myNik = box.read('sub')?.toString();
      Map<String, String> fields = {
        'pesan': pesan.isNotEmpty ? pesan : 'Mengirimkan berkas lampiran',
        'tipe': _selectedTipe,
        'progress_percent': _selectedProgress.toString(),
        'status': _selectedStatus,
        if (myNik != null && myNik.isNotEmpty) 'nik': myNik,
      };

      final res = await Api().postMultipart(
        fields,
        _attachedFile,
        '/undangan/tindak-lanjut/${widget.id}/reply',
        fieldName: 'berkas',
      );

      setState(() => _isSubmitting = false);

      if (res.statusCode == 200) {
        _pesanController.clear();
        _clearAttachedFile();
        if (mounted) {
          Msg.success(context, 'Laporan / respon berhasil dikirim');
        }
        await _loadDetail();
      } else {
        var body = json.decode(res.body);
        String errorMessage = body['message'] ?? 'Gagal mengirim respon';
        if (body['errors'] is Map && (body['errors'] as Map).isNotEmpty) {
          final firstError = (body['errors'] as Map).values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          } else if (firstError is String) {
            errorMessage = firstError;
          }
        }
        if (mounted) {
          Msg.error(context, errorMessage);
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        Msg.error(context, 'Terjadi kesalahan: $e');
      }
    }
  }

  Future<void> _openOrDownloadFile(TindakLanjutFeedbackItem feedback) async {
    final feedbackId = feedback.id;
    final fileName = feedback.namaBerkas ?? 'lampiran_$feedbackId';

    setState(() {
      _downloadingMap[feedbackId] = true;
    });

    try {
      final dir = Platform.isAndroid
          ? (await getExternalStorageDirectory())?.path ?? (await getApplicationDocumentsDirectory()).path
          : (await getApplicationDocumentsDirectory()).path;

      final filePath = '$dir/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        setState(() {
          _downloadingMap[feedbackId] = false;
        });
        await OpenFilex.open(filePath);
        return;
      }

      // Download from API
      final token = await box.read('token');
      final downloadUrl = '$apiUrl/undangan/tindak-lanjut/berkas/$feedbackId';

      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      setState(() {
        _downloadingMap[feedbackId] = false;
      });

      await OpenFilex.open(filePath);
    } catch (e) {
      setState(() {
        _downloadingMap[feedbackId] = false;
      });
      if (mounted) {
        Msg.error(context, 'Gagal membuka berkas: $e');
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF10B981); // Emerald
      case 'in_progress':
        return primaryColor; // RSIA Cyan
      case 'dibatalkan':
        return Colors.redAccent;
      case 'pending':
      default:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tindak Lanjut Rapat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Segarkan',
            onPressed: _loadDetail,
          ),
        ],
      ),
      body: _isLoading && item == null
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : item == null
              ? _buildErrorView()
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadDetail,
                        color: primaryColor,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderCard(item),
                              const SizedBox(height: 16),
                              _buildProgressCard(item),
                              const SizedBox(height: 16),
                              _buildFeedbackSection(item),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildReplyBar(item),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Data tindak lanjut tidak ditemukan',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(TindakLanjutItem item) {
    final statusColor = _getStatusColor(item.status);
    final deadline = item.deadlineDate;
    final isOverdue = item.isOverdue;

    return Container(
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
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Surat Nomor & Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.suratNomor,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.perihalRapat,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatStatusLabel(item.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Deskripsi Tugas
          const Text(
            'TUGAS / TINDAK LANJUT:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.deskripsi,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Grid Info: PIC, Creator, Deadline
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_outlined, size: 16, color: Color(0xFF475569)),
                    const SizedBox(width: 8),
                    const Text('PIC Petugas:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        item.picNama,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.co_present_outlined, size: 16, color: Color(0xFF475569)),
                    const SizedBox(width: 8),
                    const Text('Pemberi Tugas:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        item.creatorNama,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 16,
                      color: isOverdue ? Colors.red : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Target Selesai:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      deadline != null ? DateFormat('dd MMM yyyy').format(deadline) : '-',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOverdue ? Colors.red : const Color(0xFF0F172A),
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Text(
                          'Overdue',
                          style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(TindakLanjutItem item) {
    final pct = item.progressPercent.clamp(0, 100);
    final statusColor = _getStatusColor(item.status);

    return Container(
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
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.trending_up, size: 18, color: statusColor),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Progress Pengerjaan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          // Quick hint
          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.status == 'selesai'
                      ? 'Tugas ini telah selesai dikerjakan.'
                      : 'Kirim balasan di bawah untuk memperbarui persentase & lampiran.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(TindakLanjutItem item) {
    final feedbacks = item.feedbacks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_outlined, size: 18, color: Color(0xFF334155)),
            const SizedBox(width: 6),
            const Text(
              'Riwayat Progres & Diskusi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${feedbacks.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (feedbacks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Belum ada catatan progres atau respon',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feedbacks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final fb = feedbacks[index];
              return _buildFeedbackBubble(fb);
            },
          ),
      ],
    );
  }

  Widget _buildFeedbackBubble(TindakLanjutFeedbackItem fb) {
    final myNik = box.read('sub')?.toString();
    final isMe = fb.userNik == myNik;
    final isDownloading = _downloadingMap[fb.id] == true;

    Color badgeColor = primaryColor;
    String badgeText = 'Update';
    if (fb.tipe == 'review') {
      badgeColor = const Color(0xFF8B5CF6); // Purple
      badgeText = 'Review / Evaluasi';
    } else if (fb.tipe == 'komentar') {
      badgeColor = const Color(0xFF64748B); // Slate
      badgeText = 'Komentar';
    } else if (fb.progressPercent == 100) {
      badgeColor = const Color(0xFF10B981); // Emerald
      badgeText = 'Selesai 100%';
    }

    DateTime? createdAtDt;
    if (fb.createdAt != null) {
      createdAtDt = DateTime.tryParse(fb.createdAt!)?.toLocal();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? primaryColor.withOpacity(0.3) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Type & Time
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: badgeColor.withOpacity(0.15),
                child: Text(
                  fb.userNama.isNotEmpty ? fb.userNama[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? '${fb.userNama} (Saya)' : fb.userNama,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (createdAtDt != null)
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(createdAtDt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress indicator chip if set
          if (fb.progressPercent != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, size: 13, color: Color(0xFF475569)),
                  const SizedBox(width: 4),
                  Text(
                    'Progress: ${fb.progressPercent}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Pesan Text
          Text(
            fb.pesan,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.35,
            ),
          ),

          // File attachment preview chip/card
          if (fb.hasFile) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: isDownloading ? null : () => _openOrDownloadFile(fb),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFileIcon(fb.namaBerkas),
                        size: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fb.namaBerkas ?? 'Lampiran Bukti',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (fb.formattedFileSize.isNotEmpty)
                            Text(
                              fb.formattedFileSize,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isDownloading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return Icons.description;
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) return Icons.table_chart;
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png')) {
      return Icons.image;
    }
    if (lower.endsWith('.zip') || lower.endsWith('.rar')) return Icons.archive;
    return Icons.insert_drive_file;
  }

  Widget _buildReplyBar(TindakLanjutItem item) {
    final myNik = box.read('sub')?.toString();
    final isCreator = item.createdBy == myNik;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Tipe Respon & Quick Progress Chips
          Row(
            children: [
              // Tipe Selector Dropdown / Chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChipTipe('update_progress', 'Progres', Icons.trending_up),
                      const SizedBox(width: 6),
                      if (isCreator) ...[
                        _buildChipTipe('review', 'Review / Evaluasi', Icons.rate_review_outlined),
                        const SizedBox(width: 6),
                      ],
                      _buildChipTipe('komentar', 'Komentar', Icons.chat_outlined),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // If updating progress, show quick slider / chips
          if (_selectedTipe == 'update_progress') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Progress: $_selectedProgress%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(_selectedStatus),
                  ),
                ),
                const Spacer(),
                _buildQuickPctChip(25),
                const SizedBox(width: 4),
                _buildQuickPctChip(50),
                const SizedBox(width: 4),
                _buildQuickPctChip(75),
                const SizedBox(width: 4),
                _buildQuickPctChip(100),
              ],
            ),
            Slider(
              value: _selectedProgress.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: _selectedProgress == 100 ? const Color(0xFF10B981) : primaryColor,
              label: '$_selectedProgress%',
              onChanged: (val) {
                setState(() {
                  _selectedProgress = val.round();
                  if (_selectedProgress == 100) {
                    _selectedStatus = 'selesai';
                  } else if (_selectedProgress > 0) {
                    _selectedStatus = 'in_progress';
                  }
                });
              },
            ),
          ],

          // Attached file preview chip
          if (_attachedFile != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_getFileIcon(_attachedFileName), size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _attachedFileName != null
                          ? '$_attachedFileName (${_attachedFileSize != null ? "${(_attachedFileSize! / 1024).toStringAsFixed(1)} KB" : ""})'
                          : 'Berkas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _clearAttachedFile,
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          // Input field and buttons
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: _attachedFile != null ? primaryColor : Colors.grey.shade600,
                ),
                tooltip: 'Lampirkan Berkas',
                onPressed: _pickFile,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _pesanController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: _selectedTipe == 'review'
                          ? 'Tulis hasil review / catatan...'
                          : 'Tulis laporan progres / update...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isSubmitting ? null : _submitFeedback,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isSubmitting ? Colors.grey : primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: _isSubmitting
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipTipe(String tipe, String label, IconData icon) {
    final isSelected = _selectedTipe == tipe;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedTipe = tipe;
          });
        }
      },
    );
  }

  Widget _buildQuickPctChip(int pct) {
    final isSelected = _selectedProgress == pct;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedProgress = pct;
          if (pct == 100) {
            _selectedStatus = 'selesai';
          } else {
            _selectedStatus = 'in_progress';
          }
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (pct == 100 ? const Color(0xFF10B981) : primaryColor)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (pct == 100 ? const Color(0xFF10B981) : primaryColor)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          '$pct%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
