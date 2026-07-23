import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/services/ebook_service.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class EbookMainScreen extends StatefulWidget {
  final int initialTabIndex;
  const EbookMainScreen({super.key, this.initialTabIndex = 0});

  @override
  State<EbookMainScreen> createState() => _EbookMainScreenState();
}

class _EbookMainScreenState extends State<EbookMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'E-Book & Jurnal',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Perpustakaan Digital & Publikasi Medis RSIA',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('E-Book'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Jurnal'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EbookListTab(jenis: 'ebook'),
          EbookListTab(jenis: 'jurnal'),
        ],
      ),
    );
  }
}

class EbookListTab extends StatefulWidget {
  final String jenis; // 'ebook' or 'jurnal'
  const EbookListTab({super.key, required this.jenis});

  @override
  State<EbookListTab> createState() => _EbookListTabState();
}

class _EbookListTabState extends State<EbookListTab> {
  final EbookService _service = EbookService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categories = [];
  String _selectedCategory = '';
  String _sortBy = 'terbaru';
  int _currentPage = 1;
  int _lastPage = 1;

  // Track downloading progress map
  final Map<int, double> _downloadProgress = {};
  final Set<int> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.fetchCategories(jenis: widget.jenis),
        _service.fetchEbooks(
          page: 1,
          jenis: widget.jenis,
          kategoriId: _selectedCategory,
          search: _searchController.text,
          sort: _sortBy,
        ),
      ]);

      if (mounted) {
        final catResult = results[0] as List<Map<String, dynamic>>;
        final ebookResult = results[1] as Map<String, dynamic>;

        setState(() {
          _categories = catResult;
          _items = (ebookResult['data'] as List).cast<Map<String, dynamic>>();
          final pagination = ebookResult['pagination'] as Map<String, dynamic>;
          _currentPage = pagination['current_page'] ?? 1;
          _lastPage = pagination['last_page'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchData({bool reset = true}) async {
    if (reset) {
      setState(() => _isLoading = true);
      _currentPage = 1;
    }

    final res = await _service.fetchEbooks(
      page: _currentPage,
      jenis: widget.jenis,
      kategoriId: _selectedCategory,
      search: _searchController.text,
      sort: _sortBy,
    );

    if (mounted) {
      setState(() {
        final newItems = (res['data'] as List).cast<Map<String, dynamic>>();
        if (reset) {
          _items = newItems;
        } else {
          _items.addAll(newItems);
        }
        final pagination = res['pagination'] as Map<String, dynamic>;
        _currentPage = pagination['current_page'] ?? 1;
        _lastPage = pagination['last_page'] ?? 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _fetchData(reset: false);
  }

  String _getFileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    if (path.startsWith('ebook/pdf/')) {
      final filename = path.replaceFirst('ebook/pdf/', '');
      return '${AppConfig.apiUrl}/sdi/ebook/file/$filename';
    }
    if (path.startsWith('ebook/cover/')) {
      final filename = path.replaceFirst('ebook/cover/', '');
      return '${AppConfig.apiUrl}/sdi/ebook/cover/$filename';
    }
    final baseUrl = AppConfig.apiUrl.replaceAll(RegExp(r'/api/v2/?$'), '');
    return '$baseUrl/storage/$path';
  }

  Future<void> _openOrDownloadPdf(Map<String, dynamic> item) async {
    final String? pdfPath = item['file_pdf']?.toString();
    if (pdfPath == null || pdfPath.isEmpty) {
      Msg.error(context, 'Berkas PDF tidak tersedia');
      return;
    }

    final int id = int.tryParse(item['id'].toString()) ?? 0;
    final String fileUrl = _getFileUrl(pdfPath);

    // Increment view count
    _service.incrementView(id);
    setState(() {
      item['views_count'] = (item['views_count'] ?? 0) + 1;
    });

    Directory? dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final filename = fileUrl.substring(fileUrl.lastIndexOf('/') + 1);
    final String localFilePath = "${dir!.path}/$filename";
    final File localFile = File(localFilePath);

    if (await localFile.exists()) {
      await OpenFilex.open(localFilePath);
      return;
    }

    // Download file
    setState(() {
      _downloadingIds.add(id);
      _downloadProgress[id] = 0.0;
    });

    try {
      final Dio dio = Dio();
      await dio.download(
        fileUrl,
        localFilePath,
        onReceiveProgress: (rec, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress[id] = rec / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadingIds.remove(id);
          _downloadProgress.remove(id);
        });
        Msg.success(context, 'Unduh selesai. Membuka dokumen...');
        await OpenFilex.open(localFilePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingIds.remove(id);
          _downloadProgress.remove(id);
        });
        Msg.error(context, 'Gagal mengunduh berkas PDF');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isJurnal = widget.jenis == 'jurnal';
    final Color themeColor = isJurnal ? const Color(0xFF7C3AED) : primaryColor;

    return RefreshIndicator(
      onRefresh: () => _fetchData(reset: true),
      color: themeColor,
      child: Column(
        children: [
          // Filter Bar Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search Input
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _fetchData(reset: true),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: isJurnal
                          ? 'Cari judul jurnal, penulis, ISSN...'
                          : 'Cari judul e-book, penulis, penerbit...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, color: themeColor, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _fetchData(reset: true);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Category Filter Pills (Horizontal Scroll)
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryPill(
                        id: '',
                        label: isJurnal ? 'Semua Bidang' : 'Semua Kategori',
                        themeColor: themeColor,
                      ),
                      ..._categories.map((cat) {
                        final String catId = cat['id'].toString();
                        final String name = cat['nama_kategori']?.toString() ?? '';
                        final int count = cat['ebooks_count'] ?? 0;
                        return _buildCategoryPill(
                          id: catId,
                          label: '$name ($count)',
                          themeColor: themeColor,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Items List
          Expanded(
            child: _isLoading
                ? _buildLoadingState(themeColor)
                : _items.isEmpty
                    ? _buildEmptyState(isJurnal)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _items.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: themeColor,
                                ),
                              ),
                            );
                          }
                          final item = _items[index];
                          return isJurnal
                              ? _buildJurnalCard(item, themeColor)
                              : _buildEbookCard(item, themeColor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String id,
    required String label,
    required Color themeColor,
  }) {
    final bool isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = id);
        _fetchData(reset: true);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEbookCard(Map<String, dynamic> item, Color themeColor) {
    final String title = item['judul']?.toString() ?? '-';
    final String author = item['penulis']?.toString() ?? 'Penulis Tidak Disebutkan';
    final String publisher = item['penerbit']?.toString() ?? '-';
    final String category = item['kategori']?['nama_kategori']?.toString() ?? 'Umum';
    final String year = item['tahun_terbit']?.toString() ?? '-';
    final int views = item['views_count'] ?? 0;
    final String? coverPath = item['cover']?.toString();
    final int id = int.tryParse(item['id'].toString()) ?? 0;
    final bool isDownloading = _downloadingIds.contains(id);
    final double progress = _downloadProgress[id] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // E-Book Cover Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 65,
                height: 90,
                color: const Color(0xFFF1F5F9),
                child: coverPath != null && coverPath.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _getFileUrl(coverPath),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildDefaultCoverIcon(themeColor),
                      )
                    : _buildDefaultCoverIcon(themeColor),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye_rounded, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(
                            '$views',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$publisher • $year',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),

                      // Action Button
                      if (isDownloading)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            strokeWidth: 2.5,
                            color: themeColor,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _openOrDownloadPdf(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                          label: const Text(
                            'Baca PDF',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJurnalCard(Map<String, dynamic> item, Color themeColor) {
    final String title = item['judul']?.toString() ?? '-';
    final String author = item['penulis']?.toString() ?? 'Tim Peneliti RSIA';
    final String publisher = item['penerbit']?.toString() ?? '-';
    final String category = item['kategori']?['nama_kategori']?.toString() ?? 'Jurnal';
    final String year = item['tahun_terbit']?.toString() ?? '-';
    final String? issn = item['isbn_issn']?.toString();
    final int views = item['views_count'] ?? 0;
    final int id = int.tryParse(item['id'].toString()) ?? 0;
    final bool isDownloading = _downloadingIds.contains(id);
    final double progress = _downloadProgress[id] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purple Top Bar Accent
            Container(
              height: 4,
              width: double.infinity,
              color: themeColor,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (issn != null && issn.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'ISSN: $issn',
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye_rounded, size: 14, color: themeColor),
                          const SizedBox(width: 4),
                          Text(
                            '$views Dibaca',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$publisher • $year',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),

                      if (isDownloading)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            strokeWidth: 2.5,
                            color: themeColor,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _openOrDownloadPdf(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                          label: const Text(
                            'Baca Jurnal',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCoverIcon(Color themeColor) {
    return Center(
      child: Icon(
        Icons.book_rounded,
        size: 32,
        color: themeColor.withOpacity(0.5),
      ),
    );
  }

  Widget _buildLoadingState(Color themeColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: themeColor),
          const SizedBox(height: 12),
          Text(
            'Memuat katalog...',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isJurnal) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isJurnal ? Icons.science_outlined : Icons.menu_book_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            isJurnal ? 'Jurnal Tidak Ditemukan' : 'E-Book Tidak Ditemukan',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba ubah filter atau kata kunci pencarian Anda.',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
