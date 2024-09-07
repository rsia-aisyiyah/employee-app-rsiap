import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_berkas_pegawai.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class BerkasPegawai extends StatefulWidget {
  const BerkasPegawai({super.key});

  @override
  State<BerkasPegawai> createState() => _BerkasPegawaiState();
}

class _BerkasPegawaiState extends State<BerkasPegawai> {
  final box = GetStorage();
  List dataBerkas = [];
  Map links = {};
  Map meta = {};
  bool isLoding = true;

  @override
  void initState() {
    super.initState();
    fetchBerkas().then((value) {
      if (mounted) {
        _setData(value);
      }
    });
  }


  _setData(value) {
    setState(() {
      dataBerkas = value['data'] ?? [];
      links = value['links'] ?? {};
      meta = value['meta'] ?? {};
      isLoding = false;
    });
  }

  Future fetchBerkas() async {
    var res = await Api().getData("/pegawai/${box.read('sub')}/berkas");
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);
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
            "Berkas Kepegawaian",
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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                itemCount: dataBerkas.isEmpty ? 1 : dataBerkas.length,
                itemBuilder: (context, index) {
                  if (dataBerkas.isNotEmpty) {
                    return InkWell(
                      onTap: () {},
                      child: CardBerkasPegawai(
                          dataBerkasPegawai: dataBerkas[index],
                      ),
                    );
                  }

                  return null;
                },
              )
            ],
          ),
        ),
      );
    }
  }
}
