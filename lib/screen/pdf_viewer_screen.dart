import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String url;
  final String? localPath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.url,
    this.localPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _displayPath;
  bool _isLoading = true;
  String _loadingText = "Menyiapkan dokumen...";
  double _downloadProgress = 0.0;
  String? _errorMessage;

  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _downloadProgress = 0.0;
      _loadingText = "Memuat dokumen...";
    });

    try {
      // 1. Cek apakah file lokal sudah ada dan valid
      if (widget.localPath != null && widget.localPath!.isNotEmpty) {
        final localFile = File(widget.localPath!);
        if (await localFile.exists() && await localFile.length() > 0) {
          setState(() {
            _displayPath = widget.localPath;
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Jika belum ada, download ke direktori cache sementara
      final tempDir = await getTemporaryDirectory();
      final safeName = widget.url.hashCode.abs().toString();
      final cachePath = "${tempDir.path}/preview_$safeName.pdf";
      final cacheFile = File(cachePath);

      // Gunakan cache jika sudah ada
      if (await cacheFile.exists() && await cacheFile.length() > 0) {
        setState(() {
          _displayPath = cachePath;
          _isLoading = false;
        });
        return;
      }

      final dio = Dio();
      final safeUrl = Uri.encodeFull(widget.url);

      await dio.download(
        safeUrl,
        cachePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
              _loadingText =
                  "Mengunduh preview (${(_downloadProgress * 100).toInt()}%)...";
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _displayPath = cachePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal memuat berkas PDF: ${e.toString()}";
        });
      }
    }
  }

  void _openExternally() async {
    if (_displayPath != null) {
      await OpenFilex.open(_displayPath!);
    } else {
      Msg.warning(context, "Dokumen belum siap");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_totalPages > 0)
              Text(
                "Halaman ${_currentPage + 1} dari $_totalPages",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            tooltip: "Muat Ulang",
            onPressed: _preparePdf,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.black87),
            tooltip: "Buka di Aplikasi Lain",
            onPressed: _openExternally,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Loading State ──
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    color: primaryColor,
                    strokeWidth: 3.5,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _loadingText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          // ── Error State ──
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _preparePdf,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text("Coba Lagi"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // ── PDF View ──
          else if (_displayPath != null)
            PDFView(
              filePath: _displayPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: false,
              pageSnap: false,
              defaultPage: _currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages ?? 0;
                  _isReady = true;
                });
              },
              onError: (error) {
                setState(() {
                  _errorMessage = error.toString();
                });
              },
              onViewCreated: (PDFViewController controller) {
                _pdfViewController = controller;
              },
              onPageChanged: (int? page, int? total) {
                setState(() {
                  _currentPage = page ?? 0;
                  _totalPages = total ?? 0;
                });
              },
            ),

          // ── Bottom Page Pill Indicator ──
          if (_isReady && _totalPages > 0)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "${_currentPage + 1} / $_totalPages",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
