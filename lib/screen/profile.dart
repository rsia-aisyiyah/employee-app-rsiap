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
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/utils/section_title.dart';

import '../utils/table.dart';

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

  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    await _getBio();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getBio() async {
    var res = await Api().getData("/pegawai/${box.read('sub')}?include=dep,petugas,email,statusKerja");
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      if (mounted) {
        setState(() {
          _bio = body['data'];
          setDataTbl(_bio);
        });
      }
    }
  }

  Future<void> updateProfil() async {
    var data = { 'email': email, 'no_telp': no_telp, 'alamat': alamat };
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
    duration = AgeCalculator.age(DateTime.parse(detailBio['mulai_kerja']));
    dataTbl = {
      "No. KTP": detailBio['no_ktp'],
      "Jenis Kelamin": detailBio['jk'],
      "Tempat & Tanggal Lahir": "${detailBio['tmp_lahir']}, ${Helper.formatDate4(detailBio['tgl_lahir'])}",
      "Alamat": detailBio['alamat'],
      "Pendidikan": detailBio['pendidikan'],
      "Jabatan": detailBio['jbtn'],
      "Bidang": detailBio['bidang'],
      "Status": detailBio['status_kerja']['ktg'],
      "Mulai Kontrak": Helper.formatDate2(detailBio['mulai_kontrak']),
    };
    dataTbl2 = {
      "No. HP": detailBio['petugas']['no_telp'] ?? '-',
      "Email": detailBio['email'] != null ? detailBio['email']['email'] : "-",
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingku();
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
            _buildSortBio(),
            const SizedBox(height: 10),
            _buildProfileInfo(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Container(
              height: 110 + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage("assets/images/depan-rsia.jpg"),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
                color: primaryColor.withOpacity(0.4),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildHeaderLogo('assets/images/logo-rsia-aisyiyah.png'),
                  _buildHeaderLogo('assets/images/logo-larsi.png'),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
        Positioned(
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildProfilePicture(),
          ),
        ),
      ],
    );
  }

  Widget _buildSortBio() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _bio['nama'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            _bio['nik'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 10),
          Text(
            _bio['dep']['nama'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderLogo(String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Image.asset(
        imagePath,
        height: 80 + MediaQuery.of(context).padding.top,
        width: 85,
      ),
    );
  }

  Widget _buildProfilePicture() {
    return InkWell(
      onTap: _showLogoutMenu,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100.0),
              border: Border.all(
                color: bgColor,
                width: 5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100.0),
              child: CachedNetworkImage(
                imageUrl: photoUrl + (_bio['photo'] ?? ''),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) => _buildImageError(),
              ),
            ),
          ),
          _buildProfileDetails(),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          color: bgColor,
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.error),
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "Masa Kerja : ${duration.years} th ${duration.months} bln ${duration.days} hr ",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "Mulai bergabung ${Helper.formatDate3(_bio['mulai_kerja'].toString())}",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  void _showLogoutMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 100, 100),
      items: [
        PopupMenuItem(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogoutScreen(),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.logout),
                SizedBox(width: 10),
                Text('Logout'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: bgWhite,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(width: 0.5),
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -20,
              right: -5,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  padding: const EdgeInsets.all(5),
                  minimumSize: const Size(25, 25),
                  shape: const RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1.0,
                      color: Colors.black,
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      topLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
                onPressed: () async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        iconPadding: const EdgeInsets.only(top: 15, bottom: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: const Text("Form Edit Profile"),
                        content: SingleChildScrollView(
                          padding: const EdgeInsets.all(0.0),
                          child: _buildFormEditProfile(),
                        ),
                      );
                    }
                  );
                },
                child: const Row(
                  children: [
                    Icon( Icons.edit_outlined, size: 18, color: Colors.black),
                    Text( " |", style: TextStyle(color: Colors.black)),
                    Text( "| Edit Data", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const SectionTitle(title: "Biodata"),
                  GenTable(data: dataTbl),
                  const SizedBox(height: 15),
                  const SectionTitle(title: "Kontak"),
                  GenTable(data: dataTbl2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormEditProfile() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            child: Column(
              children: [
                TextFormField(
                  initialValue: _bio['email']['email'].toString(),
                  maxLines: 1,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 10.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: 'Masukkan email disini',
                    labelText: 'Email',
                  ),
                  onSaved: (value) => email = value!,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Field tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _bio['petugas']['no_telp'].toString(),
                  maxLines: 1,
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: 'Masukkan no. handphone disini',
                      labelText: 'No. HP'),
                  onSaved: (value) => no_telp = value!,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Field tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _bio['alamat'].toString(),
                  maxLines: 5,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 10.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: 'Masukkan alamat disini',
                    labelText: 'Alamat',
                  ),
                  onSaved: (value) => alamat = value!,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Field tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 10)
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
            child: _buildSaveButton()
          ),
        ],
      ),
    );
  }

  Widget buildEditableTextField(String label, String value, bool isEditable, [String? Function(String?)? validator]) {
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

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();

          if (!EmailValidator.validate(email)) {
            Msg.error(context, 'Format Email tidak sesuai');
            return;
          }

          if (no_telp.isEmpty) {
            Msg.error(context, 'No. Telp tidak boleh kosong');
            return;
          }

          if (alamat.isEmpty) {
            Msg.error(context, 'Alamat tidak boleh kosong');
            return;
          }

          updateProfil();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: const Text('Simpan Perubahan'),
    );
  }
}