import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:rsia_employee_app/screen/pdf_viewer_screen.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class CardFileManager extends StatefulWidget {
  final Map dataFileManager;
  const CardFileManager({super.key, required this.dataFileManager});

  @override
  State<CardFileManager> createState() => _CardFileManagerState();
}

class _CardFileManagerState extends State<CardFileManager> {
  bool isHAveDownloading = false;

  bool downloading = false;
  var progressString = "0%";
  String downloadStart = "Mulai Download...";
  var isDownloadContainerVisible = false;
  String filePath = '';
  var error = '';
  double progress = 0;
  String baseUrl = 'https://rsiap.my.id/rsiap/file/berkas/';
  String fileExt = '';

  String get downloadUrl {
    if (widget.dataFileManager['id'] != null) {
      return "${AppConfig.apiUrl}/file-manager/download/${widget.dataFileManager['id']}";
    }
    return baseUrl + (widget.dataFileManager['file'] ?? '');
  }

  @override
  void initState() {
    super.initState();
    checkFile();
  }

  void requestPermission(downloadUrl) {
    openFile(downloadUrl);
  }

  void checkFile() async {
    String fileName = widget.dataFileManager['file'] ?? '';
    var dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())?.path;
    } else {
      dir = (await getApplicationDocumentsDirectory()).path;
    }
    filePath = "$dir/$fileName";
    fileExt = fileName.contains('.') ? fileName.substring(fileName.lastIndexOf('.') + 1).toUpperCase() : '';

    File file = File(filePath);
    var isExist = await file.exists();
    if (isExist) {
      setState(() {
        isHAveDownloading = true;
      });
    }
  }

  void openFile(String url) async {
    String fileName = widget.dataFileManager['file'] ?? '';
    var dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())?.path;
    } else {
      dir = (await getApplicationDocumentsDirectory()).path;
    }
    filePath = "$dir/$fileName";

    // ── Preview PDF langsung di aplikasi ──
    if (fileExt == 'PDF') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            title: widget.dataFileManager['nama_file'] ?? fileName,
            url: url,
            localPath: isHAveDownloading ? filePath : null,
          ),
        ),
      );
      return;
    }

    File file = File(filePath);
    var isExist = await file.exists();
    if (isExist) {
      await OpenFilex.open(filePath);
      setState(() {
        isDownloadContainerVisible = false;
        isHAveDownloading = true;
      });
    } else {
      downloadFile(url);
    }
  }

  Future<void> downloadFile(String url) async {
    Dio dio = Dio();

    setState(() {
      progressString = "0%";
      downloadStart = "Loading...";
      downloading = true;
      isDownloadContainerVisible = true;
    });
    try {
      final safeUrl = Uri.encodeFull(url);
      await dio.download(safeUrl, filePath, onReceiveProgress: (
        rec,
        total,
      ) {
        if (total > 0) {
          setState(() {
            progressString = "${((rec / total) * 100).toStringAsFixed(0)}%";
          });
        }
      });
      setState(() {
        downloading = false;
        progressString = "";
        downloadStart = "";
        isHAveDownloading = true;
      });

      Msg.success(context, "Download selesai");
      await OpenFilex.open(filePath);
    } catch (e) {
      debugPrint("Download error: $e");
      setState(() {
        downloading = false;
        progressString = "";
        downloadStart = "";
        isHAveDownloading = false;
      });
      Msg.error(context, "Gagal download file");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          requestPermission(downloadUrl);
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
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
              // File Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  fileExt == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),

              // File Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dataFileManager['nama_file'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileExt,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Button
              const SizedBox(width: 10),
              if (downloading)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: double.tryParse(progressString.replaceAll('%', '')) !=
                              null
                          ? (double.parse(progressString.replaceAll('%', '')) / 100)
                          : null,
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                    Text(
                      progressString,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: fileExt == 'PDF'
                        ? primaryColor.withOpacity(0.1)
                        : (isHAveDownloading
                            ? Colors.green.withOpacity(0.1)
                            : primaryColor.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        fileExt == 'PDF'
                            ? Icons.visibility_rounded
                            : (isHAveDownloading
                                ? Icons.check_circle
                                : Icons.download_rounded),
                        color: fileExt == 'PDF'
                            ? primaryColor
                            : (isHAveDownloading ? Colors.green : primaryColor),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fileExt == 'PDF'
                            ? "Lihat"
                            : (isHAveDownloading ? "Buka" : "Unduh"),
                        style: TextStyle(
                          color: fileExt == 'PDF'
                              ? primaryColor
                              : (isHAveDownloading ? Colors.green : primaryColor),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
