import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class QRAttendanceScanPage extends StatefulWidget {
  const QRAttendanceScanPage({super.key});

  @override
  State<QRAttendanceScanPage> createState() => _QRAttendanceScanPageState();
}

class _QRAttendanceScanPageState extends State<QRAttendanceScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  Barcode? result;
  bool isLoading = false;
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  // attendance to api using post method
  void _handleAttendance(String qrCode) async {
    setState(() {
      isLoading = true; // Set isLoading menjadi true saat request dimulai
    });

    try {
      var res = await Api().postData({'no_surat': qrCode}, '/undangan/kehadiran');
      var body = json.decode(res.body);

      if (res.statusCode == 200) {
        Msg.success(context, body['message']);
        Navigator.pop(context);
      } else {
        Msg.error(context, body['message']);
        Navigator.pop(context);
      }

    } catch (e) {
      Msg.error(context, 'Failed to connect to server');
    } finally {
      setState(() {
        isLoading = false; // Set isLoading menjadi false setelah request selesai
      });
    }
  }

  void _requestPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return;
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }
    final result = await [Permission.camera].request();
    if (result[Permission.camera]!.isGranted) {
      return;
    }
  }

  // init state
  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||  MediaQuery.of(context).size.height < 400)
        ? 300.0
        : 600.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: primaryColor,
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: primaryColor,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: scanArea,
                  ),
                ),
              ),
            ],
          ),

          // Widget untuk menampilkan loading/pesan di atas QRView
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Background transparan
              child: const Center(
                child: CircularProgressIndicator(), // Indikator loading
              ),
            ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        _handleAttendance(result!.code!);
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
