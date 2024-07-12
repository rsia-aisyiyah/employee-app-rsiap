import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardNotulen extends StatefulWidget {
  final Map dataUdgn;

  const CardNotulen({super.key, required this.dataUdgn});

  @override
  State<CardNotulen> createState() => _CardNotulenState();
}

class _CardNotulenState extends State<CardNotulen> {
  String text = lorem(paragraphs: 15, words: 150);
  Map dataNotulen = {};
  bool isLoading = true;
  bool btnLoading = false;

  @override
  void initState() {
    // getSub();
    fetchNotulen().then((value) {
      _setData(value);
    });
    super.initState();
  }

  // void getSub() async {
  //   SharedPreferences pref = await SharedPreferences.getInstance();
  //   setState(() {
  //     sub = pref.getString('sub')!.replaceAll('"', '');
  //   });
  // }

  // fetch undangan on undangan/me
  Future fetchNotulen() async {
    var res = await Api().getData('/berkas/notulen/' +
        widget.dataUdgn['no_surat'].toString().replaceAll('/', '--') +
        '/show');
    print('/berkas/notulen/' +
        widget.dataUdgn['no_surat'].toString().replaceAll('/', '--') +
        '/show');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);
      return body;
    }
  }

  void _setData(value) {
    if (value['success']) {
      setState(() {
        dataNotulen = value['data'] ?? [];
        // print(dataNotulen['pembahasan']);
        // nextPageUrl = value['data']['next_page_url'] ?? '';
        // prevPageUrl = value['data']['prev_page_url'] ?? '';
        // currentPage = value['data']['current_page'].toString();
        // lastPage = value['data']['last_page'].toString();

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        dataNotulen = value['data'] ?? [];
        var test = value['message'];
        print(test);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingku();
    } else {
      return Scaffold(
        backgroundColor: bgWhite.withAlpha(500),
        appBar: AppBar(
          title: Text(
            "Notulen Rapat",
            style: TextStyle(
              color: textWhite,
              fontSize: 18,
              fontWeight: fontSemiBold,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: textWhite,
            ),
          ),
        ),
        body: Container(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Stack(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor,width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                            color: bgWhite.withOpacity(0.8)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black),
                                    "NOTULEN RAPAT",
                                  ),
                                  SizedBox(
                                    height: 8,
                                  )
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black),
                                    dataNotulen['surat']['perihal'].toString(),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                      style: TextStyle(color: Colors.black),
                                      Helper.formatDate(
                                              dataNotulen['surat']['tanggal']) +
                                          ' ' +
                                          Helper.dateTimeToDate(
                                              dataNotulen['surat']['tanggal'])),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(style: TextStyle(color: Colors.black),dataNotulen['surat']['tempat']
                                      .toString()),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          decoration: BoxDecoration(
                              boxShadow: [],
                              border: Border.all(color: primaryColor,width: 1.5),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10)),
                              color: bgColor),
                          child: Padding(
                              padding: const EdgeInsets.only(
                                left: 3,
                                right: 3,
                                top: 3,
                                bottom: 3,
                              ),
                              child: Icon(
                                Icons.edit_note,
                                color: primaryColor,
                                size: 20,
                              )),
                        ),
                      )
                    ],
                  ),
                ),
                // SizedBox(
                //   height: 5,
                // ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor,width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                        color: bgWhite),
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: Scrollbar(
                        thickness: 10,
                        //width of scrollbar
                        radius: Radius.circular(10),
                        //corner radius of scrollbar
                        scrollbarOrientation: ScrollbarOrientation.right,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pemimpin Rapat : ",
                                  style: TextStyle(fontWeight: FontWeight.w600,color: Colors.black),
                                ),
                                Text(
                                  dataNotulen['surat']['penanggung_jawab']
                                          ['nama']
                                      .toString(),
                                  style: TextStyle(fontWeight: FontWeight.w500,color: Colors.black),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Notulis : ",
                                  style: TextStyle(fontWeight: FontWeight.w600,color: Colors.black),
                                ),
                                Text(
                                  dataNotulen['notulis']['nama'].toString(),
                                  style: TextStyle(fontWeight: FontWeight.w500,color: Colors.black),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Pembahasan : ",
                                  style: TextStyle(fontWeight: FontWeight.w600,color: Colors.black),
                                ),
                                HtmlWidget(
                                    textStyle:
                                        TextStyle(fontSize: 14, height: 1.5,color: Colors.black),
                                    dataNotulen['pembahasan'].toString())
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
