import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/berkas_pegawai.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_svg/svg.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:dio/dio.dart';
import 'package:rsia_employee_app/utils/msg.dart';

// cardFileManager(berkas) {
//   print(berkas['master_berkas_pegawai']['nama_berkas']);
//   return cardFileManager(berkas);
// }

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
  // Future download2() async {
  //   FileDownloader.downloadFile(
  //       url:
  //           "https://sim.rsiaaisyiyah.com/rsiap/file/berkas/FORMAT_SURAT_PERMOHONAN_IZIN.docx",
  //       name: "", //THE FILE NAME AFTER DOWNLOADING,
  //       onProgress: (String? fileName, double? progress) {
  //         print('FILE fileName HAS PROGRESS $progress');
  //       },
  //       onDownloadCompleted: (String path) {
  //         print('FILE DOWNLOADED TO PATH: $path');
  //       },
  //       onDownloadError: (String error) {
  //         print('DOWNLOAD ERROR: $error');
  //       });
  // }
  //You can download a single file

  // Future download() async {
  //   FlutterDownloader.registerCallback(downloadCallback);
  //   final status = await Permission.storage.request();

  //   if (status.isGranted) {
  //     final downloadsDir = await getExternalStorageDirectory();
  //     await FlutterDownloader.enqueue(
  //       url:
  //           'https://sim.rsiaaisyiyah.com/rsiap/file/berkas/SAMPUL_DOKUMEN_RSIA.docx',
  //       savedDir: downloadsDir!.path,
  //       headers: {},
  //       showNotification:
  //           true, // show download progress in status bar (for Android)
  //       openFileFromNotification:
  //           true, // click on notification to open downloaded file (for Android)
  //     );
  //   }
  // }

  // ReceivePort _port = ReceivePort();

  // @pragma('vm:entry-point')
  // static void downloadCallback(String id, int status, int progress) {
  //   final SendPort send =
  //       IsolateNameServer.lookupPortByName('downloader_send_port')!;
  //   send.send([id, status, progress]);
  // }

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();

  //   IsolateNameServer.registerPortWithName(
  //       _port.sendPort, 'downloader_send_port');
  //   _port.listen((dynamic data) {
  //     String id = data[0];
  //     DownloadTaskStatus status = data[1];
  //     int progress = data[2];

  //     // if (status == DownloadTaskStatus.complete) {
  //     //   print("sukses download");
  //     // }
  //     setState(() {});
  //   });

  //   FlutterDownloader.registerCallback(downloadCallback);
  // }

  // @override
  // void dispose() {
  //   IsolateNameServer.removePortNameMapping('downloader_send_port');
  //   super.dispose();
  // }

  Future<void> requestPermission(downloadUrl) async {
    var manExtStorage = await Permission.manageExternalStorage.status;
    var manStorage = await Permission.storage.status;

    if (!manExtStorage.isGranted) {
      await Permission.manageExternalStorage.request();
    } else {
      openFile(downloadUrl);
    }

    if(!manStorage.isGranted) {
      await Permission.storage.request();
    } else {
      openFile(downloadUrl);
    }
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

    print(fileExt);
    print("Lokasi File $filePath");

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
    print("Lokasi File $filePath");

    File file = File(filePath);
    var isExist = await file.exists();
    if (isExist) {
      print('File Exist----------');
      await OpenFile.open(filePath);
      setState(() {
        isDownloadContainerVisible = false;
        isHAveDownloading = true;
      });
    } else {
      print('File Tidak Ada ----------');
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
        print("Rec: $rec , Total: $total");
        setState(() {
          progressString = ((rec / total) * 100).toStringAsFixed(0) + "%";
        });
      });
      setState(() {
        downloading = false;
        progressString = "";
        downloadStart = "";
        isHAveDownloading = true;
      });

      print("Download Selesai");
      Msg.success(context, "Download selesai");
      openFile(url);
    } catch (e) {
      print(e);
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
                        blurRadius: 0,
                        offset: const Offset(2, 2),
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
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
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
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withOpacity(0.5),
                          blurRadius: 0,
                          offset: const Offset(1, 1),
                        )
                      ],
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
                    // child: Icon(
                    //   Icons.picture_as_pdf,
                    //   color: Colors.red,
                    //   size: 18,
                    // ),
                  ),
                ),
              ],
            ),
            SizedBox(
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
                        blurRadius: 0,
                        offset: const Offset(2, 2),
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
                            print(baseUrl +
                                widget.dataFileManager['file'].toString());
                            requestPermission(baseUrl +
                                widget.dataFileManager['file'].toString());
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              if (!downloading)
                                isHAveDownloading
                                    ? Icon(
                                        Icons.menu_book_rounded,
                                        color: Colors.green[300],
                                        size: 32,
                                      )
                                    : Icon(
                                        Icons.cloud_download_sharp,
                                        color: primaryColor,
                                        size: 32,
                                      ),
                              downloading
                                  ? Container(
                                      width: 50,
                                      height: 25,
                                      padding: const EdgeInsets.all(8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                        child: LinearProgressIndicator(
                                          backgroundColor: bgColor,
                                          color: primaryColor,
                                        ),
                                      ))
                                  : Container(),
                              // ShowOrHideDownloadDialog(),
                            ],
                          )),
                      // IconButton(
                      //   onPressed: () {
                      //     requestPermission();
                      //   },
                      //   icon: Icon(
                      //     Icons.cloud_download_sharp,
                      //     color: primaryColor,
                      //     size: 36,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                // Positioned(
                //   top: -5,
                //   right: -5,
                //   child: Container(
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(5),
                //       border: Border.all(
                //         width: 0.5,
                //       ),
                //       color: bgWhite,
                //     ),
                //     child: Padding(
                //       padding: const EdgeInsets.all(1.0),
                //       child: Text(
                //         fileExt,
                //         style: TextStyle(fontSize: 10),
                //       ),
                //     ),
                //     // child: Icon(
                //     //   Icons.picture_as_pdf,
                //     //   color: Colors.red,
                //     //   size: 18,
                //     // ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
        SizedBox(
          height: 10,
        )
      ],
    );
  }
}
