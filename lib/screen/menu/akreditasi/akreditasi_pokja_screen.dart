import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/services/akreditasi_service.dart';
import 'package:rsia_employee_app/screen/menu/akreditasi/akreditasi_ep_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class AkreditasiPokjaScreen extends StatefulWidget {
  final Map<String, dynamic> pokja;
  final bool canWrite;
  final Set<int> userPokjaIds;

  const AkreditasiPokjaScreen({
    super.key,
    required this.pokja,
    required this.canWrite,
    required this.userPokjaIds,
  });

  @override
  State<AkreditasiPokjaScreen> createState() => _AkreditasiPokjaScreenState();
}

class _AkreditasiPokjaScreenState extends State<AkreditasiPokjaScreen> {
  final _service = AkreditasiService();
  final _scrollController = ScrollController();

  // GlobalKeys untuk scroll navigasi
  final Map<String, GlobalKey> _standarKeys = {};
  final Map<String, ExpansionTileController> _standarControllers = {};

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _standarList = [];

  @override
  void initState() {
    super.initState();
    _loadStandar();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStandar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final pokjaId = int.parse(widget.pokja['id'].toString());
      final standars = await _service.getStandarWithEpByPokja(pokjaId);

      _standarKeys.clear();
      _standarControllers.clear();
      for (final std in standars) {
        final kode = std['kode'].toString();
        _standarKeys[kode] = GlobalKey();
        _standarControllers[kode] = ExpansionTileController();
      }

      if (mounted) {
        setState(() {
          _standarList = standars;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data: ${e.toString()}';
        });
      }
    }
  }

  // ─── SCROLL NAVIGASI ────────────────────────────────────────────────────────

  void _scrollToStandar(String kode) {
    Navigator.pop(context);
    
    // Auto-expand ExpansionTile
    final controller = _standarControllers[kode];
    if (controller != null && !controller.isExpanded) {
      controller.expand();
    }
    
    // Berikan delay singkat agar layout ExpansionTile mulai meregang sebelum scroll dihitung
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final key = _standarKeys[kode];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    });
  }

  // ─── PROGRESS HELPER ────────────────────────────────────────────────────────

  ({int done, int total}) _getStandarProgress(Map<String, dynamic> standar) {
    int done = 0, total = 0;
    final eps = (standar['elemen_penilaians'] as List<dynamic>? ?? []);
    for (final ep in eps) {
      final todos = ep['todos'] as List<dynamic>? ?? [];
      total += todos.length;
      done += todos.where((t) => t['status'] == 1).length;
    }
    return (done: done, total: total);
  }

  // ─── SEARCH SHEET ────────────────────────────────────────────────────────────

  /// Kumpulkan semua hasil (standar & EP) yang cocok dengan query
  List<_SearchResult> _buildSearchResults(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final results = <_SearchResult>[];

    for (final std in _standarList) {
      final stdKode = (std['kode'] ?? '').toString().toLowerCase();
      final stdPernyataan = (std['pernyataan'] ?? '').toString().toLowerCase();

      // Match standar
      if (stdKode.contains(q) || stdPernyataan.contains(q)) {
        results.add(_SearchResult(
          type: _ResultType.standar,
          kode: std['kode']?.toString() ?? '',
          pernyataan: std['pernyataan']?.toString() ?? '',
          standarKode: std['kode']?.toString() ?? '',
          standar: std,
          ep: null,
        ));
      }

      // Match EP
      final eps = (std['elemen_penilaians'] as List<dynamic>? ?? []);
      for (final ep in eps) {
        final epKode = (ep['kode_ep'] ?? '').toString().toLowerCase();
        final epPernyataan = (ep['pernyataan_ep'] ?? '').toString().toLowerCase();
        final epKelengkapan = (ep['kelengkapan_bukti'] ?? '').toString().toLowerCase();

        if (epKode.contains(q) || epPernyataan.contains(q) || epKelengkapan.contains(q)) {
          results.add(_SearchResult(
            type: _ResultType.ep,
            kode: ep['kode_ep']?.toString() ?? '',
            pernyataan: ep['pernyataan_ep']?.toString() ?? '',
            standarKode: std['kode']?.toString() ?? '',
            standar: std,
            ep: Map<String, dynamic>.from(ep),
          ));
        }
      }
    }

    return results;
  }

  void _showSearchSheet() {
    final searchController = TextEditingController();
    List<_SearchResult> results = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.search_rounded, color: primaryColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.pokja['kode']?.toString() ?? '',
                                    style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
                                  ),
                                  const Text(
                                    'Cari Standar / EP',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A2340)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search field
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ketik kode atau pernyataan...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                            suffixIcon: searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      searchController.clear();
                                      setSheetState(() => results = []);
                                    },
                                    child: Icon(Icons.close_rounded, color: Colors.grey[400], size: 18),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF0F4F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            setSheetState(() => results = _buildSearchResults(val));
                          },
                        ),
                      ),

                      Divider(color: Colors.grey[100], height: 1),

                      // Hasil pencarian
                      Expanded(
                        child: results.isEmpty && searchController.text.trim().isNotEmpty
                            ? _buildSearchEmpty()
                            : results.isEmpty
                                ? _buildSearchHint()
                                : ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: results.length,
                                    itemBuilder: (_, i) => _buildSearchResultItem(results[i], ctx),
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search_rounded, size: 52, color: Colors.grey[200]),
          const SizedBox(height: 12),
          Text(
            'Cari di ${_standarList.length} standar',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Kode standar, EP, atau isi pernyataan',
            style: TextStyle(fontSize: 12, color: Colors.grey[350]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey[200]),
          const SizedBox(height: 12),
          Text(
            'Tidak ditemukan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba kata kunci lain',
            style: TextStyle(fontSize: 12, color: Colors.grey[350]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(_SearchResult result, BuildContext sheetCtx) {
    final isEp = result.type == _ResultType.ep;

    return InkWell(
      onTap: () {
        if (isEp && result.ep != null) {
          // Buka EP detail langsung
          Navigator.pop(sheetCtx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AkreditasiEpDetailScreen(
                ep: result.ep!,
                standar: result.standar,
                pokja: widget.pokja,
                canWrite: widget.canWrite,
              ),
            ),
          ).then((_) => _loadStandar());
        } else {
          // Scroll ke standar
          _scrollToStandar(result.standarKode);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isEp
                    ? const Color(0xFF1565C0).withOpacity(0.08)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    isEp ? Icons.checklist_rtl_rounded : Icons.layers_rounded,
                    size: 14,
                    color: isEp ? const Color(0xFF1565C0) : primaryColor,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEp ? 'EP' : 'STD',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isEp ? const Color(0xFF1565C0) : primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kode
                  Row(
                    children: [
                      Text(
                        result.kode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isEp ? const Color(0xFF1565C0) : primaryColor,
                        ),
                      ),
                      if (isEp) ...[
                        const SizedBox(width: 6),
                        Text(
                          '← ${result.standarKode}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Pernyataan (truncated)
                  Text(
                    result.pernyataan,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568), height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isEp ? Icons.open_in_new_rounded : Icons.arrow_downward_rounded,
              size: 15,
              color: Colors.grey[350],
            ),
          ],
        ),
      ),
    );
  }

  // ─── NAVIGASI SHEET ─────────────────────────────────────────────────────────

  void _showNavigasiSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.list_alt_rounded, color: primaryColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.pokja['kode']?.toString() ?? 'BAB',
                                style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
                              ),
                              const Text(
                                'Navigasi Standar',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A2340)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_standarList.length} Standar',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey[100], height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _standarList.length,
                      itemBuilder: (context, i) {
                        final std = _standarList[i];
                        final progress = _getStandarProgress(std);
                        final epCount = (std['elemen_penilaians'] as List? ?? []).length;

                        return InkWell(
                          onTap: () => _scrollToStandar(std['kode'].toString()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    std['kode']?.toString() ?? '',
                                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$epCount EP',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                      if (progress.total > 0)
                                        Text(
                                          'Tugas: ${progress.done}/${progress.total}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: progress.done == progress.total
                                                ? Colors.green.shade600
                                                : Colors.orange.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (progress.total > 0) ...[
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      value: progress.total > 0 ? progress.done / progress.total : 0,
                                      strokeWidth: 3,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation(
                                        progress.done == progress.total
                                            ? Colors.green.shade500
                                            : Colors.orange.shade400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildShimmer()
                    : _errorMessage != null
                        ? _buildError()
                        : RefreshIndicator(
                            onRefresh: _loadStandar,
                            color: primaryColor,
                            child: _standarList.isEmpty
                                ? _buildEmpty()
                                : SingleChildScrollView(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                    child: Column(
                                      children: _standarList.map((std) => _buildStandarCard(std)).toList(),
                                    ),
                                  ),
                          ),
              ),
            ],
          ),

          // FAB group: Cari + Navigasi
          if (!_isLoading && _standarList.isNotEmpty)
            Positioned(
              bottom: 24,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Search FAB (mini)
                  FloatingActionButton(
                    heroTag: 'fab_search',
                    onPressed: _showSearchSheet,
                    backgroundColor: Colors.white,
                    elevation: 4,
                    mini: true,
                    child: Icon(Icons.search_rounded, color: primaryColor, size: 22),
                  ),
                  const SizedBox(height: 10),
                  // Navigasi FAB (extended)
                  FloatingActionButton.extended(
                    heroTag: 'fab_nav',
                    onPressed: _showNavigasiSheet,
                    backgroundColor: primaryColor,
                    elevation: 6,
                    icon: const Icon(Icons.compass_calibration_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'Navigasi',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1565C0), primaryColor],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  widget.pokja['kode']?.toString() ?? 'BAB',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  widget.pokja['nama_lengkap']?.toString() ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.canWrite ? Colors.green.withOpacity(0.25) : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.canWrite ? Colors.green.shade300 : Colors.white30),
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

  // ─── STANDAR CARD ───────────────────────────────────────────────────────────

  Widget _buildStandarCard(Map<String, dynamic> standar) {
    final eps = (standar['elemen_penilaians'] as List<dynamic>? ?? []);
    final kode = standar['kode']?.toString() ?? '';
    final progress = _getStandarProgress(standar);

    return Container(
      key: _standarKeys[kode],
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            controller: _standarControllers[kode],
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            childrenPadding: EdgeInsets.zero,
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  kode,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: kode.length > 6 ? 9 : 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            title: Text(
              standar['pernyataan']?.toString() ?? kode,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A2340)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  if (progress.total > 0) ...[
                    Icon(Icons.task_alt_rounded, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text('${progress.done}/${progress.total} tugas',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(width: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: eps.isEmpty ? Colors.grey.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${eps.length} EP',
                      style: TextStyle(
                        fontSize: 10,
                        color: eps.isEmpty ? Colors.grey : primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            iconColor: primaryColor,
            collapsedIconColor: Colors.grey[400],
            children: eps.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Belum ada elemen penilaian',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12), textAlign: TextAlign.center),
                    ),
                  ]
                : eps.map((ep) => _buildEpItem(Map<String, dynamic>.from(ep), standar)).toList(),
          ),
        ),
      ),
    );
  }

  // ─── EP ITEM ────────────────────────────────────────────────────────────────

  Widget _buildEpItem(Map<String, dynamic> ep, Map<String, dynamic> standar) {
    final todos = ep['todos'] as List<dynamic>? ?? [];
    final docs = ep['dokumens'] as List<dynamic>? ?? [];
    final todoDone = todos.where((t) => t['status'] == 1).length;
    final metode = (ep['tipe_bukti']?.toString() ?? '').split(',').map((e) => e.trim()).toList();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AkreditasiEpDetailScreen(
            ep: ep,
            standar: standar,
            pokja: widget.pokja,
            canWrite: widget.canWrite,
          ),
        ),
      ).then((_) => _loadStandar()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
          color: Colors.grey.shade50,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ep['kode_ep']?.toString() ?? 'EP ${ep['nomor']}',
                style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ep['pernyataan_ep']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1A2340), fontWeight: FontWeight.w500, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...metode.take(5).map((m) => _buildMetodeBadge(m)),
                      const Spacer(),
                      if (todos.isNotEmpty)
                        _buildChip(Icons.task_alt_rounded, '$todoDone/${todos.length}',
                            todoDone == todos.length ? Colors.green : Colors.orange),
                      if (todos.isNotEmpty && docs.isNotEmpty) const SizedBox(width: 5),
                      if (docs.isNotEmpty) _buildChip(Icons.attach_file_rounded, '${docs.length}', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodeBadge(String m) {
    final colors = {
      'R': Colors.red.shade600,
      'D': Colors.blue.shade600,
      'O': Colors.orange.shade600,
      'W': Colors.cyan.shade600,
      'S': Colors.green.shade600,
    };
    final color = colors[m.toUpperCase()] ?? Colors.grey.shade600;
    if (m.isEmpty) return const SizedBox.shrink();
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
      child: Center(
        child: Text(m.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── EMPTY / ERROR / SHIMMER ────────────────────────────────────────────────

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Belum ada standar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[500])),
              const SizedBox(height: 8),
              Text('Hubungi administrator untuk import data instrumen.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Terjadi kesalahan',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadStandar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ─── MODEL HASIL PENCARIAN ───────────────────────────────────────────────────

enum _ResultType { standar, ep }

class _SearchResult {
  final _ResultType type;
  final String kode;
  final String pernyataan;
  final String standarKode;
  final Map<String, dynamic> standar;
  final Map<String, dynamic>? ep;

  const _SearchResult({
    required this.type,
    required this.kode,
    required this.pernyataan,
    required this.standarKode,
    required this.standar,
    required this.ep,
  });
}
