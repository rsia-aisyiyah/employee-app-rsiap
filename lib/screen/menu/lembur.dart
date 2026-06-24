import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

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

class _LemburScreenState extends State<LemburScreen> with SingleTickerProviderStateMixin {
  // Service Instances
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final LocationService _locationService = LocationService();
  final TextEditingController _kegiatanController = TextEditingController();

  // Animation
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  // Camera
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;

  // State
  bool _isProcessing = false;
  bool _isFaceDetected = false;
  String? _livenessChallenge;
  String _livenessInstruction = "Posisikan wajah Anda di dalam bingkai";
  bool _livenessPassed = false;
  bool _isWithinLocation = false;
  bool _isLoading = true;
  String _statusMessage = "Memeriksa izin dan lokasi...";

  bool _isFaceInPosition = false;
  final Rect _targetRect = Rect.fromCenter(
    center: const Offset(0.5, 0.45),
    width: 0.65,
    height: 0.45,
  );

  // Location Config (Will be updated from API)
  double _centerLat = -6.941626450136709;
  double _centerLng = 109.65246501663937;
  double _maxRadius = 30; // meters
  Position? _currentPosition;

  // Timer for cooldown
  Timer? _detectionTimer;

  // Bio / Worker Data
  Map _bio = {};
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    _initialize();
  }

  @override
  void dispose() {
    _scanController.dispose();
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
        if (inputImage == null || inputImage.metadata == null) return;

        final faces = await _faceDetectionService.processImage(inputImage);

        if (mounted) {
          await _processFaces(faces, inputImage.metadata!.size);
        }
      } catch (e) {
        print("Error processing image: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _processFaces(List<Face> faces, Size imageSize) async {
    if (_livenessPassed) return;

    if (faces.isEmpty) {
      setState(() {
        _isFaceDetected = false;
        _isFaceInPosition = false;
        _livenessInstruction = "Posisikan wajah Anda di dalam bingkai";
      });
      return;
    }

    if (faces.length > 1) {
      setState(() {
        _isFaceDetected = false;
        _isFaceInPosition = false;
        _livenessInstruction = "Hanya satu wajah diperbolehkan";
      });
      return;
    }

    Face face = faces.first;
    setState(() => _isFaceDetected = true);

    final faceRect = face.boundingBox;
    final double nx = faceRect.left / imageSize.width;
    final double ny = faceRect.top / imageSize.height;
    final double nw = faceRect.width / imageSize.width;
    final double nh = faceRect.height / imageSize.height;
    final Rect normalizedFace = Rect.fromLTWH(nx, ny, nw, nh);

    final bool isInPosition = _targetRect.contains(normalizedFace.center) &&
        normalizedFace.width > 0.25 && 
        normalizedFace.height > 0.25;

    if (isInPosition != _isFaceInPosition) {
      setState(() {
        _isFaceInPosition = isInPosition;
        if (isInPosition) {
          String instruction = "";
          if (_livenessChallenge == 'blink') instruction = "Silakan KEDIPKAN MATA";
          if (_livenessChallenge == 'smile') instruction = "Silakan TERSENYUM";
          _livenessInstruction = instruction;
        } else {
          _livenessInstruction = "Posisikan wajah Anda di dalam bingkai";
        }
      });
    }

    if (isInPosition) {
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
      }
    } else {
      setState(() {
        _livenessInstruction = "Posisikan wajah Anda di dalam bingkai";
      });
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.close, color: primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  size: 100,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Di Luar Jangkauan",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(32),
                child: ElevatedButton(
                  onPressed: _initialize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Coba Lagi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: FaceOverlayPainter(
                    isFaceInPosition: _isFaceInPosition,
                    targetRect: _targetRect,
                    scanLineY: _scanAnimation.value,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildInstructionCard(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 8),
                const SizedBox(width: 10),
                Text(
                  _lemburType == 'check_in' ? "MULAI LEMBUR" : "SELESAI LEMBUR",
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKegiatanInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _kegiatanController,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            hintText: "Isi kegiatan lembur...",
            hintStyle: TextStyle(color: Colors.black38, fontWeight: FontWeight.normal),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: _isFaceInPosition ? Colors.green.shade400 : Colors.black12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFaceInPosition
                ? Colors.green.withOpacity(0.15)
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_isFaceInPosition ? Colors.green : Colors.blue).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _livenessPassed ? "MEMPROSES" : "VERIFIKASI WAJAH",
                    style: TextStyle(
                      color: _isFaceInPosition ? Colors.green.shade700 : Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  !_isFaceDetected ? "Posisikan wajah Anda di dalam bingkai" : _livenessInstruction,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  final bool isFaceInPosition;
  final Rect targetRect;
  final double scanLineY;

  FaceOverlayPainter({required this.isFaceInPosition, required this.targetRect, this.scanLineY = 0});

  Path _getFacePath(Rect rect) {
    final double w = rect.width;
    final double h = rect.height;
    final double x = rect.left;
    final double y = rect.top;

    final path = Path();
    // Start at top center of the oval
    path.moveTo(x + w * 0.5, y);

    // Top-right curve (forehead)
    path.cubicTo(
      x + w * 0.85, y,
      x + w * 0.98, y + h * 0.22,
      x + w * 0.95, y + h * 0.48,
    );

    // Bottom-right curve (jawline)
    path.cubicTo(
      x + w * 0.90, y + h * 0.72,
      x + w * 0.72, y + h * 1.0,
      x + w * 0.50, y + h * 1.0,
    );

    // Bottom-left curve (jawline)
    path.cubicTo(
      x + w * 0.28, y + h * 1.0,
      x + w * 0.10, y + h * 0.72,
      x + w * 0.05, y + h * 0.48,
    );

    // Top-left curve (forehead)
    path.cubicTo(
      x + w * 0.02, y + h * 0.22,
      x + w * 0.15, y,
      x + w * 0.50, y,
    );

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * targetRect.width;
    final center = Offset(size.width * targetRect.center.dx, size.height * targetRect.center.dy);
    // Lock aspect ratio to 1:1.25 (width:height) to prevent stretching on tall screen devices
    final frameHeight = frameWidth * 1.25;
    final frameRect = Rect.fromCenter(center: center, width: frameWidth, height: frameHeight);
    
    final facePath = _getFacePath(frameRect);

    // Background mask (solid white)
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        facePath,
      ),
      bgPaint,
    );

    // Subtle glow if face in position
    if (isFaceInPosition) {
      final glowPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(facePath, glowPaint);
    }

    // Border
    final borderPaint = Paint()
      ..color = isFaceInPosition ? Colors.greenAccent : Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(facePath, borderPaint);

    // Modern Scan Beam (Gradient Light) clipped inside the face outline
    if (isFaceInPosition) {
      final currentY = frameRect.top + (frameRect.height * scanLineY);
      final beamHeight = 40.0;
      final beamRect = Rect.fromLTRB(frameRect.left, currentY - beamHeight, frameRect.right, currentY);
      
      final beamPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, currentY - beamHeight), Offset(0, currentY),
          [Colors.greenAccent.withOpacity(0), Colors.greenAccent.withOpacity(0.4)],
        );
      
      canvas.save();
      canvas.clipPath(facePath);
      canvas.drawRect(beamRect.intersect(frameRect), beamPaint);
      
      // Stronger line at the bottom of beam
      canvas.drawLine(
        Offset(frameRect.left, currentY),
        Offset(frameRect.right, currentY),
        Paint()
          ..color = Colors.greenAccent
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) => true;
}
