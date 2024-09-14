import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_daftar_hadir.dart';
import 'package:rsia_employee_app/components/cards/card_notulen.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/screen/page/scan.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/utils/table.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rsia_employee_app/config/colors.dart';

class Undangan extends StatefulWidget {
  const Undangan({super.key});

  @override
  State<Undangan> createState() => _UndanganState();
}

class _UndanganState extends State<Undangan> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final box = GetStorage();

  List dataUndangan = [];
  Map links = {};
  Map meta = {};

  bool isLoading = true;
  bool btnLoading = false;

  @override
  void initState() {
    fetchUndangan().then((value) {
      _setData(value['data'] ?? []);

      setState(() {
        meta = value['meta'] ?? [];
        links = value['links'] ?? [];
      });
    });
    super.initState();
  }

  Future fetchUndangan() async {
    var res = await Api().postData({
      "filters": [ { "field": "penerima", "operator": "=", "value": box.read('sub') } ],
      "sort": [ { "field": "created_at", "direction": "desc" } ]
    }, '/undangan/search');

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
    setState(() {
      dataUndangan = value ?? [];
      isLoading = false;
    });
  }

  Future<void> loadMore() async {
    if (links['next'] != null) {
      var res = await Api().postFullUrl({
        "filters": [ { "field": "penerima", "operator": "=", "value": box.read('sub') } ],
        "sort": [ { "field": "created_at", "direction": "desc" } ]
      }, links['next']);

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        setState(() {
          dataUndangan.addAll(body['data'] ?? []);
          meta = body['meta'] ?? [];
          links = body['links'] ?? [];
        });
      } else {
        var body = json.decode(res.body);
        Msg.error(context, body['message']);
        setState(() {
          btnLoading = false;
        });
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingku();
    } else {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            "Undangan",
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
        body: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          controller: _refreshController,
          header: const WaterDropHeader(),
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 1000));
            _refreshController.refreshCompleted();
          },
          onLoading: () async {
            await loadMore();

            if (links['next'] == null) {
              _refreshController.loadNoData();
            } else {
              _refreshController.loadComplete();
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
            itemCount: dataUndangan.isEmpty ? 1 : dataUndangan.length,
            itemBuilder: (context, i) {
              if (dataUndangan.isEmpty) {
                return Center(
                  child: Text(
                    "Data tidak ditemukan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: fontSemiBold,
                    ),
                  ),
                );
              } else {
                var dataUdgn = dataUndangan[i];
                return InkWell(
                  onTap: () => showModalBottomSheet(
                    showDragHandle: true,
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            dataUdgn['undangan']['perihal'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: fontSemiBold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GenTable(data: {
                            // format date to indonesia with month name name day asia/jakarta
                            "Tanggal": DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(dataUdgn['undangan']['tanggal'])),
                            "Waktu": "${DateFormat('HH:mm').format(DateTime.parse(dataUdgn['undangan']['tanggal']))} WIB",
                            "Tempat": dataUdgn['undangan']['tempat'],
                          }),
                          const SizedBox(height: 10),
                          Flex(
                            direction: Axis.horizontal,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: textWhite,
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                    ),
                                    onPressed: () {
                                      Navigator.push(context,MaterialPageRoute(builder: (context) => CardDaftarHadir(dataUdgn: dataUdgn)));
                                    },
                                    child: const Text("Daftar Hadir"),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: textWhite,
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                    ),
                                    onPressed: () {
                                      Navigator.push(context,MaterialPageRoute(builder: (context) => CardNotulen(dataUdgn: dataUdgn)));
                                    },
                                    child: const Text("Notulen"),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    semanticContainer: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(
                            color: (dataUdgn['undangan'] != null && dataUdgn['undangan']['tanggal'] != null)
                                ? DateTime.parse(dataUdgn['undangan']['tanggal']).isAfter(DateTime.now())
                                  ? Colors.blue
                                  : Colors.green
                                : Colors.grey, // fallback color if undangan or tanggal is null
                            width: 6,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        title: Text(
                          dataUdgn['undangan']['perihal'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: fontSemiBold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            dataUdgn['undangan'] != null && dataUdgn['undangan']['tanggal'] != null
                                ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                .add_jm()
                                .format(DateTime.parse(dataUdgn['undangan']['tanggal']))
                                : 'Tanggal tidak tersedia',  // Fallback text if undangan or tanggal is null
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // push to QRAttendanceScanPage class
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => const QRAttendanceScanPage(),
              ),
            );
          },
          // rounded circle
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          backgroundColor: primaryColor,
          child: Icon( Icons.qr_code_scanner, color: textWhite ),
        ),
      );
    }
  }
}
