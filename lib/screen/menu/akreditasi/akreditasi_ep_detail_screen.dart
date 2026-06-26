// ignore: unused_import
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/services/akreditasi_service.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class AkreditasiEpDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ep;
  final Map<String, dynamic> standar;
  final Map<String, dynamic> pokja;
  final bool canWrite;

  const AkreditasiEpDetailScreen({
    super.key,
    required this.ep,
    required this.standar,
    required this.pokja,
    required this.canWrite,
  });

  @override
  State<AkreditasiEpDetailScreen> createState() =>
      _AkreditasiEpDetailScreenState();
}

class _AkreditasiEpDetailScreenState extends State<AkreditasiEpDetailScreen>
    with SingleTickerProviderStateMixin {
  final _service = AkreditasiService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isUploadingDoc = false;
  List<Map<String, dynamic>> _todos = [];
  List<Map<String, dynamic>> _dokumens = [];

  final _newTodoController = TextEditingController();
  int? _editingTodoId;
  final _editTodoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newTodoController.dispose();
    _editTodoController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final epId = int.parse(widget.ep['id'].toString());
      final detail = await _service.getEpById(epId);
      if (mounted) {
        setState(() {
          _todos = List<Map<String, dynamic>>.from(detail['todos'] ?? widget.ep['todos'] ?? []);
          _dokumens = List<Map<String, dynamic>>.from(detail['dokumens'] ?? widget.ep['dokumens'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _todos = List<Map<String, dynamic>>.from(widget.ep['todos'] ?? []);
          _dokumens = List<Map<String, dynamic>>.from(widget.ep['dokumens'] ?? []);
          _isLoading = false;
        });
      }
    }
  }

  // ─── TODO ACTIONS ──────────────────────────────────────────────────────────

  Future<void> _addTodo() async {
    final text = _newTodoController.text.trim();
    if (text.isEmpty) return;

    final epId = int.parse(widget.ep['id'].toString());
    final ok = await _service.createTodo(epId, text);

    if (ok) {
      _newTodoController.clear();
      _loadDetail();
    } else {
      if (mounted) Msg.error(context, 'Gagal menambahkan catatan');
    }
  }

  Future<void> _toggleTodo(Map<String, dynamic> todo) async {
    final newStatus = (todo['status'] == 1) ? 0 : 1;
    final ok = await _service.updateTodoStatus(
      int.parse(todo['id'].toString()),
      newStatus,
    );
    if (ok) _loadDetail();
  }

  Future<void> _deleteTodo(int todoId) async {
    final confirmed = await _showConfirmDialog(
      'Hapus Catatan',
      'Apakah Anda yakin ingin menghapus catatan ini?',
    );
    if (!confirmed) return;

    final ok = await _service.deleteTodo(todoId);
    if (ok) {
      _loadDetail();
    } else {
      if (mounted) Msg.error(context, 'Gagal menghapus catatan');
    }
  }

  Future<void> _saveTodoEdit(int todoId) async {
    final text = _editTodoController.text.trim();
    if (text.isEmpty) return;

    final ok = await _service.updateTodoText(todoId, text);
    if (ok) {
      setState(() => _editingTodoId = null);
      _loadDetail();
    } else {
      if (mounted) Msg.error(context, 'Gagal menyimpan perubahan');
    }
  }

  // ─── DOKUMEN ACTIONS ───────────────────────────────────────────────────────

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    if (picked.path == null) return;

    setState(() => _isUploadingDoc = true);

    try {
      final file = File(picked.path!);
      final epId = int.parse(widget.ep['id'].toString());
      final ok = await _service.uploadDokumen(epId, file, picked.name);

      if (ok) {
        _loadDetail();
        if (mounted) Msg.success(context, 'Dokumen berhasil diunggah');
      } else {
        if (mounted) Msg.error(context, 'Gagal mengunggah dokumen');
      }
    } catch (e) {
      if (mounted) Msg.error(context, 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isUploadingDoc = false);
    }
  }

  Future<void> _openDokumen(Map<String, dynamic> doc) async {
    var fileUrl = doc['file_url']?.toString() ?? doc['url']?.toString();
    if ((fileUrl == null || fileUrl.isEmpty) && doc['file'] != null) {
      fileUrl = '${AppConfig.apiUrl}/akred/elemen-penilaian-dokumen/view/${doc['file']}';
    }

    final fileName = doc['nama']?.toString() ?? doc['file']?.toString() ?? 'dokumen';

    if (fileUrl == null || fileUrl.isEmpty) {
      Msg.warning(context, 'URL dokumen tidak tersedia');
      return;
    }

    // Build full URL jika relative
    final fullUrl = fileUrl.startsWith('http') ? fileUrl : '${AppConfig.baseUrl}/$fileUrl';

    try {
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/$fileName';
      final localFile = File(localPath);

      if (!await localFile.exists()) {
        // Download file dulu
        _showLoadingSnackbar('Mengunduh dokumen...');
        final res = await Api().getFullUrl(fullUrl);
        await localFile.writeAsBytes(res.bodyBytes);
      }

      await OpenFilex.open(localPath);
    } catch (e) {
      if (mounted) Msg.error(context, 'Tidak dapat membuka dokumen: $e');
    }
  }

  Future<void> _deleteDokumen(int docId) async {
    final confirmed = await _showConfirmDialog(
      'Hapus Dokumen',
      'Apakah Anda yakin ingin menghapus dokumen ini?',
    );
    if (!confirmed) return;

    final ok = await _service.deleteDokumen(docId);
    if (ok) {
      _loadDetail();
      if (mounted) Msg.success(context, 'Dokumen berhasil dihapus');
    } else {
      if (mounted) Msg.error(context, 'Gagal menghapus dokumen');
    }
  }

  // ─── HELPER ────────────────────────────────────────────────────────────────

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showLoadingSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          _buildHeader(),
          _buildEpInfo(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTodoTab(),
                      _buildDokumenTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1565C0), primaryColor],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.pokja['kode']} › ${widget.standar['kode']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  widget.ep['kode_ep']?.toString() ?? 'EP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Access badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.canWrite
                  ? Colors.green.withOpacity(0.25)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.canWrite ? Colors.green.shade300 : Colors.white30,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.canWrite ? Icons.edit_note_rounded : Icons.visibility_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.canWrite ? 'Bisa Edit' : 'Lihat Saja',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpInfo() {
    final metode = (widget.ep['metode_evaluasi']?.toString() ?? '').split(',').map((e) => e.trim()).toList();
    final colors = {
      'R': Colors.red.shade600,
      'D': Colors.blue.shade600,
      'O': Colors.orange.shade600,
      'W': Colors.cyan.shade600,
      'S': Colors.green.shade600,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Metode evaluasi badges
          if (metode.isNotEmpty && metode.first.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              children: metode.map((m) {
                final color = colors[m.toUpperCase()] ?? Colors.grey.shade600;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    m.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Pernyataan EP
          Text(
            widget.ep['pernyataan_ep']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1A2340),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),

          // Kelengkapan bukti
          if (widget.ep['kelengkapan_bukti'] != null &&
              widget.ep['kelengkapan_bukti'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: primaryColor, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KELENGKAPAN BUKTI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.ep['kelengkapan_bukti'].toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A5568),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey[500],
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.5, color: primaryColor),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.task_alt_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Catatan'),
                if (_todos.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_todos.length}',
                      style: TextStyle(fontSize: 10, color: primaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_file_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Dokumen'),
                if (_dokumens.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_dokumens.length}',
                      style: const TextStyle(fontSize: 10, color: Colors.blue),
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

  // ─── TODO TAB ──────────────────────────────────────────────────────────────

  Widget _buildTodoTab() {
    final done = _todos.where((t) => t['status'] == 1).length;
    final total = _todos.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Progress bar
        if (total > 0) ...[
          Row(
            children: [
              Text(
                '$done/$total selesai',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${total > 0 ? (done * 100 ~/ total) : 0}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: done == total ? Colors.green.shade600 : primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                done == total ? Colors.green.shade400 : primaryColor,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Add todo (hanya jika bisa write)
        if (widget.canWrite) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTodoController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tambah catatan baru...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                GestureDetector(
                  onTap: _addTodo,
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Todo list
        if (_todos.isEmpty)
          _buildEmptyState(
            Icons.task_alt_rounded,
            'Belum ada catatan',
            widget.canWrite ? 'Tambahkan catatan di atas' : null,
          )
        else
          ..._todos.map((todo) => _buildTodoItem(todo)),
      ],
    );
  }

  Widget _buildTodoItem(Map<String, dynamic> todo) {
    final isDone = todo['status'] == 1;
    final todoId = int.parse(todo['id'].toString());
    final isEditing = _editingTodoId == todoId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: widget.canWrite ? () => _toggleTodo(todo) : null,
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: isDone ? Colors.green.shade400 : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone ? Colors.green.shade400 : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: isEditing
                ? TextField(
                    controller: _editTodoController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onSubmitted: (_) => _saveTodoEdit(todoId),
                  )
                : GestureDetector(
                    onDoubleTap: widget.canWrite
                        ? () {
                            setState(() {
                              _editingTodoId = todoId;
                              _editTodoController.text = todo['todo'] ?? '';
                            });
                          }
                        : null,
                    child: Text(
                      todo['todo']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDone ? Colors.green.shade700 : const Color(0xFF1A2340),
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),

          // Actions
          if (widget.canWrite) ...[
            const SizedBox(width: 8),
            if (isEditing)
              GestureDetector(
                onTap: () => _saveTodoEdit(todoId),
                child: Icon(Icons.check_circle_rounded, color: Colors.green.shade500, size: 20),
              )
            else ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _editingTodoId = todoId;
                    _editTodoController.text = todo['todo'] ?? '';
                  });
                },
                child: Icon(Icons.edit_rounded, color: Colors.grey[400], size: 18),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _deleteTodo(todoId),
                child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 18),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── DOKUMEN TAB ───────────────────────────────────────────────────────────

  Widget _buildDokumenTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Upload button (hanya jika bisa write)
        if (widget.canWrite) ...[
          GestureDetector(
            onTap: _isUploadingDoc ? null : _pickAndUpload,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isUploadingDoc)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                    )
                  else
                    Icon(Icons.upload_file_rounded, color: primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    _isUploadingDoc ? 'Mengunggah...' : 'Pilih & Unggah Dokumen',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Format: PDF, DOC, DOCX, XLS, XLSX, JPG, PNG',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
        ],

        // Dokumen list
        if (_dokumens.isEmpty)
          _buildEmptyState(
            Icons.folder_open_rounded,
            'Belum ada dokumen',
            widget.canWrite ? 'Unggah dokumen bukti di atas' : null,
          )
        else
          ..._dokumens.map((doc) => _buildDokumenItem(doc)),
      ],
    );
  }

  Widget _buildDokumenItem(Map<String, dynamic> doc) {
    final docId = int.parse(doc['id'].toString());
    final namaFile = doc['nama']?.toString() ?? doc['file']?.toString() ?? 'Dokumen';
    final ext = namaFile.split('.').last.toLowerCase();

    final icon = _getFileIcon(ext);
    final iconColor = _getFileIconColor(ext);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          namaFile,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2340),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: doc['created_at'] != null
            ? Text(
                _formatDate(doc['created_at'].toString()),
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _openDokumen(doc),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.open_in_new_rounded, color: primaryColor, size: 16),
              ),
            ),
            if (widget.canWrite) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteDokumen(docId),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  // ─── UTILS ─────────────────────────────────────────────────────────────────

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileIconColor(String ext) {
    switch (ext) {
      case 'pdf':
        return Colors.red.shade600;
      case 'doc':
      case 'docx':
        return Colors.blue.shade600;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade600;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${_monthName(dt.month)} ${dt.year} - $hour:$minute';
    } catch (_) {
      return dateStr;
    }
  }

  String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[m];
  }
}
