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

class LemburScreen extends StatefulWidget {
  final String title;

  const LemburScreen({super.key, required this.title});

  @override
  State<LemburScreen> createState() => _LemburScreenState();
}

class _LemburScreenState extends State<LemburScreen> {
  // Service Instances
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final LocationService _locationService = LocationService();
  final TextEditingController _kegiatanController = TextEditingController();

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
  String _statusMessage = "Memeriksa izin dan lokasi...";

  // Location Config (Will be updated from API)
  double _centerLat = -6.94159449034943;
  double _centerLng = 109.65221083435888;
  double _maxRadius = 100; // meters
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
    _kegiatanController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _checkPermissions();
      await _getBio();
      await _checkStatus();

      if (_lemburType == 'check_out' && mounted) {
        bool confirm = await _showConfirmDialog();
        if (!confirm) {
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      await _checkLocation();

      if (_isWithinLocation) {
        await _initializeCamera();
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
          _statusMessage = e.toString();
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
      if (e.toString().contains("Lokasi palsu")) rethrow;
      throw "Gagal mendapatkan lokasi: $e";
    }
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
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
      _startImageStream();
    }
  }

  void _startImageStream() {
    int frameCount = 0;
    _cameraController?.startImageStream((CameraImage image) async {
      frameCount++;
      if (frameCount % 10 != 0) return;
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

    bool challengePassed = false;
    switch (_livenessChallenge) {
      case 'blink':
        challengePassed = _faceDetectionService.detectBlink(face);
        break;
      case 'smile':
        challengePassed = _faceDetectionService.detectSmile(face);
        break;
    }

    if (challengePassed) {
      setState(() {
        _livenessPassed = true;
        _livenessInstruction = "Liveness Berhasil! Memproses...";
      });

      try {
        if (_cameraController != null &&
            _cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _takePictureAndSubmit();
        }
      } catch (e) {
        if (mounted) _takePictureAndSubmit();
      }
    } else {
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

  // Lembur State
  String _lemburType = 'check_in';
  String _endpoint = '/lembur/check-in';

  Future<void> _checkStatus() async {
    try {
      String statusPath =
          '/lembur/status?nik=${_bio['nik'] ?? box.read('nik')}';
      final response = await Api().getData(statusPath);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        if (data != null) {
          if (data['status'] == 'started') {
            setState(() {
              _lemburType = 'check_out';
              _endpoint = '/lembur/check-out';
            });
          }

          if (data['config'] != null) {
            _centerLat = data['config']['center_lat'] ?? _centerLat;
            _centerLng = data['config']['center_lng'] ?? _centerLng;
            _maxRadius = (data['config']['radius'] ?? _maxRadius).toDouble();
          }
        }
      }
    } catch (e) {
      print("Error checking status: $e");
    }
  }

  Future<void> _takePictureAndSubmit() async {
    // If check-out, Kegiatan is required
    if (_lemburType == 'check_out' && _kegiatanController.text.trim().isEmpty) {
      Msg.error(context, "Harap isi kegiatan lembur terlebih dahulu.");
      setState(() {
        _livenessPassed = false;
        _generateLivenessChallenge();
        _startImageStream();
      });
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      final File imageFile = File(image.path);

      if (mounted) {
        setState(() {
          _isLoading = true;
          _statusMessage = "Memverifikasi Wajah...";
          _livenessInstruction = "Mengirim data...";
        });
      }

      final body = {
        'nik': _bio['nik']?.toString() ?? box.read('nik')?.toString() ?? '',
        'latitude':
            _currentPosition?.latitude.toString() ?? _centerLat.toString(),
        'longitude':
            _currentPosition?.longitude.toString() ?? _centerLng.toString(),
        'kegiatan': _kegiatanController.text.trim(),
      };

      final response = await Api()
          .postMultipart(body, imageFile, _endpoint, fieldName: 'photo');
      final json = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Msg.success(context, json['message'] ?? "Berhasil!");
          Navigator.pop(context, true);
        }
      } else {
        throw json['message'] ?? "Gagal: ${response.statusCode}";
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Msg.error(context, "Gagal memproses: $e");
        setState(() {
          _livenessPassed = false;
          _generateLivenessChallenge();
          _startImageStream();
        });
      }
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: const Text("Konfirmasi"),
              content: const Text(
                  "Apakah Anda yakin ingin melakukan check-out presensi lembur?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child:
                      const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Ya, Close Presensi"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

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
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

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
              colors: [primaryColor, bgColor],
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
                      CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 30),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded,
                  size: 100, color: Colors.redAccent),
              const SizedBox(height: 20),
              Text(_statusMessage,
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _initialize, child: Text("Coba Lagi")),
            ],
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
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        _lemburType == 'check_in'
                            ? "Mulai Lembur"
                            : "Selesai Lembur",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on,
                          color: Colors.green, size: 16),
                    ],
                  ),
                ),
                if (_lemburType == 'check_out')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white24)),
                      child: TextField(
                        controller: _kegiatanController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Isi kegiatan lembur...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
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
                  child: Text(
                    !_isFaceDetected
                        ? "Wajah tidak terdeteksi"
                        : _livenessInstruction,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
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
