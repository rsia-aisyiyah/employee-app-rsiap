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
  bool isProcessing = false;
  bool isFlashOn = false;
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  void _handleAttendance(String qrCode) async {
    if (isProcessing) return;
    setState(() {
      isProcessing = true;
      isLoading = true;
    });

    try {
      controller?.pauseCamera();
      var res =
          await Api().postData({'no_surat': qrCode}, '/undangan/kehadiran');
      var body = json.decode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200) {
        Msg.success(context, body['message'] ?? 'Kehadiran berhasil dicatat');
        Navigator.pop(context, true);
      } else {
        Msg.error(context, body['message'] ?? 'Presensi gagal');
        // Beri jeda sejenak sebelum kamera aktif kembali agar tidak langsung scan ulang
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          controller?.resumeCamera();
          setState(() {
            isProcessing = false;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Msg.error(context, 'Gagal terhubung ke server');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          controller?.resumeCamera();
          setState(() {
            isProcessing = false;
            isLoading = false;
          });
        }
      }
    }
  }

  void _requestPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return;
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }
    final result = await [Permission.camera].request();
    if (result[Permission.camera]!.isGranted) return;
  }

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  void _toggleFlashlight() async {
    try {
      await controller?.toggleFlash();
      final status = await controller?.getFlashStatus();
      setState(() {
        isFlashOn = status ?? !isFlashOn;
      });
    } catch (_) {}
  }

  void _flipCamera() async {
    try {
      await controller?.flipCamera();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 260.0
        : 320.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera QR View
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: primaryColor,
              borderRadius: 24,
              borderLength: 40,
              borderWidth: 6,
              cutOutSize: scanArea,
              overlayColor: Colors.black.withOpacity(0.65),
            ),
          ),

          // Top Header & Back Button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Scan Presensi Kehadiran",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Arahkan kamera ke QR Code rapat",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instruction Pill above scanning area
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        color: primaryColor, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      "Posisikan QR tepat di tengah bingkai",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls Dock
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Torch / Flash button
                      InkWell(
                        onTap: _toggleFlashlight,
                        borderRadius: BorderRadius.circular(50),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isFlashOn
                                    ? primaryColor
                                    : Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFlashOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: isFlashOn ? Colors.black : Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isFlashOn ? "Lampu Nyala" : "Lampu Mati",
                              style: TextStyle(
                                color: isFlashOn
                                    ? primaryColor
                                    : Colors.white.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withOpacity(0.15),
                      ),

                      // Flip Camera button
                      InkWell(
                        onTap: _flipCamera,
                        borderRadius: BorderRadius.circular(50),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flip_camera_ios_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Putar Kamera",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Presensi kehadiran tercatat otomatis setelah kode terbaca",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Loading Overlay during API verification
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Memverifikasi Presensi...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Mohon tunggu sebentar",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isProcessing && scanData.code != null && scanData.code!.isNotEmpty) {
        _handleAttendance(scanData.code!);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
