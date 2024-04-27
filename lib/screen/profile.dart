import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/screen/login.dart';
import 'package:rsia_employee_app/screen/logout.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/utils/section_title.dart';
import 'package:rsia_employee_app/utils/table.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:age_calculator/age_calculator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
  var email = "";
  var no_telp = "";
  var alamat = "";
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (mounted) {
      fetchAllData().then((value) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });
    }
  }

  Future<void> fetchAllData() async {
    List<Future> futures = [
      _getBio(),
    ];

    await Future.wait(futures);
  }

  Future<void> _getBio() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());
    nik = decodeToken['sub'];

    var res = await Api().postData({'nik': nik}, '/pegawai/detail');
    var body = json.decode(res.body);

    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          _bio = body['data'];
          setDataTbl(_bio);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _bio = {};
          setDataTbl(null);
        });
      }
    }
  }

  void _logout() async {
    var res = await Api().postRequest('/auth/logout');
    var body = json.decode(res.body);

    loadingku();
    if (body['success']) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(nik);

      // await FirebaseMessaging.instance.unsubscribeFromTopic('dokter');
      // SharedPreferences.getInstance().then((prefs) async {
      //   var spesialis = prefs.getString('spesialis')!.toLowerCase();
      //   if (spesialis.contains('kandungan')) {
      //     await FirebaseMessaging.instance.unsubscribeFromTopic('kandungan');
      //   } else if (spesialis.contains('umum')) {
      //     await FirebaseMessaging.instance.unsubscribeFromTopic('umum');
      //   }
      // });

      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('token');
        Msg.success(context, logoutSuccessMsg);
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => LoginScreen()),
            (route) => false);
      });
    }
  }

  Future updateProfil() async {
    var data = {
      'nik': nik,
      'email': email,
      'no_telp': no_telp,
      'alamat': alamat,
    };

    var res = await Api().postData(data, '/pegawai/update-profil');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      isSuccess = true;
      Msg.success(context, body['message']);
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (BuildContext ctx) => super.widget
      ));
      return body;
    } else {
      var body = json.decode(res.body);
      isSuccess = false;
      Msg.error(context, body['message']);
      return body;
    }
  }

  void setDataTbl(detailBio) {
    duration = AgeCalculator.age(DateTime.parse(detailBio['mulai_kerja']));
    dataTbl = {
      "No. KTP": detailBio['no_ktp'],
      "Jenis Kelamin": detailBio['jk'],
      "Tempat & Tanggal Lahir": detailBio['tmp_lahir'] +
          ", " +
          Helper.formatDate3(detailBio['tgl_lahir']),
      "Alamat": detailBio['alamat'],
      "Pendidikan": detailBio['pendidikan'],
      "Jabatan": detailBio['jbtn'],
      "Bidang": detailBio['bidang'],
      "Status": detailBio['stts_kerja']['ktg'],
      "Mulai Kontrak": Helper.formatDate2(detailBio['mulai_kontrak']),
    };
    dataTbl2 = {
      "No. HP": detailBio['petugas']['no_telp'] ?? '-',
      "Email": detailBio['rsia_email_pegawai']!=null ? detailBio['rsia_email_pegawai']['email'] : "-",
    };


  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? loadingku()
        : Scaffold(
            backgroundColor: bgColor,
            body: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          Container(
                            height: 110 + MediaQuery.of(context).padding.top,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image:
                                    AssetImage("assets/images/depan-rsia.jpg"),
                                fit: BoxFit.cover,
                                opacity: 0.3,
                              ),
                              color: primaryColor.withOpacity(0.4),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(50),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Image.asset(
                                    'assets/images/logo-rsia-aisyiyah.png',
                                    height:
                                        80 + MediaQuery.of(context).padding.top,
                                    width: 85,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Image.asset(
                                    'assets/images/logo-larsi.png',
                                    height:
                                        80 + MediaQuery.of(context).padding.top,
                                    width: 85,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: InkWell(
                            onTap: () {
                              showMenu(
                                context: context,
                                position:
                                    RelativeRect.fromLTRB(100, 100, 100, 100),
                                items: [
                                  PopupMenuItem(
                                    child: InkWell(
                                      // onTap: () => _logout(),
                                      onTap: () {
                                        // push to logout screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                LogoutScreen(),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.logout,
                                            color: textColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Logout",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
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
                                      imageUrl:
                                          photoUrl + _bio['photo'].toString(),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      placeholder: (context, url) => Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: bgColor,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 50,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        "Masa Kerja : " +
                                            duration.years.toString() +
                                            " th " +
                                            duration.months.toString() +
                                            " bln " +
                                            duration.days.toString() +
                                            " hr ",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        "Mulai bergabung " +
                                            Helper.formatDate3(
                                                _bio['mulai_kerja'].toString()),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _bio['nama'].toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _bio['nik'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _bio['dpt']['nama'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  cardBio(),
                  SizedBox(
                    height: 70,
                  )
                ],
              ),
            ),
          );
  }

  Widget buttonLogout() {
    return InkWell(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.all(8),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(5),
        child: Icon(
          Icons.logout,
          // color: textWhite,
        ),
      ),
    );
  }

  Widget cardBio() {
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
        child: SingleChildScrollView(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -20,
                right: -5,
                child: ElevatedButton(
                  onPressed: () async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Form(
                          key: _formKey,
                          child: AlertDialog(
                            iconPadding: EdgeInsets.only(top: 15, bottom: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: const Text("Form Edit Profile"),
                            content: Container(
                              // height: 400,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(0.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Container(
                                          child: SizedBox(
                                            // height: 50,
                                            child: Column(
                                              children: [
                                                Container(
                                                  child: TextFormField(
                                                    initialValue: _bio['rsia_email_pegawai']['email'].toString(),
                                                    maxLines: 1,
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                        vertical: 10.0,
                                                        horizontal: 10.0,
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(
                                                          10,
                                                        ),
                                                      ),
                                                      hintText:
                                                          'Masukkan email disini',
                                                      labelText: 'Email',
                                                    ),
                                                    onSaved: (value) {
                                                      email = value!;
                                                    },
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Field tidak boleh kosong';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 12,
                                                ),
                                                Container(
                                                  child: TextFormField(
                                                    initialValue: _bio['petugas']['no_telp'].toString(),
                                                    maxLines: 1,
                                                    decoration: InputDecoration(
                                                        contentPadding:EdgeInsets.symmetric(
                                                          vertical: 10.0,
                                                          horizontal: 10.0,
                                                        ),
                                                        border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(
                                                              10,
                                                            ),
                                                        ),
                                                        hintText: 'Masukkan no. handphone disini',
                                                        labelText: 'No. HP'),
                                                    onSaved: (value) {
                                                      no_telp = value!;
                                                    },
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Field tidak boleh kosong';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 12,
                                                ),
                                                Container(
                                                  child: TextFormField(
                                                    initialValue: _bio['alamat'].toString(),
                                                    maxLines: 5,
                                                    decoration: InputDecoration(
                                                      contentPadding: EdgeInsets.symmetric(
                                                        vertical: 10.0,
                                                        horizontal: 10.0,
                                                      ),
                                                      border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(
                                                            10,
                                                          ),
                                                      ),
                                                      hintText: 'Masukkan alamat disini',
                                                      labelText: 'Alamat',
                                                    ),
                                                    onSaved: (value) {
                                                      alamat = value!;
                                                    },
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Field tidak boleh kosong';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          height: 50,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (_formKey.currentState!.validate()) {
                                                _formKey.currentState!.save();
                                                if (EmailValidator.validate(email)) {
                                                  updateProfil();

                                                  if (isSuccess) {
                                                    Navigator.of(context).pop();
                                                  }
                                                } else {
                                                  Msg.error(
                                                    context,
                                                    'Format Email tidak sesuai',
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                            ),
                                            child: Text("Submit"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // actionsAlignment: MainAxisAlignment.spaceAround,
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    padding: EdgeInsets.all(5),
                    minimumSize: Size(25, 25),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.black,
                      ),
                      Text(
                        " |",
                        style: TextStyle(color: Colors.black),
                      ),
                      Text(
                        "| Edit Data",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SectionTitle(title: "Data Pegawai"),
                    GenTable(data: dataTbl),
                    const SizedBox(height: 20),
                    const SectionTitle(title: "Kontak"),
                    GenTable(data: dataTbl2),
                    // const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
