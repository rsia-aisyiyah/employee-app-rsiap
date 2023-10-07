import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_file_manager.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileManager extends StatefulWidget {
  const FileManager({super.key});

  @override
  State<FileManager> createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  bool isLoding = true;
  List dataFileManager = [];
  late String title;
  late String url;

  @override
  void initState() {
    super.initState();
    _initialSet();
    fetchFileManager().then((value) {
      if (mounted) {
        _setData(value);
      }
    });
  }

  _initialSet() {
    title = "Dokumen & Surat";
    url = "/file-manager";
  }

  _setData(value) {
    print(value['data']);
    if (value['success']) {
      setState(() {
        dataFileManager = value['data'] ?? [];
        isLoding = false;
      });
    } else {
      setState(() {
        isLoding = false;
        dataFileManager = [];
      });
    }
  }

  Future fetchFileManager() async {
    var strUrl = url;
    var res = await Api().getData(strUrl);
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
            "Dokumen & Surat",
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
                itemCount: dataFileManager.isEmpty ? 1 : dataFileManager.length,
                itemBuilder: (context, index) {
                  if (dataFileManager.isNotEmpty) {
                    return InkWell(
                      onTap: () {},
                      child: cardFileManager(
                          dataFileManager: dataFileManager[index]),
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
