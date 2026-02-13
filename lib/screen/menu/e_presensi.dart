import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/services/face_detection_service.dart';
import 'package:rsia_employee_app/services/location_service.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class EPresensiScreen extends StatefulWidget {
  final String title;

  const EPresensiScreen({super.key, required this.title});

  @override
  State<EPresensiScreen> createState() => _EPresensiScreenState();
}

class _EPresensiScreenState extends State<EPresensiScreen> {
  // Service Instances
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final LocationService _locationService = LocationService();

  // Camera
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;

  // State
  bool _isProcessing = false;
  bool _isFaceDetected = false;
  String? _livenessChallenge;
  String _livenessInstruction = "Posisikan wajah Anda di dalam area";
  bool _livenessPassed = false;
  bool _isWithinLocation = false;
  bool _isLoading = true;
  bool _isCompleted = false; // Add completion flag
  String _statusMessage = "Memeriksa izin dan lokasi...";

  // Location Config
  static const double _centerLat = -6.94159449034943;
  static const double _centerLng = 109.65221083435888;
  static const double _maxRadius = 200; // meters
  Position? _currentPosition;

  // Timer for cooldown
  Timer? _detectionTimer;

  // Bio / Worker Data
  Map _bio = {};
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectionService.dispose();
    _detectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      // 1. Check Permissions
      await _checkPermissions();

      // 2. Get Bio / NIK
      await _getBio();

      // 3. Get Location & Validate
      await _checkLocation();

      // 4. Check Status (Determine Check-In or Check-Out)
      await _checkStatus();

      if (_isWithinLocation) {
        // 5. Initialize Camera
        await _initializeCamera();

        // 6. Start Liveness Flow
        setState(() {
          _isLoading = false;
          _statusMessage = "";
          _generateLivenessChallenge();
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Error: $e";
        });
      }
    }
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.location] != PermissionStatus.granted) {
      throw "Izin kamera dan lokasi diperlukan.";
    }
  }

  Future<void> _getBio() async {
    var res = await Api().getData("/pegawai/${box.read('sub')}");
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      if (mounted) {
        setState(() {
          _bio = body['data'];
        });
      }
    }
  }

  Future<void> _checkLocation() async {
    setState(() => _statusMessage = "Memeriksa lokasi...");
    try {
      _currentPosition = await _locationService.getCurrentPosition();

      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _centerLat,
        _centerLng,
      );

      if (mounted) {
        setState(() {
          _isWithinLocation = distance <= _maxRadius;
          if (!_isWithinLocation) {
            _statusMessage =
                "Jarak Anda ${(distance).toInt()}m dari kantor. Maksimal ${_maxRadius.toInt()}m.";
          }
        });
      }
    } catch (e) {
      throw "Gagal mendapatkan lokasi: $e";
    }
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    // Default to front camera
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
      // Start Image Stream
      _startImageStream();
    }
  }

  void _startImageStream() {
    // Process every 500ms to avoid lag
    int frameCount = 0;
    _cameraController?.startImageStream((CameraImage image) async {
      frameCount++;
      if (frameCount % 10 != 0) return; // Process every ~10th frame
      if (_isProcessing || _livenessPassed) return;

      _isProcessing = true;
      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) return;

        final faces = await _faceDetectionService.processImage(inputImage);

        if (mounted) {
          await _processFaces(faces);
        }
      } catch (e) {
        print("Error processing image: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _processFaces(List<Face> faces) async {
    if (_livenessPassed) return;

    if (faces.isEmpty) {
      setState(() {
        _isFaceDetected = false;
        _livenessInstruction = "Wajah tidak terdeteksi";
      });
      return;
    }

    if (faces.length > 1) {
      setState(() {
        _isFaceDetected = false;
        _livenessInstruction = "Hanya satu wajah diperbolehkan";
      });
      return;
    }

    Face face = faces.first;
    setState(() => _isFaceDetected = true);

    // Liveness Logic
    bool challengePassed = false;

    switch (_livenessChallenge) {
      case 'blink':
        challengePassed = _faceDetectionService.detectBlink(face);
        break;
      case 'smile':
        challengePassed = _faceDetectionService.detectSmile(face);
        break;
      // Add more cases if needed
    }

    if (challengePassed) {
      setState(() {
        _livenessPassed = true;
        _livenessInstruction = "Liveness Berhasil! Memproses...";
      });

      // Stop stream and take confirmation picture
      try {
        if (_cameraController != null &&
            _cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }

        // Give the camera hardware a short break to transition from stream to photo
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          _takePictureAndSubmit();
        }
      } catch (e) {
        print("Error stopping stream: $e");
        if (mounted) {
          _takePictureAndSubmit(); // Try anyway
        }
      }
    } else {
      // Update instruction based on challenge
      String instruction = "";
      if (_livenessChallenge == 'blink') instruction = "Silakan KEDIPKAN MATA";
      if (_livenessChallenge == 'smile') instruction = "Silakan TERSENYUM";

      setState(() => _livenessInstruction = instruction);
    }
  }

  void _generateLivenessChallenge() {
    final challenges = ['blink', 'smile'];
    _livenessChallenge = challenges[Random().nextInt(challenges.length)];
  }

  // Presensi State
  String _presensiType = 'masuk'; // masuk, pulang
  String _endpoint = '/presensi-online/check-in';

  Future<void> _checkStatus() async {
    try {
      String statusPath = '/presensi-online/status';
      if (_bio.isNotEmpty && _bio['nik'] != null) {
        statusPath += "?nik=${_bio['nik']}";
      }

      final response = await Api().getData(statusPath);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final data = body['data'];
        if (data != null && data['status'] != null) {
          final status = data['status'];

          if (status == 'checked_in') {
            // Already checked in, next action is check-out
            setState(() {
              _presensiType = 'pulang';
              _endpoint = '/presensi-online/check-out';
            });
          } else if (status == 'checked_out') {
            // Already completed for today
            setState(() {
              _statusMessage = "Anda sudah menyelesaikan presensi hari ini.";
              _isWithinLocation = false; // Prevent camera start
              _isCompleted = true; // Set completed flag
            });
          }
          // else status == 'none', default is check-in (already set)
        }
      }
    } catch (e) {
      print("Error checking status: $e");
    }
  }

  Future<void> _takePictureAndSubmit() async {
    try {
      final XFile image = await _cameraController!.takePicture();
      final File imageFile = File(image.path);

      if (mounted) {
        setState(() {
          _isLoading = true; // Use the full-screen loading overlay
          _statusMessage = "Memverifikasi Wajah...";
          _livenessInstruction = "Mengirim data...";
        });
      }

      final body = {
        'nik': _bio['nik']?.toString() ?? '',
        'type': _presensiType == 'masuk' ? 'check_in' : 'check_out',
        'latitude':
            _currentPosition?.latitude.toString() ?? _centerLat.toString(),
        'longitude':
            _currentPosition?.longitude.toString() ?? _centerLng.toString(),
        'accuracy': _currentPosition?.accuracy.toString() ?? '0',
      };

      final response = await Api()
          .postMultipart(body, imageFile, _endpoint, fieldName: 'photo');
      final json = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          String message = json['message'] ?? "Presensi Berhasil!";

          // Check if this was first-time registration
          if (json['first_time'] == true) {
            message = "Wajah berhasil didaftarkan!\n$message";
          }

          Msg.success(context, message);
          Navigator.pop(context, true); // Return true to refresh prev screen
        }
      } else {
        throw json['message'] ?? "Gagal: ${response.statusCode}";
      }
    } catch (e) {
      if (mounted) {
        Msg.error(context, "Gagal memproses: $e");

        // Reset state to retry
        setState(() {
          _livenessPassed = false;
          _generateLivenessChallenge();
          _startImageStream();
        });
      }
    }
  }

  // Helper to convert CameraImage to InputImage (Generic boilerplate)
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor,
                bgColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Mohon tunggu sebentar...",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isWithinLocation) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor,
                bgColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.location_off_rounded,
                            size: 100,
                            color:
                                _isCompleted ? Colors.green : Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _isCompleted
                              ? "Presensi Selesai"
                              : "Peringatan Lokasi",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 50),
                        if (!_isCompleted) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _initialize,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: primaryColor.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Coba Lagi",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Kembali",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: primaryColor.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Kembali",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview with Scaling Fix
          ClipRect(
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          ),

          // 2. Overlay & Instruction
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Dalam Area",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Face / Liveness Status
                Container(
                  margin: const EdgeInsets.only(bottom: 50),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _livenessPassed
                        ? Colors.green.withOpacity(0.8)
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isFaceDetected)
                        const Text(
                          "Wajah tidak terdeteksi",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        )
                      else if (_livenessPassed)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Verifikasi Berhasil",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Text(
                              _livenessInstruction,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            if (_livenessChallenge != null)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  "(Ikuti instruksi di atas)",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14),
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
        ],
      ),
    );
  }
}
