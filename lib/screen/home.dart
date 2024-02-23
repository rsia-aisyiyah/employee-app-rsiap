import 'dart:convert';
// import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;
  int selectedTab = 0;
  String nik = "";
  Map _bio = {};
  Map _jadwal = {};
  Map _tempPresensi = {};
  Map _rekapPresensi = {};

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
      _getJadwal(),
      _getTempPresensi(),
      _getRekapPresensi(),
      // _getMetricsToday(),
      // _getJadwalOperasiNow(),
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
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _bio = {};
        });
      }
    }
  }

  Future<void> _getJadwal() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());
    nik = decodeToken['sub'];
    var res = await Api().postData({'nik': nik}, '/pegawai/jadwal/now');
    var body = json.decode(res.body);
    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          _jadwal = body['data']['jam_masuk'] ?? {};
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _jadwal = {};
        });
      }
    }
  }

  Future<void> _getTempPresensi() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());
    nik = decodeToken['sub'];

    var res = await Api().postData({'nik': nik}, '/pegawai/presensi/tmp');
    var body = json.decode(res.body);
    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          _tempPresensi = body['data'];
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _tempPresensi = {};
        });
      }
    }
  }

  Future<void> _getRekapPresensi() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());
    nik = decodeToken['sub'];
    var res = await Api().postData({'nik': nik}, '/pegawai/presensi/rekap/now');
    var body = json.decode(res.body);
    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          _rekapPresensi = body['data'];
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _rekapPresensi = {};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? loadingku()
        : Scaffold(
            extendBody: true,
            backgroundColor: bgColor,
            body: Container(
              height: MediaQuery.of(context).size.height,
              // decoration: const BoxDecoration(
              //   image: DecorationImage(
              //     image: AssetImage('assets/images/splash-bg.png'),
              //     fit: BoxFit.cover,
              //     alignment: Alignment.center,
              //   ),
              // ),
              child: SingleChildScrollView(
                // height: MediaQuery.of(context).size.height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).padding.top,
                      child: Container(
                        color: primaryColor,
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0),
                          ),
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 5, left: 20),
                                  child: Image.asset(
                                    'assets/images/logo-rsia-aisyiyah.png',
                                    height: 90,
                                    width: 110,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Image.asset(
                                    'assets/images/logo-larsi.png',
                                    height: 90,
                                    width: 110,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 80,
                          bottom: -80,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                // border: Border.all(
                                //   color: primaryColor.withOpacity(0.5),
                                //   width: 1.3,
                                // ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(15.0),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Assalamu'alaikum"),
                                              Text(
                                                _bio['nama'].toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              Text(
                                                _bio['nik'].toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(100.0),
                                            border: Border.all(
                                              color: bgColor,
                                              width: 2.5,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(100.0),
                                            child: CachedNetworkImage(
                                              imageUrl: photoUrl + _bio['photo'].toString(),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.topCenter,
                                              placeholder: (
                                                context,
                                                url,
                                              ) => Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    color: bgColor,
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (
                                                context,
                                                url,
                                                error,
                                              ) => Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text( _jadwal['shift'] != null
                                            ? _jadwal['shift'].toString()
                                            : "Libur",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        _jadwal['shift'] != null
                                          ? Text( 
                                              " (" + _jadwal['jam_masuk'].toString().substring(
                                                      0,
                                                      _jadwal['jam_masuk'].toString() .length - 3) +
                                              " - " + _jadwal['jam_pulang'].toString()
                                                  .substring(
                                                      0,
                                                      _jadwal['jam_pulang'].toString().length -3) +
                                              ")",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            )
                                          : Text(" -"),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      // CrossAxisAlignment.stretch,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "IN ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.green,
                                              ),
                                            ),
                                            Text(
                                              _rekapPresensi.isEmpty && _tempPresensi.isEmpty
                                                ? "-"
                                                : _rekapPresensi.isEmpty
                                                    ? DateFormat.Hms().format(
                                                        DateTime.parse(
                                                          _tempPresensi[
                                                              'jam_datang'],
                                                        ),
                                                      )
                                                    : DateFormat.Hms().format(
                                                        DateTime.parse(
                                                          _rekapPresensi[
                                                              'jam_datang'],
                                                        ),
                                                      ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 20),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "OUT ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.red,
                                              ),
                                            ),
                                            Text(
                                              _rekapPresensi.isEmpty
                                                ? "-"
                                                : DateFormat.Hms().format(
                                                    DateTime.parse(
                                                      _rekapPresensi[
                                                          'jam_pulang'],
                                                    ),
                                                  ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 20),
                                        Column(
                                          children: [
                                            Text(
                                              "Status ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              _rekapPresensi.isEmpty && _tempPresensi.isEmpty
                                                  ? "-"
                                                  : _rekapPresensi.isEmpty
                                                      ? _tempPresensi['status']
                                                          .toString()
                                                      : _rekapPresensi['status']
                                                          .toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 90,
                    ),
                    GridView.builder(
                      itemCount: menuScreenItems.length,
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 5,
                        top: 0,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            if (menuScreenItems[index]['disabled'] == true) {
                              Msg.warning(context, featureNotAvailableMsg);
                            } else {
                              if (menuScreenItems[index]['widget'] == "") {
                                Msg.warning(context, featureNotAvailableMsg);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => menuScreenItems[index]['widget'] as Widget,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: menuScreenItems[index]['disabled'] == true
                                  ? Colors.grey[300]
                                  : bgWhite,
                              borderRadius: BorderRadius.circular(10),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: primaryColor.withOpacity(0.2),
                              //     offset: Offset(0, 3),
                              //     blurRadius: 5,
                              //   ),
                              // ],
                              // border: Border.all(
                              //   color:
                              //       menuScreenItems[index]['disabled'] == true
                              //           ? Colors.grey[400]!
                              //           : primaryColor.withOpacity(0.5),
                              //   width: 1.3,
                              // ),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        menuScreenItems[index]['label'].toString(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: menuScreenItems[index]['disabled'] == true
                                              ? bgWhite
                                              : textColor,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: -8,
                                  right: -15,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.22,
                                    child: Transform(
                                      transform: Matrix4.rotationZ(0.3),
                                      child: Icon(
                                        menuScreenItems[index]['icon'] as IconData,
                                        size: 80,
                                        color: menuScreenItems[index]['disabled'] ==true
                                          ? bgWhite
                                          : primaryColor.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: 60,
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
