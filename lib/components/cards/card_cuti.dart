import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class CardCuti extends StatefulWidget {
  final Map dataCuti;
  final VoidCallback onDelete;

  const CardCuti({
    super.key,
    required this.dataCuti,
    required this.onDelete,
  });

  @override
  State<CardCuti> createState() => _CardCutiState();
}

class _CardCutiState extends State<CardCuti> {
  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  // Future _deleteData(data) async {
  //   var res = await Api().deleteData({'id_cuti': data}, '/pegawai/cuti/delete');
  //   if (res.statusCode == 200) {
  //     var body = json.decode(res.body);
  //     Msg.success(context, body['message']);
  //     widget.getData;
  //     // setState(() {});
  //     return body;
  //   } else {
  //     var body = json.decode(res.body);
  //     Msg.error(context, body['message']);
  //     widget.getData;

  //     // setState(() {});
  //     return body;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 90,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: bgWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      height: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            Helper.dayToNum(
                              widget.dataCuti['tanggal_cuti'].toString(),
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              color: textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Helper.daytoMonth(
                              widget.dataCuti['tanggal_cuti'].toString(),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: textWhite,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Text(
                            Helper.daytoYear(
                              widget.dataCuti['tanggal_cuti'].toString(),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Helper.numtoDayFull(widget
                                      .dataCuti['tanggal_cuti']
                                      .toString()),
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  widget.dataCuti['jenis'].toString(),
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                              ],
                            ),
                            widget.dataCuti['status_cuti'].toString() == "2"
                                ? textDisetujui()
                                : widget.dataCuti['status_cuti'].toString() == "0"
                                    ? textPengajuan()
                                    : textDitolak(),
                            // Icon(
                            //   Icons.check_circle_rounded,
                            //   color: Colors.green,
                            //   size: 28,
                            // )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            widget.dataCuti['status_cuti'].toString() == "0"
                ? Positioned(
                    top: -18,
                    right: -18,
                    child: ElevatedButton(
                      onPressed: () async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              iconPadding: EdgeInsets.only(top: 15,bottom: 10),
                              icon: Icon(Icons.warning,color: Colors.orangeAccent,size: 32,),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              title: const Text("Hapus Pengajuan Cuti"),
                              content: const Text(
                                "Apakah anda yakin akan menghapus pengajuan cuti ?",
                              ),
                              actionsAlignment: MainAxisAlignment.spaceAround,
                              actions: <Widget>[
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("NO"),
                                ),
                                ElevatedButton(
                                  style:
                                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text("YES"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.all(5),
                        minimumSize: Size(25, 25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.dangerous_sharp,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  )
                : Container()
          ],
        ),
        SizedBox(
          height: 10,
        ),
      ],
    );
  }
}

Widget textDisetujui() {
  return Row(
    children: [
      Text(
        "Disetujui",
        style: TextStyle(
          fontSize: 16,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      Icon(
        Icons.check_circle_rounded,
        color: Colors.green,
        size: 28,
      )
    ],
  );
}

Widget textPengajuan() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        "Pengajuan",
        style: TextStyle(
          fontSize: 16,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(width: 10),
      Icon(
        Icons.send_rounded,
        color: Colors.blue,
        size: 20,
      )
    ],
  );
}

Widget textDitolak() {
  return Row(
    children: [
      Text(
        "Ditolak",
        style: TextStyle(
          fontSize: 16,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      Icon(
        Icons.dangerous,
        color: Colors.red,
        size: 28,
      )
    ],
  );
}
