import 'dart:convert';

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
          "/pegawai/${box.read('sub')}?include=dep,petugas,email,statusKerja");

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
    var data = {'email': email, 'no_telp': no_telp, 'alamat': alamat};
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
            const SizedBox(height: 80),
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
                Row(
                  children: [
                    InkWell(
                      onTap: _showEditDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
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

  Widget _buildFormEditProfile() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildModernInput(
            label: 'Email',
            initialValue:
                _bio['email'] != null ? _bio['email']['email'].toString() : '',
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
            maxLines: 3,
            onSaved: (val) => alamat = val!,
            validator: (val) =>
                val == null || val.isEmpty ? 'Alamat wajib diisi' : null,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  if (!EmailValidator.validate(email)) {
                    Msg.error(context, 'Format Email tidak sesuai');
                    return;
                  }
                  updateProfil();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 5,
                shadowColor: primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Simpan Perubahan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInput({
    required String label,
    required String initialValue,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextFormField(
            initialValue: initialValue,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primaryColor),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            ),
            onSaved: onSaved,
            validator: validator,
          ),
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
          _buildInfoCard("Kontak & Alamat", [
            _buildInfoTile(
                Icons.phone_android,
                "No. HP",
                (_bio['petugas'] != null && _bio['petugas']['no_telp'] != null)
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
          ]),
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

  Widget _buildInfoCard(String title, List<Widget> children) {
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
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey)),
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
