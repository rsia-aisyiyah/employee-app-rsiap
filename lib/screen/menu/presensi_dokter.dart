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
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/services/face_detection_service.dart';
import 'package:rsia_employee_app/services/location_service.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class PresensiDokter extends StatefulWidget {
  const PresensiDokter({super.key});

  @override
  State<PresensiDokter> createState() => _PresensiDokterState();
}

class _PresensiDokterState extends State<PresensiDokter> {
  // Service Instances
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final LocationService _locationService = LocationService();

  // Camera
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;

  // State
  bool _isLoading = true;
  bool _isScheduleSelected = false;
  bool _isProcessing = false;
  bool _isFaceDetected = false;
  String? _livenessChallenge;
  String _livenessInstruction = "Posisikan wajah Anda di dalam area";
  bool _livenessPassed = false;
  bool _isWithinLocation = false;
  bool _isCompleted = false;
  bool _isJadwalTambahan = false;
  String _statusMessage = "Memeriksa data...";

  // Schedule State
  List _shifts = [];
  String? _todayShift;

  // Location Config
  static const double _centerLat = -6.94159449034943;
  static const double _centerLng = 109.65221083435888;
  static const double _maxRadius = 100; // meters
  Position? _currentPosition;

  // User Data
  Map _bio = {};
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _fetchShiftsAndData();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }

  Future<void> _fetchShiftsAndData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get Bio
      await _getBio();

      // 2. Fetch Shifts
      var shiftRes = await Api().getData('/sdi/shifts');
      if (shiftRes.statusCode == 200) {
        var body = json.decode(shiftRes.body);
        _shifts = body['data'] ?? [];
      }

      // 3. Check Today's Schedule
      DateTime now = DateTime.now();
      String statusPath =
          '/sdi/jadwal-pegawai?bulan=${now.month}&tahun=${now.year}&nik=${box.read('sub')}';
      var scheduleRes = await Api().getData(statusPath);

      if (scheduleRes.statusCode == 200) {
        var body = json.decode(scheduleRes.body);
        var data = body['data'];
        if (data != null && data.isNotEmpty) {
          var empData = data[0];
          String dayKey = 'h${now.day}';
          if (empData['jadwal'] != null && empData['jadwal'][dayKey] != null) {
            String existingShift = empData['jadwal'][dayKey];
            if (existingShift.isNotEmpty && existingShift != '-') {
              _todayShift = existingShift;
              _isScheduleSelected = true;
            }
          }
        }
      }

      // 4. Check Presence Status (Determine if already checked in/out)
      await _checkPresenceStatus();

      // If schedule is already selected, proceed to camera initialization
      if (_isScheduleSelected && !_isCompleted) {
        await _startPresenceFlow();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Gagal memuat data: $e";
        });
      }
    }
  }

  Future<void> _getBio() async {
    final box = GetStorage();
    String? nik = box.read('sub');

    try {
      // Fetch from jadwal-pegawai to get the integer 'id' used by the database
      var res = await Api().getData("/sdi/jadwal-pegawai?nik=$nik");
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (body['success'] == true && body['data'].isNotEmpty) {
          if (mounted) {
            setState(() {
              _bio = body['data'][0];
            });
          }
        } else {
          // Fallback to regular profile if not found in jadwal-pegawai
          final response = await Api().getData('/pegawai/$nik');
          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final data = body['data'];
            if (mounted) {
              setState(() {
                _bio = data;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching bio: $e");
      if (mounted) {
        setState(() {
          _statusMessage = "Gagal memuat profil: $e";
        });
      }
    }
  }

  Future<void> _checkPresenceStatus() async {
    try {
      String nik = box.read('sub')?.toString() ?? '';
      String statusPath = '/presensi-online/status?nik=$nik';
      final response = await Api().getData(statusPath);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        if (data != null && data['status'] != null) {
          final status = data['status'];
          if (status == 'checked_in') {
            _presensiType = 'pulang';
            _endpoint = '/presensi-online/check-out';
          } else if (status == 'checked_out') {
            if (!_isJadwalTambahan) {
              setState(() {
                _isScheduleSelected = false;
                _todayShift = null;
              });
              _showJadwalTambahanConfirmation();
            } else {
              _isCompleted = true;
              _statusMessage = "Anda sudah menyelesaikan presensi hari ini.";
            }
          }
        }
      }
    } catch (e) {
      print("Error checking presence status: $e");
    }
  }

  void _showJadwalTambahanConfirmation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: primaryColor),
              const SizedBox(width: 8),
              const Text("Presensi Dokter"),
            ],
          ),
          content: const Text(
              "Sudah ada data presensi hari ini.\n\nApakah Anda akan masuk jadwal tambahan?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isCompleted = true;
                  _statusMessage =
                      "Anda sudah menyelesaikan presensi hari ini.";
                });
              },
              child: const Text("Tidak"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForJadwalTambahan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Ya, Tambahan",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }

  void _resetForJadwalTambahan() {
    setState(() {
      _isJadwalTambahan = true;
      _isScheduleSelected = false;
      _todayShift = null;
      _isLoading = false;
      _presensiType = 'masuk';
      _endpoint = '/presensi-online/check-in';
    });
  }

  // Preservation Flow
  String _presensiType = 'masuk';
  String _endpoint = '/presensi-online/check-in';

  Future<void> _startPresenceFlow() async {
    setState(() => _isLoading = true);
    try {
      await _checkPermissions();
      await _checkLocation();

      if (_isWithinLocation) {
        await _initializeCamera();
        _generateLivenessChallenge();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = e.toString();
      });
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

  Future<void> _checkLocation() async {
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

  // --- UI Rendering ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScaffold();
    }

    if (_isCompleted) {
      return _buildMessageScaffold(Icons.check_circle_rounded,
          "Presensi Selesai", _statusMessage, Colors.green);
    }

    if (!_isScheduleSelected) {
      return _buildScheduleSelectionScreen();
    }

    if (!_isWithinLocation) {
      return _buildMessageScaffold(Icons.location_off_rounded,
          "Peringatan Lokasi", _statusMessage, Colors.redAccent);
    }

    return _buildFaceScanScreen();
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, bgColor],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
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
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageScaffold(
      IconData icon, String title, String message, Color color) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.4),
                  bgColor,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom Header (Instead of AppBar)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        "Presensi Dokter",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                          border:
                              Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon with decorative background
                            Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 70, color: color),
                            ),
                            const SizedBox(height: 30),

                            // Title
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Message
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Actions
                            if (icon == Icons.location_off_rounded)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    )
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _startPresenceFlow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    "Coba Lagi",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                ),
                                child: Text(
                                  "Kembali",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSelectionScreen() {
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isJadwalTambahan
                        ? "Pilih Jadwal Tambahan"
                        : "Pilih Jadwal Kerja",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isJadwalTambahan
                        ? "Anda masuk dalam mode jadwal tambahan. Silakan pilih shift yang sesuai."
                        : "Silakan pilih shift Anda untuk hari ini agar dapat melanjutkan presensi.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  var shift = _shifts[index];
                  return _buildShiftCard(shift);
                },
                childCount: _shifts.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                primaryColor.withBlue(210).withGreen(180),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                )
                              ],
                              color: Colors.white24,
                            ),
                            child: ClipOval(
                              child: _bio['photo'] != null
                                  ? Image.network(
                                      AppConfig.photoUrl + _bio['photo'],
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorBuilder: (c, e, s) => const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 40),
                                    )
                                  : const Icon(Icons.person,
                                      color: Colors.white, size: 40),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _bio['nama'] ?? "Dokter",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _bio['nik'] ?? "-",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE', 'id_ID')
                                    .format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                DateFormat('d MMMM yyyy', 'id_ID')
                                    .format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.medical_information,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  "Presensi Dokter",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildShiftCard(Map shift) {
    String shiftName = shift['shift'].toString().toLowerCase();
    Color cardColor;
    IconData shiftIcon;
    List<Color> gradient;

    if (shiftName.contains('pagi')) {
      cardColor = Colors.orange;
      shiftIcon = Icons.wb_sunny_rounded;
      gradient = [
        Colors.orange[400]!.withOpacity(0.1),
        Colors.orange[600]!.withOpacity(0.1)
      ];
    } else if (shiftName.contains('siang') || shiftName.contains('sore')) {
      cardColor = Colors.blue;
      shiftIcon = Icons.wb_cloudy_rounded;
      gradient = [
        Colors.blue[400]!.withOpacity(0.1),
        Colors.blue[600]!.withOpacity(0.1)
      ];
    } else if (shiftName.contains('malam')) {
      cardColor = Colors.indigo;
      shiftIcon = Icons.nightlight_round;
      gradient = [
        Colors.indigo[400]!.withOpacity(0.1),
        Colors.indigo[800]!.withOpacity(0.1)
      ];
    } else {
      cardColor = primaryColor;
      shiftIcon = Icons.access_time_filled_rounded;
      gradient = [
        primaryColor.withOpacity(0.1),
        primaryColor.withBlue(200).withOpacity(0.1)
      ];
    }

    return InkWell(
      onTap: () => _saveSchedule(shift),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative background icon
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  shiftIcon,
                  size: 70,
                  color: cardColor.withOpacity(0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(shiftIcon, color: cardColor, size: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift['shift'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              "${(shift['jam_masuk'] ?? '00:00:00').split(':').take(2).join(':')} - ${(shift['jam_pulang'] ?? '00:00:00').split(':').take(2).join(':')}",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Future<void> _saveSchedule(Map shift) async {
    setState(() => _isLoading = true);
    try {
      DateTime now = DateTime.now();
      String empId = (_bio['id'] ?? '').toString();

      if (empId.isEmpty || empId == 'null') {
        // Final attempt to get ID if missing
        await _getBio();
        empId = (_bio['id'] ?? '').toString();
      }

      if (empId.isEmpty || empId == 'null') {
        throw "Data ID Karyawan tidak ditemukan (NIK: ${box.read('sub')}). Silahkan restart aplikasi atau hubungi IT.";
      }

      Map<String, dynamic> payload = {
        "bulan": now.month,
        "tahun": now.year,
        "data": [
          {
            "id": empId,
            "h${now.day}": shift['shift'],
          }
        ]
      };

      var res = await Api().postData(
          payload,
          _isJadwalTambahan
              ? '/sdi/jadwal-tambahan/admin'
              : '/sdi/jadwal-pegawai/admin');
      if (res.statusCode == 200) {
        setState(() {
          _todayShift = shift['shift'];
          _isScheduleSelected = true;
        });
        await _startPresenceFlow();
      } else {
        var body = json.decode(res.body);
        throw body['message'] ?? "Gagal menyimpan jadwal";
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMsg = e.toString();
        if (errorMsg.isEmpty)
          errorMsg = "Terjadi kesalahan sistem (Empty Error)";
        Msg.error(context, errorMsg);
      }
    }
  }

  Widget _buildFaceScanScreen() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _presensiType == 'masuk'
                                  ? "Check In"
                                  : "Check Out",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            if (_todayShift != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _todayShift!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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
                    style: const TextStyle(
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

  // --- Liveness & Stream Logic (Reused from EPresensi) ---

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
        if (mounted) await _processFaces(faces);
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
        _livenessInstruction = "Verifikasi Berhasil! Memproses...";
      });

      try {
        if (_cameraController != null &&
            _cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _takePictureAndSubmit();
      } catch (e) {
        if (mounted) _takePictureAndSubmit();
      }
    } else {
      String instruction = _livenessChallenge == 'blink'
          ? "Silakan KEDIPKAN MATA"
          : "Silakan TERSENYUM";
      setState(() => _livenessInstruction = instruction);
    }
  }

  void _generateLivenessChallenge() {
    final challenges = ['blink', 'smile'];
    _livenessChallenge = challenges[Random().nextInt(challenges.length)];
  }

  Future<void> _takePictureAndSubmit() async {
    try {
      final XFile image = await _cameraController!.takePicture();
      final File imageFile = File(image.path);

      if (mounted) {
        setState(() {
          _isLoading = true;
          _statusMessage = "Memverifikasi Wajah...";
        });
      }

      final body = {
        'nik': box.read('sub')?.toString() ?? '',
        'latitude':
            _currentPosition?.latitude.toString() ?? _centerLat.toString(),
        'longitude':
            _currentPosition?.longitude.toString() ?? _centerLng.toString(),
        'is_tambahan': _isJadwalTambahan ? 'true' : 'false',
      };

      final response = await Api()
          .postMultipart(body, imageFile, _endpoint, fieldName: 'photo');
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Msg.success(context, jsonData['message'] ?? "Presensi Berhasil!");
          Navigator.pop(context, true);
        }
      } else {
        throw jsonData['message'] ?? "Gagal: ${response.statusCode}";
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
}
