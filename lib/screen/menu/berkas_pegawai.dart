import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_berkas_pegawai.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BerkasPegawai extends StatefulWidget {
  const BerkasPegawai({super.key});

  @override
  State<BerkasPegawai> createState() => _BerkasPegawaiState();
}

class _BerkasPegawaiState extends State<BerkasPegawai> {
  SharedPreferences? pref;
  List dataBerkas = [];
  late String title;
  late String url;
  late String nik;
  bool isLoding = true;

  @override
  void initState() {
    super.initState();
    _initialSet();
    fetchBerkas().then((value) {
      if (mounted) {
        _setData(value);
      }
    });
  }

  _initialSet() {
    title = "Berkas Pegawai";
    url = "/pegawai/detail";
  }

  _setData(value) {
    print(value['data']);
    if (value['success']) {
      setState(() {
        dataBerkas = value['data']['berkas_pegawai'] ?? [];
        isLoding = false;
      });
    } else {
      setState(() {
        isLoding = false;
        dataBerkas = [];
      });
    }
  }

  Future fetchBerkas() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());
    nik = decodeToken['sub'];
    var strUrl = url;
    var res = await Api().postData({'nik': nik}, strUrl);
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      print(body);

      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);

      print(body);
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoding) {
      return loadingku();
    } else {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            "Berkas Pegawai",
            style: TextStyle(
              color: textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primaryColor,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                itemCount: dataBerkas.isEmpty ? 1 : dataBerkas.length,
                itemBuilder: (context, index) {
                  if (dataBerkas.isNotEmpty) {
                    return InkWell(
                      onTap: () {},
                      child: cardBerkasPegawai(
                          dataBerkasPegawai: dataBerkas[index]),
                    );
                  }
                },
              )
            ],
          ),
        ),
      );
    }
  }
}
