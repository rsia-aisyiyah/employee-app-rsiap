import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class LaporIkpFormScreen extends StatefulWidget {
  const LaporIkpFormScreen({super.key});

  @override
  State<LaporIkpFormScreen> createState() => _LaporIkpFormScreenState();
}

class _LaporIkpFormScreenState extends State<LaporIkpFormScreen> {
  int _currentStep = 1;
  bool isLoading = false;
  bool isSearchingPasien = false;

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

  // Step 2: Incident Details
  int? selectedJenisInsidenId;
  final TextEditingController _insidenController = TextEditingController();
  final TextEditingController _kronologiController = TextEditingController();
  final TextEditingController _tempatController = TextEditingController();
  int? selectedUnitId;
  String selectedJenisPelapor = 'Karyawan';
  String? selectedJenisPelaporLainnya;
  String selectedKorbanInsiden = 'Pasien';
  String? selectedKorbanInsidenLainnya;
  String selectedLayananInsiden = 'Medis';
  String? selectedLayananInsidenLainnya;
  List<String> selectedKasusInsiden = [];
  String? selectedKasusInsidenLainnya;

  // Step 3: Severity & Action
  String? selectedDampak; // Biru, Hijau, Kuning, Merah
  int pernahTerjadi = 0; // 0: Tidak, 1: Ya
  String selectedStatusPelapor = 'Staf'; // Staf, Pj, Koor
  final TextEditingController _tindakanController = TextEditingController();
  String tindakanOleh = 'Petugas'; // Petugas, Tim

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
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
    super.dispose();
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

  Future<void> _searchPasien(String query) async {
    if (query.length < 3) {
      setState(() => searchResults = []);
      return;
    }

    setState(() => isSearchingPasien = true);
    try {
      var res = await Api().getData('/sdi/ikp/pasien/search?keyword=$query');
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
          selectedJk == null ||
          tglPasienMasuk == null ||
          tglInsiden == null ||
          waktuInsiden == null) {
        Msg.warning(context, "Mohon lengkapi seluruh data pasien dan waktu.");
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (selectedJenisInsidenId == null ||
          _insidenController.text.isEmpty ||
          _kronologiController.text.isEmpty ||
          _tempatController.text.isEmpty ||
          selectedUnitId == null) {
        Msg.warning(context, "Mohon lengkapi seluruh detail laporan insiden.");
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
    if (selectedDampak == null ||
        _tindakanController.text.isEmpty) {
      Msg.warning(context, "Mohon lengkapi data dampak dan tindakan awal.");
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
      'tindakan_oleh': tindakanOleh
    };

    try {
      var res = await Api().postData(payload, '/sdi/ikp/lapor');
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
        content: const Text(
            "Laporan IKP berhasil terkirim. Komite Mutu & Keselamatan Pasien akan segera mengevaluasi."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
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
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepIndicator(1, "Identitas", _currentStep >= 1),
          _buildStepLine(_currentStep >= 2),
          _buildStepIndicator(2, "Detail", _currentStep >= 2),
          _buildStepLine(_currentStep >= 3),
          _buildStepIndicator(3, "Tindakan", _currentStep >= 3),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepNum, String title, bool isActive) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.grey[200],
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? primaryColor : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Text(
            stepNum.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            color: isActive ? primaryColor : Colors.grey[500],
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 15),
        color: isActive ? primaryColor : Colors.grey[200],
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
  Widget _buildStep1View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            maxHeight: 180,
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
        _buildInputLabel("Nama Pasien *"),
        const SizedBox(height: 8),
        _buildFormTextField(_nmPasienController, "Ketik Nama Pasien secara manual jika tidak ada di SIMRS"),
        const SizedBox(height: 15),
        _buildInputLabel("No. Rekam Medis (RM)"),
        const SizedBox(height: 8),
        _buildFormTextField(_noRmController, "Kosongkan jika bukan pasien RS (pengunjung/staf)"),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel("Tanggal Lahir *"),
                  const SizedBox(height: 8),
                  _buildFormTextField(_tglLahirController, "YYYY-MM-DD"),
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
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: _buildInputBoxDecoration(),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedJk,
                        hint: Text("Pilih JK", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'L', child: Text("Laki-laki")),
                          DropdownMenuItem(value: 'P', child: Text("Perempuan")),
                        ],
                        onChanged: (val) => setState(() => selectedJk = val),
                      ),
                    ),
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
              onChanged: (val) => setState(() => selectedUnitId = val),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildInputLabel("Orang Pertama yang Melaporkan"),
        const SizedBox(height: 8),
        _buildStringDropdown(
          value: selectedJenisPelapor,
          items: ['Karyawan', 'Dokter', 'Pasien', 'Keluarga Pasien', 'Lainnya'],
          onChanged: (val) => setState(() => selectedJenisPelapor = val!),
        ),
        const SizedBox(height: 15),
        _buildInputLabel("Korban Insiden"),
        const SizedBox(height: 8),
        _buildStringDropdown(
          value: selectedKorbanInsiden,
          items: ['Pasien', 'Karyawan', 'Pengunjung', 'Lainnya'],
          onChanged: (val) => setState(() => selectedKorbanInsiden = val!),
        ),
        const SizedBox(height: 15),
        _buildInputLabel("Layanan Terkait Insiden"),
        const SizedBox(height: 8),
        _buildStringDropdown(
          value: selectedLayananInsiden,
          items: ['Medis', 'Keperawatan', 'Farmasi', 'Laboratorium', 'Radiologi', 'Gizi', 'Sarana Prasarana', 'Administrasi'],
          onChanged: (val) => setState(() => selectedLayananInsiden = val!),
        ),
      ],
    );
  }

  // --- STEP 3: DAMPAK & TINDAKAN ---
  Widget _buildStep3View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel("Dampak Cedera (Tingkat Keparahan / Severity) *"),
        const SizedBox(height: 10),
        _buildDampakCards(),
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
        _buildInputLabel("Tindakan Dilakukan Oleh"),
        const SizedBox(height: 8),
        Row(
          children: [
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

  Widget _buildFormTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: _buildInputBoxDecoration(),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[300], fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTimePickerButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: _buildInputBoxDecoration(),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 18),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

  BoxDecoration _buildInputBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey[200]!, width: 1),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))
      ],
    );
  }

  Widget _buildJenisInsidenCards() {
    return Column(
      children: masterJenisInsiden.map((j) {
        bool isSelected = selectedJenisInsidenId == j['id'];
        return GestureDetector(
          onTap: () => setState(() => selectedJenisInsidenId = j['id']),
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
      {'label': 'Biru (Tidak Cedera)', 'value': 'Biru', 'color': Colors.blue},
      {'label': 'Hijau (Cedera Ringan)', 'value': 'Hijau', 'color': Colors.green},
      {'label': 'Kuning (Cedera Sedang)', 'value': 'Kuning', 'color': Colors.amber[700]},
      {'label': 'Merah (Cedera Berat/Kematian)', 'value': 'Merah', 'color': Colors.red},
    ];

    return Column(
      children: dampaks.map((d) {
        bool isSelected = selectedDampak == d['value'];
        Color c = d['color'];
        return GestureDetector(
          onTap: () => setState(() => selectedDampak = d['value']),
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
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
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
                if (isSelected) Icon(Icons.check_circle, color: c, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: isLoading ? null : _prevStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("KEMBALI", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _currentStep == 3 ? "KIRIM LAPORAN" : "LANJUT",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
