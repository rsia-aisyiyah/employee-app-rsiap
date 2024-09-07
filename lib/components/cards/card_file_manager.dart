import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:dio/dio.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class cardFileManager extends StatefulWidget {
  final Map dataFileManager;
  const cardFileManager({super.key, required this.dataFileManager});

  @override
  State<cardFileManager> createState() => _cardFileManagerState();
}

class _cardFileManagerState extends State<cardFileManager> {
  bool isHAveDownloading = false;

  bool downloading = false;
  var progressString = "0%";
  String downloadStart = "Mulai Download...";
  var isDownloadContainerVisible = false;
  String filePath = '';
  var error = '';
  double progress = 0;
  String baseUrl = 'https://sim.rsiaaisyiyah.com/rsiap/file/berkas/';
  String fileExt = '';

  @override
  void initState() {
    super.initState();
    checkFile();
  }


  Future<void> requestPermission(downloadUrl) async {
    var storage = await Permission.storage.status;
    var image = await Permission.mediaLibrary.status;
    var mediaLocation = await Permission.accessMediaLocation.status;

    if(!storage.isGranted) {
      await Permission.storage.request();
    }

    if(!image.isGranted) {
      await Permission.mediaLibrary.request();
    }

    if(!mediaLocation.isGranted) {
      await Permission.accessMediaLocation.request();
    }
    
    openFile(downloadUrl);
  }

  void checkFile() async {
    String url = baseUrl + widget.dataFileManager['file'];
    var dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())?.path;
    } else {
      dir = (await getApplicationDocumentsDirectory()).path;
    }
    filePath = "$dir/${url.substring(url.lastIndexOf('/') + 1)}";
    fileExt = url.substring(url.lastIndexOf('.') + 1).toUpperCase();

    File file = File(filePath);
    var isExist = await file.exists();
    if (isExist) {
      setState(() {
        isHAveDownloading = true;
        fileExt = url.substring(url.lastIndexOf('.') + 1).toUpperCase();
      });
    } else {
      setState(() {
        fileExt = url.substring(url.lastIndexOf('.') + 1).toUpperCase();
      });
    }
  }

  void openFile(String url) async {
    var dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())?.path;
    } else {
      dir = (await getApplicationDocumentsDirectory()).path;
    }
    filePath = "$dir/${url.substring(url.lastIndexOf('/') + 1)}";

    File file = File(filePath);
    var isExist = await file.exists();
    if (isExist) {
      await OpenFile.open(filePath);
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
      await dio.download(url, filePath, onReceiveProgress: (
        rec,
        total,
      ) {
        setState(() {
          progressString = "${((rec / total) * 100).toStringAsFixed(0)}%";
        });
      });
      setState(() {
        downloading = false;
        progressString = "";
        downloadStart = "";
        isHAveDownloading = true;
      });

      Msg.success(context, "Download selesai");
      openFile(url);
    } catch (e) {
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
    return Column(
      children: [
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 70,
                  width: (MediaQuery.of(context).size.width - 35) * 0.8,
                  decoration: BoxDecoration(
                    color: bgWhite,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dataFileManager['nama_file'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -3,
                  right: -1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: primaryColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: 4,
                        top: 1,
                        bottom: 1,
                      ),
                      child: Text(
                        fileExt,
                        style: TextStyle(
                          fontSize: 10,
                          color: textWhite,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              width: 5,
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 70,
                  width: (MediaQuery.of(context).size.width - 35) * 0.2,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      )
                    ],
                    color: bgWhite,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                          onTap: () {
                            requestPermission(baseUrl + widget.dataFileManager['file'].toString());
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              if (!downloading)
                                isHAveDownloading
                                    ? Icon(
                                        Icons.menu_book_rounded,
                                        color: primaryColor,
                                        size: 32,
                                      )
                                    : Icon(
                                        Icons.cloud_download_sharp,
                                        color: primaryColor,
                                        size: 32,
                                      ),
                              downloading
                                  ? Column(
                                    children: [
                                      Container(
                                          width: 50,
                                          height: 25,
                                          padding: const EdgeInsets.all(8),
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(10),
                                            ),
                                            child: LinearProgressIndicator(
                                              backgroundColor: bgColor,
                                              color: primaryColor,
                                            ),
                                          ),
                                      ),
                                      Text(progressString)
                                    ],
                                  )
                                  : Container(),
                              // ShowOrHideDownloadDialog(),
                            ],
                          ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        )
      ],
    );
  }
}
