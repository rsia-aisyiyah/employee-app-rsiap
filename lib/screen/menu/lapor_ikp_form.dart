import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class LaporIkpFormScreen extends StatefulWidget {
  final Map? existingData;
  const LaporIkpFormScreen({super.key, this.existingData});

  @override
  State<LaporIkpFormScreen> createState() => _LaporIkpFormScreenState();
}

class _LaporIkpFormScreenState extends State<LaporIkpFormScreen> {
  int _currentStep = 1;
  bool isLoading = false;
  bool isSearchingPasien = false;
  bool isPasien = true; // true if victim is a patient, false if non-patient

  // Master Data
  List masterJenisInsiden = [];
  List masterUnits = [];

  // Step 1: Patient & Time Info
  final TextEditingController _searchPasienController = TextEditingController();
  List searchResults = [];
  Map? selectedPasien;

  final TextEditingController _nmPasienController = TextEditingController();
  final TextEditingController _noRmController = TextEditingController();
  final TextEditingController _tglLahirController = TextEditingController();
  String? selectedJk;

  DateTime? tglPasienMasuk;
  DateTime? tglInsiden;
  TimeOfDay? waktuInsiden;

  // Option Mappings matching backend/Filament schema
  final Map<String, String> jenisPelaporOptions = {
    'karyawan': 'Karyawan (Dokter, Perawat, dll)',
    'pengunjung': 'Pengunjung',
    'pasien': 'Pasien',
    'keluarga': 'Keluarga / Pendamping Pasien',
    'lainnya': 'Lainnya',
  };

  final Map<String, String> korbanInsidenOptions = {
    'pasien': 'Pasien',
    'lainnya': 'Lainnya',
  };

  final Map<String, String> layananInsidenOptions = {
    'ranap': 'Rawat Inap',
    'ralan': 'Rawat Jalan',
    'ugd': 'UGD / IGD',
    'lainnya': 'Lainnya',
  };

  final Map<String, String> kasusOptions = {
    'Penyakit-Dalam-dan-Subspesialiasinya': 'Penyakit Dalam dan Subspesialiasinya',
    'Anak-dan-Subspesialiasinya': 'Anak dan Subspesialiasinya',
    'Bedah-dan-Subspesialiasinya': 'Bedah dan Subspesialiasinya',
    'Obstetri-Gynekologi-dan-Subspesialiasinya': 'Obstetri Gynekologi dan Subspesialiasinya',
    'THT-dan-Subspesialiasinya': 'THT dan Subspesialiasinya',
    'Mata-dan-Subspesialiasinya': 'Mata dan Subspesialiasinya',
    'Saraf-dan-Subspesialiasinya': 'Saraf dan Subspesialiasinya',
    'Anastesi-dan-Subspesialiasinya': 'Anastesi dan Subspesialiasinya',
    'Kulit-Kelamin-dan-Subspesialiasinya': 'Kulit & Kelamin dan Subspesialiasinya',
    'Jantung-dan-Subspesialiasinya': 'Jantung dan Subspesialiasinya',
    'Paru-dan-Subspesialiasinya': 'Paru dan Subspesialiasinya',
    'Jiwa-dan-Subspesialiasinya': 'Jiwa dan Subspesialiasinya',
    'Orthopedi-dan-Subspesialiasinya': 'Orthopedi dan Subspesialiasinya'
  };

  // Step 2: Incident Details
  int? selectedJenisInsidenId;
  final TextEditingController _insidenController = TextEditingController();
  final TextEditingController _kronologiController = TextEditingController();
  final TextEditingController _tempatController = TextEditingController();
  int? selectedUnitId;
  String selectedJenisPelapor = 'karyawan';
  String? selectedJenisPelaporLainnya;
  String selectedKorbanInsiden = 'pasien';
  String? selectedKorbanInsidenLainnya;
  String selectedLayananInsiden = 'ranap';
  String? selectedLayananInsidenLainnya;
  List<String> selectedKasusInsiden = [];
  String? selectedKasusInsidenLainnya;

  // Step 3: Severity & Action
  String? selectedDampak; // tidak signifikan, minor, moderat, mayor, katastropik
  int pernahTerjadi = 0; // 0: Tidak, 1: Ya
  String selectedStatusPelapor = 'Staf'; // Staf, Pj, Koor
  final TextEditingController _tindakanController = TextEditingController();
  String tindakanOleh = 'Petugas'; // Petugas, Tim
  final TextEditingController _tindakanOlehDetailController = TextEditingController();
  String? selectedGradingRisiko; // Biru, Hijau, Kuning, Merah

  // Auto grading state variables
  String? autoGradingValue; // biru, hijau, kuning, merah
  String? autoGradingLabel; // Rendah, Moderat, Tinggi, Ekstrim
  bool isCalculatingGrading = false;

  String _mapWarnaToGrading(String? warna) {
    if (warna == 'biru') return 'Biru';
    if (warna == 'hijau') return 'Hijau';
    if (warna == 'kuning') return 'Kuning';
    if (warna == 'merah') return 'Merah';
    return 'Biru';
  }

  @override
  void initState() {
    super.initState();
    _fetchMasterData().then((_) {
      if (widget.existingData != null) {
        _prepopulateForm();
      }
    });
  }

  @override
  void dispose() {
    _searchPasienController.dispose();
    _nmPasienController.dispose();
    _noRmController.dispose();
    _tglLahirController.dispose();
    _insidenController.dispose();
    _kronologiController.dispose();
    _tempatController.dispose();
    _tindakanController.dispose();
    _tindakanOlehDetailController.dispose();
    super.dispose();
  }

  void _prepopulateForm() {
    if (widget.existingData == null) return;
    final data = widget.existingData!;

    setState(() {
      // Step 1: Patient info & date
      _noRmController.text = data['pasien_id'] == '000000' ? '' : (data['pasien_id'] ?? '');
      _nmPasienController.text = data['nm_pasien'] ?? '';
      _tglLahirController.text = data['tgl_lahir'] ?? '';
      selectedJk = data['jk'] ?? 'L';

      if (data['tgl_pasien_masuk'] != null) {
        tglPasienMasuk = DateTime.parse(data['tgl_pasien_masuk']);
      }
      if (data['tanggal_insiden'] != null) {
        tglInsiden = DateTime.parse(data['tanggal_insiden']);
      }
      if (data['waktu_insiden'] != null) {
        final parts = data['waktu_insiden'].toString().split(':');
        if (parts.length >= 2) {
          waktuInsiden = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }

      isPasien = _noRmController.text.isNotEmpty;

      // Step 2: Details
      selectedJenisInsidenId = int.tryParse(data['jenis_insiden_id']?.toString() ?? '');
      _insidenController.text = data['insiden'] ?? '';
      _kronologiController.text = data['kronologi'] ?? '';

      selectedJenisPelapor = data['jenis_pelapor'] ?? 'karyawan';
      selectedJenisPelaporLainnya = data['jenis_pelapor_lainnya'];

      selectedKorbanInsiden = data['korban_insiden'] ?? 'pasien';
      selectedKorbanInsidenLainnya = data['korban_insiden_lainnya'];

      selectedLayananInsiden = data['layanan_insiden'] ?? 'ranap';
      selectedLayananInsidenLainnya = data['layanan_insiden_lainnya'];

      if (data['kasus_insiden'] != null) {
        if (data['kasus_insiden'] is String) {
          try {
            selectedKasusInsiden = List<String>.from(json.decode(data['kasus_insiden']));
          } catch (e) {
            selectedKasusInsiden = [];
          }
        } else if (data['kasus_insiden'] is List) {
          selectedKasusInsiden = List<String>.from(data['kasus_insiden']);
        }
      }
      selectedKasusInsidenLainnya = data['kasus_insiden_lainnya'];

      _tempatController.text = data['tempat_kejadian'] ?? '';
      selectedUnitId = int.tryParse(data['unit_id']?.toString() ?? '');

      // Step 3: Action & Severity
      selectedDampak = data['dampak_insiden'];
      pernahTerjadi = int.tryParse(data['pernah_terjadi']?.toString() ?? '0') ?? 0;
      selectedStatusPelapor = data['status_pelapor'] ?? 'Staf';

      _tindakanController.text = data['tindakan_insiden'] ?? '';
      tindakanOleh = data['tindakan_oleh'] ?? 'Petugas';
      _tindakanOlehDetailController.text = data['tindakan_detail'] ?? '';
      selectedGradingRisiko = _mapWarnaToGrading(data['grading_risiko']?.toString().toLowerCase());
    });

    _fetchAutoGrading();
  }

  Future<void> _fetchMasterData() async {
    setState(() => isLoading = true);
    try {
      var res = await Api().getData('/sdi/ikp/master-data');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        setState(() {
          masterJenisInsiden = body['data']['jenis_insiden'] ?? [];
          masterUnits = body['data']['units'] ?? [];
        });
      } else {
        Msg.error(context, "Gagal mengambil data master IKP");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan koneksi master data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAutoGrading() async {
    if (selectedJenisInsidenId == null || selectedUnitId == null || selectedDampak == null) {
      return;
    }

    setState(() {
      isCalculatingGrading = true;
      autoGradingValue = null;
      autoGradingLabel = null;
    });

    try {
      var queryParams = "?jenis_insiden_id=$selectedJenisInsidenId&unit_id=$selectedUnitId&dampak_insiden=${Uri.encodeComponent(selectedDampak!)}";
      var res = await Api().getData('/sdi/ikp/grading$queryParams');
      
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (body['success'] == true) {
          setState(() {
            autoGradingValue = body['data']['warna']; // biru, hijau, kuning, merah
            autoGradingLabel = body['data']['grading']; // Rendah, Moderat, Tinggi, Ekstrim
            selectedGradingRisiko = _mapWarnaToGrading(body['data']['warna']);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching auto grading: $e");
    } finally {
      if (mounted) {
        setState(() {
          isCalculatingGrading = false;
        });
      }
    }
  }

  Future<void> _searchPasien(String query) async {
    if (query.length < 3) {
      setState(() => searchResults = []);
      return;
    }

    setState(() => isSearchingPasien = true);
    try {
      var res = await Api().getData('/sdi/ikp/pasien/search?keyword=${Uri.encodeComponent(query)}');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        setState(() {
          searchResults = body['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Gagal mencari pasien: $e");
    } finally {
      setState(() => isSearchingPasien = false);
    }
  }

  void _selectPasien(Map pasien) {
    setState(() {
      selectedPasien = pasien;
      _noRmController.text = pasien['no_rkm_medis'] ?? '';
      _nmPasienController.text = pasien['nm_pasien'] ?? '';
      _tglLahirController.text = pasien['tgl_lahir'] ?? '';
      selectedJk = pasien['jk'] == 'L' ? 'L' : 'P';
      searchResults = [];
      _searchPasienController.clear();
    });
  }

  Future<void> _pickDate(bool isMasuk) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMasuk) {
          tglPasienMasuk = picked;
        } else {
          tglInsiden = picked;
        }
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        waktuInsiden = picked;
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_nmPasienController.text.isEmpty ||
          _tglLahirController.text.isEmpty ||
          selectedJk == null ||
          (isPasien && _noRmController.text.isEmpty) ||
          tglPasienMasuk == null ||
          tglInsiden == null ||
          waktuInsiden == null) {
        Msg.warning(context, "Mohon lengkapi seluruh data korban dan waktu.");
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (selectedJenisInsidenId == null ||
          _insidenController.text.isEmpty ||
          _kronologiController.text.isEmpty ||
          _tempatController.text.isEmpty ||
          selectedUnitId == null ||
          selectedKasusInsiden.isEmpty ||
          selectedDampak == null) {
        Msg.warning(context, "Mohon lengkapi seluruh detail laporan insiden termasuk kasus dan dampak cedera.");
        return;
      }
      setState(() => _currentStep = 3);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitReport() async {
    final bool isOlehTimAtauPetugas = tindakanOleh.toLowerCase() == 'tim' || tindakanOleh.toLowerCase() == 'petugas';

    if (selectedDampak == null ||
        _tindakanController.text.isEmpty ||
        selectedGradingRisiko == null ||
        (isOlehTimAtauPetugas && _tindakanOlehDetailController.text.trim().isEmpty)) {
      Msg.warning(context, "Mohon lengkapi data dampak, tindakan awal, grading risiko, dan detail petugas/tim.");
      return;
    }

    setState(() => isLoading = true);

    final String formattedTglMasuk = DateFormat('yyyy-MM-dd').format(tglPasienMasuk!);
    final String formattedTglInsiden = DateFormat('yyyy-MM-dd').format(tglInsiden!);
    final String formattedWaktu = "${waktuInsiden!.hour.toString().padLeft(2, '0')}:${waktuInsiden!.minute.toString().padLeft(2, '0')}:00";

    Map<String, dynamic> payload = {
      'pasien_id': _noRmController.text.isNotEmpty ? _noRmController.text : null,
      'nm_pasien': _nmPasienController.text,
      'tgl_lahir': _tglLahirController.text,
      'jk': selectedJk,
      'tgl_pasien_masuk': formattedTglMasuk,
      'jenis_insiden_id': selectedJenisInsidenId,
      'tanggal_insiden': formattedTglInsiden,
      'waktu_insiden': formattedWaktu,
      'insiden': _insidenController.text,
      'kronologi': _kronologiController.text,
      'jenis_pelapor': selectedJenisPelapor,
      'jenis_pelapor_lainnya': selectedJenisPelaporLainnya,
      'korban_insiden': selectedKorbanInsiden,
      'korban_insiden_lainnya': selectedKorbanInsidenLainnya,
      'layanan_insiden': selectedLayananInsiden,
      'layanan_insiden_lainnya': selectedLayananInsidenLainnya,
      'kasus_insiden': selectedKasusInsiden,
      'kasus_insiden_lainnya': selectedKasusInsidenLainnya,
      'tempat_kejadian': _tempatController.text,
      'unit_id': selectedUnitId,
      'dampak_insiden': selectedDampak,
      'pernah_terjadi': pernahTerjadi,
      'status_pelapor': selectedStatusPelapor,
      'tindakan_insiden': _tindakanController.text,
      'tindakan_oleh': tindakanOleh,
      'tindakan_detail': isOlehTimAtauPetugas ? _tindakanOlehDetailController.text.trim() : null,
      'grading_risiko': selectedGradingRisiko
    };

    try {
      var res = widget.existingData != null
          ? await Api().postData(payload, '/sdi/ikp/update/${widget.existingData!['id']}')
          : await Api().postData(payload, '/sdi/ikp/lapor');
      var body = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _showSuccessDialog();
      } else {
        Msg.error(context, body['message'] ?? "Gagal mengirim laporan insiden");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Berhasil"),
          ],
        ),
        content: Text(
            widget.existingData != null
                ? "Laporan IKP berhasil diperbarui."
                : "Laporan IKP berhasil terkirim. Komite Mutu & Keselamatan Pasien akan segera mengevaluasi."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: Text("OK",
                style: TextStyle(
                    color: primaryColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          _buildHeader(),
          _buildStepperTracker(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: _buildCurrentStepView(),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withBlue(220).withGreen(160)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 15),
          const Text(
            "Lapor Insiden (IKP)",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperTracker() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepIndicator(1, "Identitas", _currentStep > 1, _currentStep == 1),
          _buildStepLine(_currentStep >= 2),
          _buildStepIndicator(2, "Detail", _currentStep > 2, _currentStep == 2),
          _buildStepLine(_currentStep >= 3),
          _buildStepIndicator(3, "Tindakan", _currentStep > 3, _currentStep == 3),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepNum, String title, bool isCompleted, bool isActive) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 38 : 32,
          height: isActive ? 38 : 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF10B981)
                : (isActive ? primaryColor : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? primaryColor
                  : (isCompleted ? const Color(0xFF10B981) : Colors.grey[300]!),
              width: isActive ? 3 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: isCompleted
              ? const Icon(Icons.done_rounded, color: Colors.white, size: 16)
              : Text(
                  stepNum.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[500],
                    fontSize: isActive ? 13 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: isActive ? primaryColor : (isCompleted ? const Color(0xFF10B981) : Colors.grey[500]),
            fontSize: 11,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 3,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1:
        return _buildStep1View();
      case 2:
        return _buildStep2View();
      case 3:
        return _buildStep3View();
      default:
        return Container();
    }
  }

  // --- STEP 1: IDENTITAS PASIEN & WAKTU ---
  Widget _buildVictimTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isPasien = true;
                  selectedKorbanInsiden = 'pasien';
                  selectedPasien = null;
                  _searchPasienController.clear();
                  searchResults.clear();
                  _noRmController.clear();
                  _nmPasienController.clear();
                  _tglLahirController.clear();
                  selectedJk = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isPasien ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isPasien
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: isPasien ? primaryColor : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Pasien",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPasien ? primaryColor : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isPasien = false;
                  selectedKorbanInsiden = 'lainnya';
                  selectedPasien = null;
                  _searchPasienController.clear();
                  searchResults.clear();
                  _noRmController.clear();
                  _nmPasienController.clear();
                  _tglLahirController.clear();
                  selectedJk = 'L';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: !isPasien ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isPasien
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group,
                      size: 16,
                      color: !isPasien ? primaryColor : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Selain Pasien",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: !isPasien ? primaryColor : Colors.grey[600],
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

  Widget _buildStep1View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel("Insiden Terjadi Pada"),
        const SizedBox(height: 8),
        _buildVictimTypeSelector(),
        const SizedBox(height: 20),
        if (isPasien) ...[
          _buildInputLabel("Cari Pasien (SIMRS)"),
          const SizedBox(height: 8),
          Container(
            decoration: _buildInputBoxDecoration(),
            child: TextField(
              controller: _searchPasienController,
              onChanged: _searchPasien,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Ketik No. RM atau nama pasien...",
                hintStyle: TextStyle(color: Colors.grey[300], fontSize: 13),
                prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
                suffixIcon: isSearchingPasien
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchResults.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  var item = searchResults[index];
                  return ListTile(
                    title: Text(item['nm_pasien'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text("RM: ${item['no_rkm_medis'] ?? '-'} | Lahir: ${item['tgl_lahir'] ?? '-'}", style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, size: 16),
                    onTap: () => _selectPasien(item),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
        _buildInputLabel(isPasien ? "Nama Pasien *" : "Nama Lengkap Korban *"),
        const SizedBox(height: 8),
        _buildFormTextField(
          _nmPasienController,
          isPasien ? "Akan otomatis terisi dari pencarian SIMRS" : "Ketik Nama Lengkap Korban secara manual",
          enabled: !isPasien,
        ),
        const SizedBox(height: 15),
        if (isPasien) ...[
          _buildInputLabel("No. Rekam Medis (RM) *"),
          const SizedBox(height: 8),
          _buildFormTextField(_noRmController, "Akan otomatis terisi dari SIMRS", enabled: false),
          const SizedBox(height: 15),
        ],
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel("Tanggal Lahir *"),
                  const SizedBox(height: 8),
                  isPasien
                      ? _buildFormTextField(_tglLahirController, "Akan terisi otomatis", enabled: false)
                      : _buildTimePickerButton(
                          label: _tglLahirController.text.isEmpty
                              ? "Pilih Tanggal Lahir"
                              : _tglLahirController.text,
                          icon: Icons.cake_outlined,
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(1990),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black87,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _tglLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                        ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel("Jenis Kelamin *"),
                  const SizedBox(height: 8),
                  _buildMappedDropdown(
                    value: selectedJk ?? 'L',
                    enabled: !isPasien,
                    options: const {
                      'L': 'Laki-laki',
                      'P': 'Perempuan',
                    },
                    onChanged: (val) => setState(() => selectedJk = val),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        const Divider(),
        const SizedBox(height: 15),
        _buildInputLabel("Waktu Masuk Pasien ke Rumah Sakit *"),
        const SizedBox(height: 8),
        _buildTimePickerButton(
          label: tglPasienMasuk == null
              ? "Pilih Tanggal Masuk"
              : DateFormat('dd MMMM yyyy').format(tglPasienMasuk!),
          icon: Icons.calendar_month,
          onTap: () => _pickDate(true),
        ),
        const SizedBox(height: 15),
        _buildInputLabel("Waktu Terjadinya Insiden *"),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimePickerButton(
                label: tglInsiden == null
                    ? "Pilih Tanggal"
                    : DateFormat('dd MMMM yyyy').format(tglInsiden!),
                icon: Icons.calendar_today,
                onTap: () => _pickDate(false),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTimePickerButton(
                label: waktuInsiden == null
                    ? "Pilih Waktu"
                    : "${waktuInsiden!.hour.toString().padLeft(2, '0')}:${waktuInsiden!.minute.toString().padLeft(2, '0')}",
                icon: Icons.access_time_rounded,
                onTap: _pickTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- STEP 2: DETAIL INSIDEN ---
  Widget _buildStep2View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel("Jenis Insiden Keselamatan *"),
        const SizedBox(height: 10),
        _buildJenisInsidenCards(),
        const SizedBox(height: 20),
        _buildInputLabel("Insiden (Judul Singkat / Peristiwa) *"),
        const SizedBox(height: 8),
        _buildFormTextField(_insidenController, "Contoh: Kesalahan pemberian obat paracetamol drop"),
        const SizedBox(height: 15),
        _buildInputLabel("Kronologi Kejadian Lengkap *"),
        const SizedBox(height: 8),
        Container(
          decoration: _buildInputBoxDecoration(),
          child: TextField(
            controller: _kronologiController,
            maxLines: 6,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Ceritakan kronologi terjadinya insiden secara lengkap...",
              hintStyle: TextStyle(color: Colors.grey[300], fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(15),
            ),
          ),
        ),
        const SizedBox(height: 15),
        _buildInputLabel("Tempat Kejadian Fisik *"),
        const SizedBox(height: 8),
        _buildFormTextField(_tempatController, "Contoh: Kamar Mandi Kamar 302, Depan IGD, Koridor ICU"),
        const SizedBox(height: 15),
        _buildInputLabel("Unit Penyebab / Unit Terkait Laporan *"),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: _buildInputBoxDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedUnitId,
              hint: Text("Pilih Unit", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              isExpanded: true,
              items: masterUnits.map((u) {
                return DropdownMenuItem<int>(
                  value: u['id'],
                  child: Text(u['nama_unit'] ?? '-'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedUnitId = val);
                _fetchAutoGrading();
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildInputLabel("Orang Pertama yang Melaporkan"),
        const SizedBox(height: 8),
        _buildMappedDropdown(
          value: selectedJenisPelapor,
          options: jenisPelaporOptions,
          onChanged: (val) => setState(() => selectedJenisPelapor = val!),
        ),
        const SizedBox(height: 15),
        _buildInputLabel("Korban Insiden"),
        const SizedBox(height: 8),
        _buildMappedDropdown(
          value: selectedKorbanInsiden,
          options: korbanInsidenOptions,
          onChanged: (val) => setState(() => selectedKorbanInsiden = val!),
        ),
        const SizedBox(height: 15),
        _buildInputLabel("Layanan Terkait Insiden"),
        const SizedBox(height: 8),
        _buildMappedDropdown(
          value: selectedLayananInsiden,
          options: layananInsidenOptions,
          onChanged: (val) => setState(() => selectedLayananInsiden = val!),
        ),
        const SizedBox(height: 20),
        _buildInputLabel("Insiden Terjadi Pada Pasien (Kasus Penyakit / Spesialisasi) *"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kasusOptions.entries.map((entry) {
            bool isSelected = selectedKasusInsiden.contains(entry.key);
            return FilterChip(
              label: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? primaryColor : Colors.grey[200]!),
              ),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedKasusInsiden.add(entry.key);
                  } else {
                    selectedKasusInsiden.remove(entry.key);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 25),
        _buildInputLabel("Dampak Cedera (Tingkat Keparahan / Severity) *"),
        const SizedBox(height: 10),
        _buildDampakCards(),
      ],
    );
  }

  // --- STEP 3: DAMPAK & TINDAKAN ---
  Widget _buildStep3View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAutoGradingSection(),
        const SizedBox(height: 20),
        _buildGradingRisikoSelection(),
        const SizedBox(height: 25),
        _buildInputLabel("Tindakan Awal yang Dilakukan Pasca Kejadian *"),
        const SizedBox(height: 8),
        Container(
          decoration: _buildInputBoxDecoration(),
          child: TextField(
            controller: _tindakanController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Contoh: Melakukan observasi vital sign, mengganti cairan infus...",
              hintStyle: TextStyle(color: Colors.grey[300], fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(15),
            ),
          ),
        ),
        const SizedBox(height: 15),
        _buildInputLabel("Tindakan Dilakukan Oleh *"),
        const SizedBox(height: 8),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Dokter", style: TextStyle(fontSize: 13)),
                    value: "Dokter",
                    groupValue: tindakanOleh,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => tindakanOleh = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Tim", style: TextStyle(fontSize: 13)),
                    value: "Tim",
                    groupValue: tindakanOleh,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => tindakanOleh = val!),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Perawat", style: TextStyle(fontSize: 13)),
                    value: "Perawat",
                    groupValue: tindakanOleh,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => tindakanOleh = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Petugas", style: TextStyle(fontSize: 13)),
                    value: "Petugas",
                    groupValue: tindakanOleh,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => tindakanOleh = val!),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (tindakanOleh.toLowerCase() == 'tim' || tindakanOleh.toLowerCase() == 'petugas') ...[
          const SizedBox(height: 15),
          _buildInputLabel("Detail Nama Tim / Petugas *"),
          const SizedBox(height: 8),
          _buildFormTextField(_tindakanOlehDetailController, "Masukkan nama petugas atau anggota tim"),
        ],
        const SizedBox(height: 15),
        _buildInputLabel("Apakah Kejadian Serupa Pernah Terjadi di Unit Lain?"),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<int>(
                title: const Text("Pernah", style: TextStyle(fontSize: 13)),
                value: 1,
                groupValue: pernahTerjadi,
                activeColor: primaryColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => pernahTerjadi = val!),
              ),
            ),
            Expanded(
              child: RadioListTile<int>(
                title: const Text("Belum Pernah", style: TextStyle(fontSize: 13)),
                value: 0,
                groupValue: pernahTerjadi,
                activeColor: primaryColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => pernahTerjadi = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildInputLabel("Status Pelapor Insiden"),
        const SizedBox(height: 8),
        _buildStringDropdown(
          value: selectedStatusPelapor,
          items: ['Staf', 'Penanggung Jawab', 'Koordinator / Kepala Unit'],
          onChanged: (val) => setState(() => selectedStatusPelapor = val!),
        ),
      ],
    );
  }

  // --- ATOM UI WIDGETS ---
  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
    );
  }

  Widget _buildFormTextField(TextEditingController controller, String hint, {bool enabled = true}) {
    return Container(
      decoration: _buildInputBoxDecoration(enabled: enabled),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(fontSize: 14, color: enabled ? const Color(0xFF2D3142) : Colors.grey[500]),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[300], fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTimePickerButton({required String label, required IconData icon, required VoidCallback onTap, bool enabled = true}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: _buildInputBoxDecoration(enabled: enabled),
        child: Row(
          children: [
            Icon(icon, color: enabled ? primaryColor : Colors.grey[400], size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled ? const Color(0xFF2D3142) : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStringDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: _buildInputBoxDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMappedDropdown({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: _buildInputBoxDecoration(enabled: enabled),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: options.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  BoxDecoration _buildInputBoxDecoration({bool enabled = true}) {
    return BoxDecoration(
      color: enabled ? Colors.white : Colors.grey[100],
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: enabled ? Colors.grey[200]! : Colors.grey[300]!, width: 1),
      boxShadow: enabled
          ? [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))
            ]
          : [],
    );
  }

  Widget _buildJenisInsidenCards() {
    return Column(
      children: masterJenisInsiden.map((j) {
        bool isSelected = selectedJenisInsidenId == j['id'];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => selectedJenisInsidenId = j['id']);
            _fetchAutoGrading();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey[200]!,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(j['alias'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? primaryColor : Colors.black87)),
                      const SizedBox(height: 2),
                      Text(j['nama_jenis_insiden'] ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
                if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDampakCards() {
    List<Map<String, dynamic>> dampaks = [
      {'label': 'Tidak Cedera (Tidak Signifikan - Biru)', 'value': 'tidak signifikan', 'color': Colors.blue},
      {'label': 'Cedera Ringan (Minor - Hijau)', 'value': 'minor', 'color': Colors.green},
      {'label': 'Cedera Sedang (Moderat - Kuning)', 'value': 'moderat', 'color': Colors.amber[700]},
      {'label': 'Cedera Berat (Mayor - Oranye)', 'value': 'mayor', 'color': Colors.orange[800]},
      {'label': 'Kematian (Katastropik - Merah)', 'value': 'katastropik', 'color': Colors.red},
    ];

    return Column(
      children: dampaks.map((d) {
        bool isSelected = selectedDampak == d['value'];
        Color c = d['color'];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => selectedDampak = d['value']);
            _fetchAutoGrading();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? c.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? c : Colors.grey[200]!,
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? c : Colors.grey[350]!, width: 1.8),
                    color: isSelected ? c : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 10)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    d['label'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                      color: isSelected ? c : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAutoGradingSection() {
    if (selectedJenisInsidenId == null || selectedUnitId == null || selectedDampak == null) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.help_outline_rounded, color: Colors.grey[600], size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Auto Grading Sistem",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Anda sepertinya belum mengisi data insiden dengan benar (jenis insiden, unit, dan dampak insiden). Auto Grading sistem belum dapat memberikan grading insiden ini.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isCalculatingGrading) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
            ),
            const SizedBox(width: 12),
            Text(
              "Menghitung grading risiko otomatis...",
              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (autoGradingValue == null || autoGradingLabel == null) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData iconData;

    switch (autoGradingValue) {
      case 'biru':
        bgColor = const Color(0xFFE3F2FD);
        borderColor = const Color(0xFF90CAF9);
        textColor = const Color(0xFF0D47A1);
        iconData = Icons.info_outline_rounded;
        break;
      case 'hijau':
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFFA5D6A7);
        textColor = const Color(0xFF1B5E20);
        iconData = Icons.check_circle_outline_rounded;
        break;
      case 'kuning':
        bgColor = const Color(0xFFFFFDE7);
        borderColor = const Color(0xFFFFE082);
        textColor = const Color(0xFFF57F17);
        iconData = Icons.warning_amber_rounded;
        break;
      case 'merah':
        bgColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFEF9A9A);
        textColor = const Color(0xFFB71C1C);
        iconData = Icons.error_outline_rounded;
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        borderColor = const Color(0xFFE0E0E0);
        textColor = const Color(0xFF424242);
        iconData = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: textColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Auto Grading Sistem",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textColor.withOpacity(0.85),
                    ),
                    children: [
                      const TextSpan(text: "Berdasarkan data yang telah diinput (jenis insiden, unit, dan dampak insiden). Sistem memberikan grading insiden ini sebagai "),
                      TextSpan(
                        text: autoGradingLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: "."),
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

  Widget _buildGradingRisikoSelection() {
    List<String> options = ['Biru', 'Hijau', 'Kuning', 'Merah'];
    Map<String, Color> colors = {
      'Biru': Colors.blue,
      'Hijau': Colors.green,
      'Kuning': Colors.amber[700]!,
      'Merah': Colors.red,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel("Grading Risiko * (Manual Adjustment)"),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: options.map((opt) {
            bool isSelected = selectedGradingRisiko == opt;
            Color c = colors[opt]!;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => selectedGradingRisiko = opt);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? c : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? c : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: c.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : c,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        opt,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 15,
        bottom: bottomPadding > 0 ? bottomPadding + 10 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.grey[100]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: isLoading ? null : _prevStep,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: primaryColor.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "KEMBALI",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : (_currentStep == 3 ? _submitReport : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentStep == 3 ? "KIRIM LAPORAN" : "LANJUT",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
