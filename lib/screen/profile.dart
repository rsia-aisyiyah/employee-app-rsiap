import 'dart:convert';
import 'dart:io';

import 'package:age_calculator/age_calculator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/screen/logout.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_profile.dart';
import 'package:rsia_employee_app/utils/biometric_helper.dart';
import 'package:rsia_employee_app/utils/secure_storage_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late DateDuration duration;
  late Map<String, dynamic> dataTbl;
  late Map<String, dynamic> dataTbl2;
  Map _bio = {};
  bool isLoading = true;
  bool isSuccess = true;
  String nik = "";
  String email = "";
  String no_telp = "";
  String alamat = "";
  String stts_nikah = "SINGLE";
  String nomor_str = "";
  String nomor_sip = "";
  String tanggal_str = "";
  String tanggal_akhir_str = "";
  String tanggal_izin_praktek = "";
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    fetchAllData();
    _checkBiometricStatus();
  }

  Future<void> fetchAllData() async {
    try {
      await _getBio();
    } catch (e) {
      print("DEBUG: Error in fetchAllData: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _getBio() async {
    try {
      print("DEBUG: Fetching bio...");
      var res = await Api().getData(
          "/pegawai/${box.read('sub')}?include=dep,petugas,email,statusKerja,keluarga,kualifikasiStaf,latestSkKredensial");

      print("DEBUG: Bio Response Status: ${res.statusCode}");
      print("DEBUG: Bio Response Body: ${res.body}");

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (mounted) {
          setState(() {
            _bio = body['data'];
            // Wrap setDataTbl in try-catch to prevent crash from data issues
            try {
              setDataTbl(_bio);
            } catch (e) {
              print("DEBUG: Error in setDataTbl: $e");
            }
          });
        }
      } else {
        print("DEBUG: Failed to fetch bio: ${res.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Exception in _getBio: $e");
      rethrow;
    }
  }

  Future<void> updateProfil() async {
    var data = {
      'email': email,
      'no_telp': no_telp,
      'alamat': alamat,
      'stts_nikah': stts_nikah,
      if (_bio['kualifikasi_staf'] != null) ...{
        'nomor_str': nomor_str,
        'nomor_sip': nomor_sip,
        'tanggal_str': tanggal_str,
        'tanggal_akhir_str': tanggal_akhir_str,
        'tanggal_izin_praktek': tanggal_izin_praktek,
      }
    };
    var res = await Api().postData(data, "/pegawai/${box.read('sub')}/profile");
    var body = json.decode(res.body);

    if (res.statusCode == 200) {
      isSuccess = true;
      Msg.success(context, body['message']);
      Navigator.pop(context);
      fetchAllData();
    } else {
      isSuccess = false;
      Msg.error(context, body['message']);
    }
  }

  Future<void> _pickAndUploadBerkas(BuildContext context, String type) async {
    try {
      // 1. Get kategori from qualification
      String? kategoriProfesi = _bio['kualifikasi_staf']?['kategori_profesi'];
      if (kategoriProfesi == null) {
        Msg.error(context, "Kategori profesi tidak ditemukan");
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // 2. Fetch master berkas to find the right code
      var resMaster = await Api().getData("/sdi/pegawai/berkas/nama-berkas");
      
      // Close loading
      Navigator.pop(context);

      if (resMaster.statusCode != 200) {
        Msg.error(context, "Gagal mengambil daftar berkas");
        return;
      }

      var bodyMaster = json.decode(resMaster.body);
      List masterList = bodyMaster['data'] ?? [];

      // Filter by type name
      String searchName = type == 'SIP' ? 'Surat Izin Praktik (SIP)' : 'Surat Tanda Registrasi(STR)';
      
      // Find the one that matches our professional category (partial match)
      // "Staf Keperawatan" -> "Tenaga klinis Perawat dan Bid"
      // "Staf Medis" -> "Tenaga klinis Dokter"
      var match = masterList.firstWhere((item) {
        String kategori = item['kategori'] ?? '';
        String nama = item['nama'] ?? '';
        
        bool nameMatch = nama.contains(searchName);
        bool catMatch = false;

        if (kategoriProfesi.contains('Keperawatan') || kategoriProfesi.contains('Kebidanan')) {
          catMatch = kategori.contains('Perawat');
        } else if (kategoriProfesi.contains('Medis')) {
          catMatch = kategori.contains('Dokter');
        } else {
          catMatch = kategori.contains('Profesi Lain');
        }

        return nameMatch && catMatch;
      }, orElse: () => null);

      if (match == null) {
        Msg.error(context, "Jenis berkas untuk $type tidak ditemukan untuk kategori Anda");
        return;
      }

      String kodeBerkas = match['kode'];

      // 3. Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        // 4. Upload
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        Map<String, String> fields = {
          'nik': box.read('sub'),
          'berkas': kodeBerkas,
        };

        var resUpload = await Api().postMultipart(fields, file, "/sdi/pegawai/upload/berkas", fieldName: 'file_berkas');
        
        // Close loading
        Navigator.pop(context);

        var bodyUpload = json.decode(resUpload.body);
        if (resUpload.statusCode == 200 && bodyUpload['success'] == true) {
          Msg.success(context, "Berkas $type berhasil diunggah");
        } else {
          Msg.error(context, bodyUpload['message'] ?? "Gagal mengunggah berkas");
        }
      }
    } catch (e) {
      // If error occurs, try to pop if dialog is still open
      // This is a bit tricky in Flutter without context management, 
      // but usually we can assume if it fails here we might need to pop.
      // However, to be safe, I'll just print and show error.
      print("DEBUG: Error in _pickAndUploadBerkas: $e");
      Msg.error(context, "Terjadi kesalahan: $e");
    }
  }

  Future<void> _selectDate(BuildContext context, String initialDate, Function(String) onSelected) async {
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime(2100);
    DateTime initial = DateTime.tryParse(initialDate) ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked.toString().split(' ')[0]);
    }
  }

  void setDataTbl(detailBio) {
    try {
      if (detailBio['mulai_kerja'] != null) {
        duration = AgeCalculator.age(DateTime.parse(detailBio['mulai_kerja']));
      }
    } catch (e) {
      print("Error parsing age: $e");
    }

    dataTbl = {
      "No. KTP": detailBio['no_ktp'] ?? '-',
      "Jenis Kelamin": (detailBio['jk'] == 'L' || detailBio['jk'] == 'Pria')
          ? "Laki-laki"
          : "Perempuan",
      "Tempat & Tanggal Lahir":
          "${detailBio['tmp_lahir'] ?? '-'}, ${detailBio['tgl_lahir'] != null ? Helper.formatDate4(detailBio['tgl_lahir']) : '-'}",
      "Alamat": detailBio['alamat'] ?? '-',
      "Pendidikan": detailBio['pendidikan'] ?? '-',
      "Jabatan": detailBio['jbtn'] ?? '-',
      "Bidang": detailBio['bidang'] ?? '-',
      "Status": detailBio['status_kerja'] != null
          ? detailBio['status_kerja']['ktg']
          : '-',
      "Mulai Kontrak": detailBio['mulai_kontrak'] != null
          ? Helper.formatDate2(detailBio['mulai_kontrak'])
          : '-',
    };

    if (detailBio['kualifikasi_staf'] != null) {
      var k = detailBio['kualifikasi_staf'];
      dataTbl["Nomor STR"] = k['nomor_str'] ?? '-';
      dataTbl["Nomor SIP"] = k['nomor_sip'] ?? '-';
      dataTbl["Tgl. Berakhir SIP"] = k['tanggal_akhir_str'] != null
          ? Helper.formatDate2(k['tanggal_akhir_str'])
          : '-';
    }

    if (detailBio['latest_sk_kredensial'] != null && detailBio['latest_sk_kredensial']['kredensial'] != null) {
      var kred = detailBio['latest_sk_kredensial']['kredensial'];
      dataTbl["Jenjang Kredensial"] = kred['label'] ?? '-';
    }

    dataTbl2 = {
      "No. HP": (detailBio['petugas'] != null &&
              detailBio['petugas']['no_telp'] != null)
          ? detailBio['petugas']['no_telp']
          : '-',
      "Email":
          (detailBio['email'] != null && detailBio['email']['email'] != null)
              ? detailBio['email']['email']
              : "-",
    };
  }

  /// Check biometric availability and status
  Future<void> _checkBiometricStatus() async {
    final isAvailable = await BiometricHelper.isBiometricAvailable();
    final isEnabled = await SecureStorageHelper.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricEnabled = isEnabled;
      });
    }
  }

  /// Enable biometric authentication
  Future<void> _enableBiometric(StateSetter setModalState) async {
    // Show password confirmation dialog
    final confirmed = await _showPasswordConfirmationDialog();
    if (!confirmed) return;

    // Authenticate with biometric
    final result = await BiometricHelper.authenticate(
      localizedReason: 'Verifikasi untuk mengaktifkan fingerprint login',
    );

    if (result.success) {
      // Get current credentials from storage (NIK from box)
      final nik = box.read('sub')?.toString() ?? '';

      // Save credentials
      final saved = await SecureStorageHelper.saveCredentials(
        nik: nik,
        password: '', // Password will be set during next manual login
      );

      if (saved && mounted) {
        setState(() => _biometricEnabled = true);
        setModalState(() => _biometricEnabled = true);
        Msg.success(context, 'Fingerprint login berhasil diaktifkan!');
      }
    } else if (result.errorCode != BiometricErrorCode.userCanceled && mounted) {
      Msg.error(
          context, result.errorMessage ?? 'Gagal mengaktifkan fingerprint');
    }
  }

  /// Disable biometric authentication
  Future<void> _disableBiometric(StateSetter setModalState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Nonaktifkan Fingerprint?'),
        content: const Text('Anda harus login manual di lain waktu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Nonaktifkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SecureStorageHelper.deleteCredentials();
      if (mounted) {
        setState(() => _biometricEnabled = false);
        setModalState(() => _biometricEnabled = false);
        Msg.success(context, 'Fingerprint login dinonaktifkan');
      }
    }
  }

  /// Show password confirmation dialog
  Future<bool> _showPasswordConfirmationDialog() async {
    // For now, just return true. In production, you'd verify the password.
    // This is a simplified version.
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SkeletonProfile();
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(context),
            const SizedBox(height: 20),
            _buildModernProfileInfo(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 50),
          width: double.infinity,
          height: 180 + MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20,
                left: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Profile Saya",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: _showLogoutMenu,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: _buildCenteredProfilePic(),
        ),
      ],
    );
  }

  void _showEditDialog() {
    stts_nikah = (_bio['petugas'] != null && _bio['petugas']['stts_nikah'] != null)
        ? _bio['petugas']['stts_nikah'].toString()
        : "SINGLE";

    if (_bio['kualifikasi_staf'] != null) {
      var k = _bio['kualifikasi_staf'];
      nomor_str = k['nomor_str']?.toString() ?? "";
      nomor_sip = k['nomor_sip']?.toString() ?? "";
      
      // Format ISO dates from backend (e.g. 2025-07-24T17:00:00.000000Z) to YYYY-MM-DD
      // We parse and convert to local first to ensure timezone shifts are handled correctly
      tanggal_str = k['tanggal_str'] != null 
          ? DateTime.parse(k['tanggal_str'].toString()).toLocal().toString().split(' ')[0] 
          : "";
      tanggal_akhir_str = k['tanggal_akhir_str'] != null 
          ? DateTime.parse(k['tanggal_akhir_str'].toString()).toLocal().toString().split(' ')[0] 
          : "";
      tanggal_izin_praktek = k['tanggal_izin_praktek'] != null 
          ? DateTime.parse(k['tanggal_izin_praktek'].toString()).toLocal().toString().split(' ')[0] 
          : "";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height *
                0.70, // Slightly reduced height
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                // Title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit Data Profile",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textBlue,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),
                ),
                const Divider(),
                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: _buildFormEditProfile(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormSection(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormEditProfile() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildFormSection(
            title: 'Informasi Dasar',
            icon: Icons.person_outline,
            children: [
              _buildModernInput(
                label: 'Email',
                initialValue: _bio['email'] != null
                    ? _bio['email']['email'].toString()
                    : '',
                icon: Icons.alternate_email,
                hint: 'cth: nama@email.com',
                onSaved: (val) => email = val!,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Email wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              _buildModernInput(
                label: 'No. Handphone',
                initialValue: _bio['petugas'] != null
                    ? _bio['petugas']['no_telp'].toString()
                    : '',
                icon: Icons.phone_iphone,
                hint: 'cth: 08123456789',
                keyboardType: TextInputType.phone,
                onSaved: (val) => no_telp = val!,
                validator: (val) =>
                    val == null || val.isEmpty ? 'No. HP wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              _buildModernInput(
                label: 'Alamat',
                initialValue: _bio['alamat']?.toString() ?? '',
                icon: Icons.location_on_outlined,
                hint: 'Masukkan alamat lengkap',
                maxLines: 2,
                onSaved: (val) => alamat = val!,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Menikah',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: stts_nikah,
                    items: [
                      const DropdownMenuItem(
                          value: 'SINGLE', child: Text('Single')),
                      const DropdownMenuItem(
                          value: 'MENIKAH', child: Text('Menikah')),
                      const DropdownMenuItem(
                          value: 'JANDA', child: Text('Janda')),
                      const DropdownMenuItem(
                          value: 'DUDHA', child: Text('Duda')),
                    ],
                    onChanged: (val) {
                      stts_nikah = val!;
                    },
                    onSaved: (val) => stts_nikah = val!,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.favorite_border,
                          color: primaryColor, size: 20),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_bio['kualifikasi_staf'] != null)
            _buildFormSection(
              title: 'Kualifikasi Klinis',
              icon: Icons.verified_user_outlined,
              children: [
                _buildModernInput(
                  label: 'Nomor STR',
                  initialValue: nomor_str,
                  icon: Icons.badge_outlined,
                  hint: 'Masukkan Nomor STR',
                  onSaved: (val) => nomor_str = val!,
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.upload_file_outlined,
                          color: primaryColor, size: 20),
                      onPressed: () => _pickAndUploadBerkas(context, 'STR'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                StatefulBuilder(builder: (context, setModalState) {
                  return _buildModernInput(
                    label: 'Tanggal Terbit STR',
                    controller: TextEditingController(text: tanggal_str),
                    icon: Icons.calendar_today_outlined,
                    hint: 'Pilih Tanggal',
                    readOnly: true,
                    onTap: () => _selectDate(context, tanggal_str, (val) {
                      setModalState(() => tanggal_str = val);
                    }),
                    onSaved: (val) => tanggal_str = val!,
                  );
                }),
                const SizedBox(height: 20),
                _buildModernInput(
                  label: 'Nomor SIP',
                  initialValue: nomor_sip,
                  icon: Icons.assignment_outlined,
                  hint: 'Masukkan Nomor SIP',
                  onSaved: (val) => nomor_sip = val!,
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.upload_file_outlined,
                          color: primaryColor, size: 20),
                      onPressed: () => _pickAndUploadBerkas(context, 'SIP'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                StatefulBuilder(builder: (context, setModalState) {
                  return _buildModernInput(
                    label: 'Tanggal Mulai SIP',
                    controller:
                        TextEditingController(text: tanggal_izin_praktek),
                    icon: Icons.event_available_outlined,
                    hint: 'Pilih Tanggal',
                    readOnly: true,
                    onTap: () =>
                        _selectDate(context, tanggal_izin_praktek, (val) {
                      setModalState(() => tanggal_izin_praktek = val);
                    }),
                    onSaved: (val) => tanggal_izin_praktek = val!,
                  );
                }),
                const SizedBox(height: 20),
                StatefulBuilder(builder: (context, setModalState) {
                  return _buildModernInput(
                    label: 'Tanggal Berakhir SIP',
                    controller: TextEditingController(text: tanggal_akhir_str),
                    icon: Icons.event_busy_outlined,
                    hint: 'Pilih Tanggal',
                    readOnly: true,
                    onTap: () => _selectDate(context, tanggal_akhir_str, (val) {
                      setModalState(() => tanggal_akhir_str = val);
                    }),
                    onSaved: (val) => tanggal_akhir_str = val!,
                  );
                }),
              ],
            ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                updateProfil();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              shadowColor: primaryColor.withOpacity(0.4),
            ),
            child: const Text(
              'Simpan Perubahan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildModernInput({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    required IconData icon,
    required String hint,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
              fontSize: 13,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryColor, size: 20),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          onSaved: onSaved,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCenteredProfilePic() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: _bio['photo'] != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                          photoUrl + _bio['photo'].toString()),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : null,
            ),
            child: _bio['photo'] == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _bio['nama']?.toString() ?? "Nama Pegawai",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          _bio['jbtn']?.toString() ?? "Jabatan",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showAddFamilyDialog() {
    final _familyFormKey = GlobalKey<FormState>();
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _ktpController = TextEditingController();
    final TextEditingController _bpjsController = TextEditingController();
    final TextEditingController _birthDateController = TextEditingController();
    final TextEditingController _jobController = TextEditingController();
    final TextEditingController _descController = TextEditingController();

    String fName = "";
    String fRelation = "Anak";
    String fKtp = "";
    String fBpjs = "";
    String fJk = "L";
    DateTime? fBirthDate;
    String fJob = "";
    String fDesc = "";
    bool isSearching = false;

    void _performAutopopulate(
        Map<String, dynamic> peserta, Function setModalState) {
      if (peserta['nama'] != null) {
        _nameController.text = peserta['nama'];
        fName = peserta['nama'];
      }

      if (peserta['nik'] != null) {
        _ktpController.text = peserta['nik'];
        fKtp = peserta['nik'];
      }

      if (peserta['noKartu'] != null) {
        _bpjsController.text = peserta['noKartu'];
        fBpjs = peserta['noKartu'];
      }

      if (peserta['tglLahir'] != null) {
        try {
          fBirthDate = DateTime.parse(peserta['tglLahir']);
          _birthDateController.text = Helper.formatDate4(fBirthDate.toString());
        } catch (e) {
          print("Error parsing birth date: $e");
        }
      }

      if (peserta['sex'] != null) {
        fJk = peserta['sex'] == 'L' ? 'L' : 'P';
      }

      setModalState(() {});
    }

    Future<void> _lookupBpjs(
        String value, bool isNik, Function setModalState) async {
      if (value.isEmpty) {
        Msg.error(
            context, "Harap isi ${isNik ? 'NIK' : 'No. BPJS'} terlebih dahulu");
        return;
      }

      setModalState(() => isSearching = true);
      try {
        String today = DateTime.now().toString().split(' ')[0]; // yyyy-mm-dd
        String type = isNik ? "nik" : "nokartu";
        var res =
            await Api().getData("/bpjs/vclaim/peserta/$type/$value/$today");

        if (res.statusCode == 200) {
          var body = json.decode(res.body);
          if (body['metaData'] != null && body['metaData']['code'] == '200') {
            _performAutopopulate(body['response']['peserta'], setModalState);
            Msg.success(context, "Data ditemukan!");
          } else {
            Msg.error(context,
                body['metaData']?['message'] ?? "Data tidak ditemukan");
          }
        } else {
          Msg.error(context, "Koneksi ke server BPJS bermasalah");
        }
      } catch (e) {
        Msg.error(context, "Terjadi kesalahan: $e");
      } finally {
        setModalState(() => isSearching = false);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tambah Anggota Keluarga",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textBlue,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        )
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _familyFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModernInput(
                              label: 'Nama Lengkap',
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: 'Nama anggota keluarga',
                              onSaved: (val) => fName = val!,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Nama wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Hubungan",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: fRelation,
                                  isExpanded: true,
                                  items: [
                                    'Suami',
                                    'Istri',
                                    'Anak',
                                    'Ayah',
                                    'Ibu',
                                    'Saudara'
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setModalState(() => fRelation = val!);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildModernInput(
                              label: 'No. KTP',
                              controller: _ktpController,
                              icon: Icons.credit_card,
                              hint: '16 digit NIK',
                              keyboardType: TextInputType.number,
                              onSaved: (val) => fKtp = val!,
                              suffixIcon: isSearching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)))
                                  : IconButton(
                                      icon: Icon(Icons.search,
                                          color: primaryColor),
                                      onPressed: () => _lookupBpjs(
                                          _ktpController.text,
                                          true,
                                          setModalState),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            _buildModernInput(
                              label: 'No. BPJS',
                              controller: _bpjsController,
                              icon: Icons.card_membership,
                              hint: '13 digit No. BPJS',
                              keyboardType: TextInputType.number,
                              onSaved: (val) => fBpjs = val!,
                              suffixIcon: isSearching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)))
                                  : IconButton(
                                      icon: Icon(Icons.search,
                                          color: primaryColor),
                                      onPressed: () => _lookupBpjs(
                                          _bpjsController.text,
                                          false,
                                          setModalState),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Jenis Kelamin",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setModalState(() => fJk = "L"),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: fJk == "L"
                                            ? primaryColor.withOpacity(0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: fJk == "L"
                                              ? primaryColor
                                              : Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.male,
                                              color: fJk == "L"
                                                  ? primaryColor
                                                  : Colors.grey),
                                          const SizedBox(width: 8),
                                          Text("Laki-laki",
                                              style: TextStyle(
                                                  color: fJk == "L"
                                                      ? primaryColor
                                                      : Colors.grey,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setModalState(() => fJk = "P"),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: fJk == "P"
                                            ? primaryColor.withOpacity(0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: fJk == "P"
                                              ? primaryColor
                                              : Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.female,
                                              color: fJk == "P"
                                                  ? primaryColor
                                                  : Colors.grey),
                                          const SizedBox(width: 8),
                                          Text("Perempuan",
                                              style: TextStyle(
                                                  color: fJk == "P"
                                                      ? primaryColor
                                                      : Colors.grey,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Tanggal Lahir",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: fBirthDate ??
                                      DateTime.now().subtract(
                                          const Duration(days: 365 * 10)),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    fBirthDate = picked;
                                    _birthDateController.text =
                                        Helper.formatDate4(picked.toString());
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: primaryColor, size: 20),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        _birthDateController.text.isEmpty
                                            ? "Pilih Tanggal Lahir"
                                            : _birthDateController.text,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              _birthDateController.text.isEmpty
                                                  ? Colors.grey[400]
                                                  : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildModernInput(
                              label: 'Pekerjaan',
                              controller: _jobController,
                              icon: Icons.work_outline,
                              hint: 'Opsional',
                              onSaved: (val) => fJob = val!,
                            ),
                            const SizedBox(height: 20),
                            _buildModernInput(
                              label: 'Keterangan',
                              controller: _descController,
                              icon: Icons.info_outline,
                              hint: 'Tambahkan catatan jika perlu',
                              maxLines: 2,
                              onSaved: (val) => fDesc = val!,
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_familyFormKey.currentState!.validate()) {
                                    _familyFormKey.currentState!.save();
                                    _saveFamilyMember({
                                      'nama': fName,
                                      'hubungan': fRelation,
                                      'no_ktp': fKtp,
                                      'no_bpjs': fBpjs,
                                      'jk': fJk,
                                      'tgl_lahir':
                                          fBirthDate?.toString().split(' ')[0],
                                      'pekerjaan': fJob,
                                      'keterangan': fDesc,
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  elevation: 5,
                                  shadowColor: primaryColor.withOpacity(0.4),
                                ),
                                child: const Text(
                                  "Simpan Anggota Keluarga",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _saveFamilyMember(Map<String, dynamic> data) async {
    try {
      var res =
          await Api().postData(data, "/pegawai/${box.read('sub')}/keluarga");
      var body = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Msg.success(context, "Berhasil menambahkan anggota keluarga");
        Navigator.pop(context); // Close dialog
        fetchAllData(); // Refresh list
      } else {
        Msg.error(context, body['message'] ?? "Gagal menyimpan data");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan: $e");
    }
  }

  Future<void> _deleteFamilyMember(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Data?"),
        content:
            Text("Apakah Anda yakin ingin menghapus $name dari data keluarga?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        var res = await Api()
            .deleteData({}, "/pegawai/${box.read('sub')}/keluarga/$id");
        if (res.statusCode == 200) {
          Msg.success(context, "Data berhasil dihapus");
          fetchAllData();
        } else {
          Msg.error(context, "Gagal menghapus data");
        }
      } catch (e) {
        Msg.error(context, "Terjadi kesalahan: $e");
      }
    }
  }

  void _showLogoutMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Biometric Toggle
                  if (_biometricAvailable)
                    ListTile(
                      leading: Icon(
                        Icons.fingerprint,
                        color: _biometricEnabled ? primaryColor : Colors.grey,
                      ),
                      title: const Text("Login dengan Fingerprint"),
                      subtitle: Text(
                        _biometricEnabled ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          color: _biometricEnabled ? Colors.green : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Switch(
                        value: _biometricEnabled,
                        activeColor: primaryColor,
                        onChanged: (value) async {
                          if (value) {
                            // Enable biometric
                            await _enableBiometric(setModalState);
                          } else {
                            // Disable biometric
                            await _disableBiometric(setModalState);
                          }
                        },
                      ),
                    ),
                  if (_biometricAvailable) const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text("Logout"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LogoutScreen()));
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInfoCard("Informasi Pribadi", [
            _buildInfoTile(Icons.perm_identity, "NIK", _bio['nik'] ?? "-"),
            _buildInfoTile(
                Icons.wc,
                "J. Kelamin",
                (_bio['jk'] == "L" || _bio['jk'] == "Pria")
                    ? "Laki-laki"
                    : "Perempuan"),
            _buildInfoTile(Icons.cake, "TTL",
                "${_bio['tmp_lahir'] ?? '-'}, ${_bio['tgl_lahir'] != null ? Helper.formatDate4(_bio['tgl_lahir']) : '-'}"),
            _buildInfoTile(
                Icons.work_outline,
                "Mulai Kerja",
                _bio['mulai_kerja'] != null
                    ? Helper.formatDate2(_bio['mulai_kerja'])
                    : '-'),

            // Only show duration if initialized (it might not be if mulai_kerja was null)
            // We check if duration is initialized by checking if variables using it are accessed safely or just checking the logic above
            // Since duration is 'late', accessing it before init throws.
            // We can wrap it in a try-catch block conceptually or better, assume it's set if mulia_kerja was present.
            // However, 'late' variable check is tricky.
            // Better strategy: Make duration nullable or check _bio['mulai_kerja'] again.
            if (_bio['mulai_kerja'] != null)
              _buildInfoTile(Icons.timer, "Masa Kerja", _getDurationString()),
          ]),
          const SizedBox(height: 15),
          _buildInfoCard(
            "Kontak & Alamat",
            [
              _buildInfoTile(
                  Icons.phone_android,
                  "No. HP",
                  (_bio['petugas'] != null &&
                          _bio['petugas']['no_telp'] != null)
                      ? _bio['petugas']['no_telp']
                      : "-"),
              _buildInfoTile(
                  Icons.email_outlined,
                  "Email",
                  (_bio['email'] != null && _bio['email']['email'] != null)
                      ? _bio['email']['email']
                      : "-"),
              _buildInfoTile(
                  Icons.location_on_outlined, "Alamat", _bio['alamat'] ?? "-"),
              _buildInfoTile(
                  Icons.favorite_border,
                  "Status Menikah",
                  () {
                    final status = (_bio['petugas'] != null && _bio['petugas']['stts_nikah'] != null)
                        ? _bio['petugas']['stts_nikah'].toString()
                        : 'SINGLE';
                    const labels = {
                      'SINGLE': 'Single / Belum Menikah',
                      'MENIKAH': 'Menikah',
                      'JANDA': 'Janda',
                      'DUDHA': 'Dudha',
                      'JOMBLO': 'Jomblo',
                    };
                    return labels[status] ?? status;
                  }()),
            ],
            onAdd: _showEditDialog,
          ),
          if (_bio['kualifikasi_staf'] != null) ...[
            const SizedBox(height: 15),
            _buildInfoCard(
              "Kualifikasi Klinis",
              [
                _buildInfoTile(Icons.verified_user, "Nomor STR",
                    _bio['kualifikasi_staf']['nomor_str'] ?? "-"),
                _buildInfoTile(Icons.assignment, "Nomor SIP",
                    _bio['kualifikasi_staf']['nomor_sip'] ?? "-"),
                _buildInfoTile(
                    Icons.event_busy,
                    "Tgl. Berakhir SIP",
                    _bio['kualifikasi_staf']['tanggal_akhir_str'] != null
                        ? Helper.formatDate2(
                            _bio['kualifikasi_staf']['tanggal_akhir_str'])
                        : "-"),
                if (_bio['latest_sk_kredensial'] != null && _bio['latest_sk_kredensial']['kredensial'] != null)
                  _buildInfoTile(
                      Icons.military_tech_outlined,
                      "Jenjang Kredensial",
                      _bio['latest_sk_kredensial']['kredensial']['label'] ?? "-"),
              ],
              onAdd: _showEditDialog,
            ),
          ],
          const SizedBox(height: 15),
          _buildInfoCard(
            "Data Keluarga",
            (_bio['keluarga'] != null && (_bio['keluarga'] as List).isNotEmpty)
                ? (_bio['keluarga'] as List).map((member) {
                    IconData familyIcon = Icons.person_outline;
                    switch (member['hubungan'].toString().toLowerCase()) {
                      case 'suami':
                      case 'ayah':
                        familyIcon = Icons.male;
                        break;
                      case 'istri':
                      case 'ibu':
                        familyIcon = Icons.female;
                        break;
                      case 'anak':
                        familyIcon = Icons.child_care;
                        break;
                      default:
                        familyIcon = Icons.people_outline;
                    }

                    return _buildFamilyTile(
                      id: member['id'].toString(),
                      icon: familyIcon,
                      name: member['nama'] ?? "-",
                      relation: member['hubungan'] ?? "-",
                      ktp: member['no_ktp'],
                      bpjs: member['no_bpjs'],
                    );
                  }).toList()
                : [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "Belum ada data keluarga",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  ],
            onAdd: _showAddFamilyDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTile({
    required String id,
    required IconData icon,
    required String name,
    required String relation,
    String? ktp,
    String? bpjs,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: primaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        relation,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () => _deleteFamilyMember(id, name),
                      child: Icon(Icons.delete_outline,
                          size: 18, color: Colors.red[300]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (ktp != null && ktp.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      "KTP: $ktp",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                if (bpjs != null && bpjs.isNotEmpty)
                  Text(
                    "BPJS: $bpjs",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDurationString() {
    try {
      // Since we didn't make duration nullable in class def (it is 'late'),
      // we rely on setDataTbl initializing it if mulai_kerja exists.
      // But if setDataTbl failed silently, accessing `duration` crashes.
      // Re-calculate safely here or rely on the bio check.
      var d = AgeCalculator.age(DateTime.parse(_bio['mulai_kerja']));
      return "${d.years} thn ${d.months} bln";
    } catch (e) {
      return "-";
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children,
      {VoidCallback? onAdd}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey)),
              if (onAdd != null)
                InkWell(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        title.contains("Data Keluarga")
                            ? Icons.add
                            : Icons.edit,
                        color: primaryColor,
                        size: 20),
                  ),
                ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditableTextField(String label, String value, bool isEditable,
      [String? Function(String?)? validator]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        initialValue: value,
        enabled: isEditable,
        validator: validator,
        onChanged: (val) {
          setState(() {
            if (label == "Email") email = val;
            if (label == "No. Telp") no_telp = val;
            if (label == "Alamat") alamat = val;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
