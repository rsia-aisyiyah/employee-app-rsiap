import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/berkas_pegawai.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

// cardBerkasPegawai(berkas) {
//   print(berkas['master_berkas_pegawai']['nama_berkas']);
//   return cardBerkasPegawai(berkas);
// }

class cardBerkasPegawai extends StatefulWidget {
  final Map dataBerkasPegawai;
  const cardBerkasPegawai({super.key, required this.dataBerkasPegawai});

  @override
  State<cardBerkasPegawai> createState() => _cardBerkasPegawaiState();
}

class _cardBerkasPegawaiState extends State<cardBerkasPegawai> {
  Future download() async {
    final status = await Permission.storage.request();

    if (status.isGranted) {
      final downloadsDir = await getExternalStorageDirectory();
      await FlutterDownloader.enqueue(
        url:
            'https://sim.rsiaaisyiyah.com/rsiap/file/berkas/SAMPUL_DOKUMEN_RSIA.docx',
        savedDir: downloadsDir!.path,
        headers: {
          // 'content-type': 'application/pdf',
          'content-type': 'application/msword',
        },
        showNotification:
            true, // show download progress in status bar (for Android)
        openFileFromNotification:
            true, // click on notification to open downloaded file (for Android)
      );
    }
  }

  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      if (status == DownloadTaskStatus.complete) {
        print("sukses download");
      }
      setState(() {});
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(String id, int status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              height: 70,
              width: (MediaQuery.of(context).size.width - 35) * 0.8,
              decoration: BoxDecoration(
                  color: bgWhite, borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dataBerkasPegawai['master_berkas_pegawai']
                          ['nama_berkas'],
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              ),
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
                      color: bgWhite, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          download();
                        },
                        icon: Icon(
                          Icons.cloud_download_sharp,
                          color: primaryColor,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: Icon(
                    Icons.picture_as_pdf_sharp,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(
          height: 5,
        )
      ],
    );
  }
}
