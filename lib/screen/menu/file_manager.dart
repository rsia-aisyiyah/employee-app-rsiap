import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_file_manager.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class FileManager extends StatefulWidget {
  const FileManager({super.key});

  @override
  State<FileManager> createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  bool isLoding = true;
  List dataFileManager = [];
  late String title;

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
  }

  _setData(value) {
    setState(() {
      dataFileManager = value['data'] ?? [];
      isLoding = false;
    });
  }

  Future fetchFileManager() async {
    var res = await Api().getData("/rsia/file/manager");
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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                itemCount: dataFileManager.isEmpty ? 1 : dataFileManager.length,
                itemBuilder: (context, index) {
                  if (dataFileManager.isNotEmpty) {
                    return InkWell(
                      onTap: () {},
                      child: CardFileManager(
                          dataFileManager: dataFileManager[index],
                      ),
                    );
                  }

                  return const Center(
                    child: Text(
                      "Data tidak ditemukan",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      );
    }
  }
}
