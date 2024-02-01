import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/utils/table.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Undangan extends StatefulWidget {
  const Undangan({super.key});

  @override
  State<Undangan> createState() => _UndanganState();
}

class _UndanganState extends State<Undangan> {
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  String sub = "";

  String nextPageUrl = '';
  String prevPageUrl = '';
  String currentPage = '';
  String lastPage = '';

  List dataUndangan = [];

  bool isLoading = true;
  bool btnLoading = false;

  @override
  void initState() {
    getSub();
    fetchUndangan().then((value) {
      _setData(value);
    });
    super.initState();
  }

  // async function get from local storage
  void getSub() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      sub = pref.getString('sub')!.replaceAll('"', '');
    });
  }

  // fetch undangan on undangan/me
  Future fetchUndangan() async {
    var res = await Api().getData('/undangan/me');
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
    if (value['data']['total'] != 0) {
      setState(() {
        dataUndangan = value['data']['data'] ?? [];

        nextPageUrl = value['data']['next_page_url'] ?? '';
        prevPageUrl = value['data']['prev_page_url'] ?? '';
        currentPage = value['data']['current_page'].toString();
        lastPage = value['data']['last_page'].toString();

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;

        dataUndangan = value['data']['data'] ?? [];
      });
    }
  }

  Future<void> loadMore() async {
    if (nextPageUrl.isNotEmpty) {
      var res = await Api().getDataUrl(nextPageUrl);
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        setState(() {
          dataUndangan.addAll(body['data']['data']);

          nextPageUrl = body['data']['next_page_url'] ?? '';
          prevPageUrl = body['data']['prev_page_url'] ?? '';
          currentPage = body['data']['current_page'].toString();
          lastPage = body['data']['last_page'].toString();
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
          header: WaterDropHeader(),
          onRefresh: () async {
            setState(() {});
            print("On Refresh");
            await Future.delayed(Duration(milliseconds: 1000));
            _refreshController.refreshCompleted();
          },
          onLoading: () async {
            await loadMore();
            print("On Loading");
            _refreshController.loadComplete();
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Row to make handle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          Text(
                            dataUdgn['surat']['perihal'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: fontSemiBold,
                            ),
                          ),
                          SizedBox(height: 10),
                          GenTable(data: {
                            // format date to indonesia with month name name day asia/jakarta
                            "Tanggal": DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                .format(DateTime.parse(
                                    dataUdgn['surat']['tanggal'])),
                            "Waktu": DateFormat('HH:mm').format(DateTime.parse(
                                    dataUdgn['surat']['tanggal'])) +
                                " WIB",
                            "Tempat": dataUdgn['surat']['tempat'],
                          }),
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
                        border: Border(
                          left: BorderSide(
                            color: DateTime.parse(dataUdgn['surat']['tanggal'])
                                    .isAfter(DateTime.now())
                                ? Colors.blue
                                : Colors.green,
                            width: 5,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        title: Text(
                          dataUdgn['surat']['perihal'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: fontSemiBold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                .add_jm()
                                .format(DateTime.parse(
                                    dataUdgn['surat']['tanggal'])),
                            style: TextStyle(
                              fontSize: 14,
                            ),
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
      );
    }
  }
}
