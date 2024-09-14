import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/helper.dart';

import '../../config/config.dart';

class CardNotulen extends StatefulWidget {
  final Map dataUdgn;

  const CardNotulen({super.key, required this.dataUdgn});

  @override
  State<CardNotulen> createState() => _CardNotulenState();
}

class _CardNotulenState extends State<CardNotulen> {
    @override
  void initState() {
    super.initState();
  }

  Future fetchNotulen() async {
    final String url = "/undangan/${base64Encode(utf8.encode(widget.dataUdgn['no_surat'].toString()))}/notulen";
    var res = await Api().getData(url);

    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      return body;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder(
        future: fetchNotulen(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var data = snapshot.data['data'];
            
            if (data == null || data.isEmpty) {
              return const Center(
                child: Text("Data notulen tidak ditemukan"),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox( height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              border: Border.all(color: primaryColor,width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                              color: bgWhite.withOpacity(0.8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                      ),
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
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                      ),
                                      data['perihal'].toString(),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                        style: const TextStyle(color: Colors.black),
                                        '${Helper.formatDate(data['tanggal'])} ${Helper.dateTimeToDate(data['tanggal'])}',
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(style: const TextStyle(color: Colors.black),data['tempat'].toString()),
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
                                boxShadow: const [],
                                border: Border.all(color: primaryColor,width: 1.5),
                                borderRadius: const BorderRadius.only(
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
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          border: Border.all(color: primaryColor,width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                          color: bgWhite,
                      ),
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: Scrollbar(
                          thickness: 10,
                          //width of scrollbar
                          radius: const Radius.circular(10),
                          //corner radius of scrollbar
                          scrollbarOrientation: ScrollbarOrientation.right,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Pemimpin Rapat : ",
                                    style: TextStyle(fontWeight: FontWeight.w600,color: Colors.black),
                                  ),
                                  Text(
                                    data['penanggung_jawab']['nama'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w400,color: Colors.black),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  const Text(
                                    "Notulis : ",
                                    style: TextStyle(fontWeight: FontWeight.w600,color: Colors.black),
                                  ),
                                  Text(
                                    data['notulen'] == null ? "-" : data['notulen']['nama'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w400,color: Colors.black),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  const Text(
                                    "Pembahasan : ",
                                    style: TextStyle(fontWeight: FontWeight.w600,color: Colors.black),
                                  ),
                                  HtmlWidget(
                                      textStyle: const TextStyle(fontSize: 14, height: 1.5,color: Colors.black),
                                      data['notulen'] == null ? "-" : data['notulen']['pembahasan'].toString(),
                                  ),


                                  // created at and updated at
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    "Dibuat Pada : ${data['notulen'] == null ? "-" : Helper.formatDate(data['notulen']['created_at'])}",
                                    style: const TextStyle(fontWeight: FontWeight.w400,color: Colors.black45, fontSize: 12),
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    "Terakhir diubah : ${data['notulen'] == null ? "-" : Helper.formatDate(data['notulen']['updated_at'])}",
                                    style: const TextStyle(fontWeight: FontWeight.w400,color: Colors.black45, fontSize: 12),
                                  ),
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
            );
          }

          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }

          return loadingku();
        },
      ),
    );
  }
}
