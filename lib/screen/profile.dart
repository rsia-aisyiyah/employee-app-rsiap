import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/screen/login.dart';
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
  String nik = "";

  @override
  void initState() {
    super.initState();
    if (mounted) {
      fetchAllData().then((value) {
        if (mounted) {
          setState(() {
            isLoading = false;

            // print(_getBio());
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
    // print(nik);

    // print(nik);
    var res = await Api().postData({'nik': nik}, '/pegawai/detail');
    var body = json.decode(res.body);
    print(body);
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

    if (body['success']) {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      });
    }
  }

  void setDataTbl(detailBio) {
    duration = AgeCalculator.age(DateTime.parse(detailBio['mulai_kontrak']));
    print(duration.years);
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
    };
    dataTbl2 = {
      "No. HP": detailBio['petugas']['no_telp'],
      "Email": detailBio['rsia_email_pegawai']['email'],
    };
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? loadingku()
        : Scaffold(
            backgroundColor: bgColor,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 110,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image:
                                    AssetImage("assets/images/depan-rsia.jpg"),
                                fit: BoxFit.cover,
                                opacity: 0.3),
                            color: primaryColor.withOpacity(0.4),
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(50)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 0),
                                child: Image.asset(
                                  'assets/images/logo-text-rsiap2.png',
                                  // height: 70,
                                  width: 50,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                child: Image.asset(
                                  'assets/images/logo-larsi.png',
                                  // height: 100,
                                  width: 70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                            bottom: -15,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 140),
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
                            )),
                        Positioned(
                            bottom: -30,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 140),
                              child: Text(
                                "Mulai bergabung " +
                                    Helper.formatDate3(
                                        _bio['mulai_kontrak'].toString()),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic),
                              ),
                            )),
                        Positioned(
                          bottom: -55,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
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
                                  imageUrl: photoUrl + _bio['photo'].toString(),
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
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 60,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _bio['nama'].toString(),
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                            fontSize: 14, fontWeight: FontWeight.w400),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _bio['dpt']['nama'].toString(),
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w400),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    cardBio(dataTbl, dataTbl2),
                  ],
                ),
              ),
            ),
          );
  }
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

Widget cardBio(data, data2) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SectionTitle(title: "Data Pegawai"),
            GenTable(data: data),
            const SectionTitle(title: "Kontak"),
            GenTable(data: data2),
            // const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
