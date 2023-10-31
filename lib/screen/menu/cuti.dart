import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_cuti.dart';
import 'package:rsia_employee_app/components/filter/bottom_sheet_filter.dart';
import 'package:rsia_employee_app/components/modal/modal_cuti.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rsia_employee_app/components/loadingku.dart';

class Cuti extends StatefulWidget {
  const Cuti({super.key});

  @override
  State<Cuti> createState() => _CutiState();
}

class _CutiState extends State<Cuti> {
  TextEditingController dateinput = TextEditingController();

  SharedPreferences? pref;
  List dataCuti = [];
  Map hitungCuti = {};

  late String title;
  late String url;
  late String nik;
  late String id_pegawai;
  late String nama;
  late String dep_id;
  late String jenis;
  late String id_jenis;
  num sisacuti1 = 0;
  num sisacuti2 = 0;

  String nextPageUrl = '';
  String prevPageUrl = '';
  String currentPage = '';
  String lastPage = '';
  bool isLoding = true;
  bool isLodingButton = true;
  bool isFilter = false;
  TextEditingController searchController = TextEditingController();
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  Map filterData = {};

  @override
  void initState() {
    super.initState();
    _initialSet();
    fetchCuti().then((value) {
      if (mounted) {
        _hitungData();
        _setData(value);
      }
    });
  }

  _initialSet() {
    // var now = DateTime.now();
    // var bulan = now.month.toString().padLeft(2, '0');
    // var tahun = now.year.toString();
    title = "Rekap Cuti";
    url = "/pegawai/cuti";
  }

  _setData(value) {
    if (value['success']) {
      setState(() {
        dataCuti = value['data']['cuti'] ?? [];
        dataCuti.sort((a, b) => b['tanggal_cuti'].compareTo(a['tanggal_cuti']));
        // id_pegawai = value['data']['id'][0] ?? '';
        id_pegawai = value['data']['id'].toString();
        nama = value['data']['nama'].toString();
        dep_id = value['data']['departemen'].toString();

        // dep_id = value['data']['dep_id'][0] ?? '';
        // nextPageUrl = value['data']['next_page_url'] ?? '';
        // prevPageUrl = value['data']['prev_page_url'] ?? '';
        // currentPage = value['data']['current_page'].toString();
        // lastPage = value['data']['last_page'].toString();

        isLoding = false;
      });

      // if (nextPageUrl.isEmpty) {
      //   _refreshController.loadNoData();
      // }
    } else {
      setState(() {
        isLoding = false;
        dataCuti = [];

        // nextPageUrl = '';
        // prevPageUrl = '';
        // currentPage = value['data']['current_page'].toString();
        // lastPage = value['data']['last_page'].toString();
      });

      // _refreshController.resetNoData();
    }
  }

  Future _onClearCancel() async {
    setState(() {
      isLoding = true;
      isFilter = false;

      dateinput.text = "";

      filterData.clear();
      searchController.clear();
    });

    fetchCuti().then((value) {
      _setData(value);
    });
  }

  Future _fetchSearch(data) async {
    var res = await Api().postData(data, '/pegawai/cuti');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);

      return body;
    }
  }

  Future _postData(data) async {
    var res = await Api().postData(data, '/pegawai/cuti/post');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      Msg.success(context, body['message']);

      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);

      return body;
    }
  }

  Future fetchCuti() async {
    // SharedPreferences localStorage = await SharedPreferences.getInstance();
    // var spesialis = localStorage.getString('spesialis');
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());
    nik = decodeToken['sub'];

    var strUrl = url;
    // if (widget.ranap) {
    //   if (spesialis!.toLowerCase().contains('umum')) {
    //     strUrl = '/pasien/ranap/all';
    //   }
    // }

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

  void doFilter() async {
    setState(() {
      isLoding = true;
      isFilter = true;
    });
    filterData['nik'] = nik;

    // search
    // if (searchController.text.isNotEmpty) {
    //   filterData['keywords'] = searchController.text.toString();
    // }

    _fetchSearch(filterData).then((value) {
      _setData(value);
    });
  }

  void doPost() async {
    setState(() {
      isLoding = true;
      isFilter = true;
    });
    filterData['nik'] = nik;
    filterData['id_pegawai'] = id_pegawai;
    filterData['nama'] = nama;
    filterData['dep_id'] = dep_id;

    // search
    // if (searchController.text.isNotEmpty) {
    //   filterData['keywords'] = searchController.text.toString();
    // }

    _postData(filterData).then((value) {
      _onClearCancel();
      // Msg.success(context, "Berhasil simpan data");
    });
  }

  Future _hitungData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());
    nik = decodeToken['sub'];
    var res = await Api().postData({'nik': nik}, '/pegawai/cuti/count');
    var body = json.decode(res.body);

    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          print(body['data']);
          hitungCuti = body['data'][0];
          if (hitungCuti['jml1'] >= 6) {
            // hitungCuti['jml2'] = 12 - hitungCuti['jml1'];
            sisacuti1 = 0;
            sisacuti2 = 12 - (hitungCuti['jml1'] + hitungCuti['jml2']);
          } else {
            sisacuti1 = 6 - hitungCuti['jml1'];
            sisacuti2 = 6 - hitungCuti['jml2'];
          }
          isLodingButton = false;

          ;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          hitungCuti = {};
          isLodingButton = false;
        });
      }
    }
  }

  Future _deleteData(data) async {
    var res = await Api().deleteData({'id_cuti': data}, '/pegawai/cuti/delete');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      Msg.success(context, body['message']);

      // setState(() {});
      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);

      // setState(() {});
      return body;
    }
  }

  void _deleteItem(data) {
    if (mounted)
      setState(() {
        _deleteData(data).then((value) {
          _onClearCancel();
        });
      });
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
            "Cuti",
            style: TextStyle(
              color: textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primaryColor,
          actions: [
            IconButton(
              onPressed: () {
                _onFilterIconClicked(context);
              },
              icon: Icon(Icons.calendar_month),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 2 - 20,
                    height: 110,
                    decoration: BoxDecoration(
                        color: bgWhite,
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            "SEMESTER I",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            height: 25,
                            width:
                                MediaQuery.of(context).size.width / 2 - 30 - 10,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Cuti Diambil",
                                    style: TextStyle(color: textWhite),
                                  ),
                                  isLodingButton
                                      ? loadingIcon()
                                      : Text(
                                          hitungCuti['jml1'].toString(),
                                          style: TextStyle(color: textWhite),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Container(
                            height: 25,
                            width:
                                MediaQuery.of(context).size.width / 2 - 30 - 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Cuti Sisa",
                                    style: TextStyle(color: textWhite),
                                  ),
                                  isLodingButton
                                      ? loadingIcon()
                                      : Text(
                                          sisacuti1.toString(),
                                          style: TextStyle(color: textWhite),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 2 - 20,
                    height: 110,
                    decoration: BoxDecoration(
                      color: bgWhite,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            "SEMESTER II",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            height: 25,
                            width:
                                MediaQuery.of(context).size.width / 2 - 30 - 10,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Cuti Diambil",
                                    style: TextStyle(color: textWhite),
                                  ),
                                  isLodingButton
                                      ? loadingIcon()
                                      : Text(
                                          hitungCuti['jml2'].toString(),
                                          style: TextStyle(color: textWhite),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Container(
                            height: 25,
                            width:
                                MediaQuery.of(context).size.width / 2 - 30 - 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Cuti Sisa",
                                    style: TextStyle(color: textWhite),
                                  ),
                                  isLodingButton
                                      ? loadingIcon()
                                      : Text(
                                          sisacuti2.toString(),
                                          style: TextStyle(color: textWhite),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Column(
                // mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    itemCount: dataCuti.isEmpty ? 1 : dataCuti.length,
                    itemBuilder: (context, index) {
                      if (dataCuti.isNotEmpty) {
                        return dataCuti[index]['status_cuti'] == 0
                            ? slideToDelete(index)
                            : CardCuti(
                                dataCuti: dataCuti[index],
                                onDelete: () => _deleteItem(
                                  dataCuti[index]['id_cuti'],
                                ),
                              );
                      }
                    },
                  ),
                ],
              ),
            ]),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _onAddIconClicked(context);
          },
          backgroundColor: primaryColor,
          child: Icon(
            Icons.add_circle,
            size: 36,
          ),
        ),
      );
    }
  }

  Widget slideToDelete(index) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 15),
          child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Swipe To Delete",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500),
                        ),
                        Icon(
                          Icons.delete_forever_outlined,
                          color: Colors.white,
                          size: 32,
                        )
                      ],
                    )),
              )),
        ),
        Dismissible(
          direction: DismissDirection.endToStart,
          key: Key(index.toString()),
          onDismissed: (direction) {
            setState(() {
              _deleteItem(dataCuti[index]['id_cuti']);
              dataCuti.removeAt(index);
            });

            Msg.success(context, "Cuti dalam proses penghapusan");
          },
          confirmDismiss: (DismissDirection direction) async {
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
          // background: Container(
          //   decoration: BoxDecoration(
          //     color: HexColor('#FF6962'),
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   child: Row(
          //     crossAxisAlignment: CrossAxisAlignment.center,
          //     mainAxisAlignment:
          //     MainAxisAlignment.spaceBetween,
          //     children: [
          //       Padding(
          //         padding: const EdgeInsets.symmetric(
          //             horizontal: 20),
          //         child: Text(
          //           "Delete",
          //           style: TextStyle(
          //             fontWeight: FontWeight.bold,
          //             color: Colors.white,
          //             fontSize: 20,
          //           ),
          //         ),
          //       ),
          //       Padding(
          //         padding: const EdgeInsets.symmetric(
          //             horizontal: 20),
          //         child: Text(
          //           "Delete",
          //           style: TextStyle(
          //             fontWeight: FontWeight.bold,
          //             color: Colors.white,
          //             fontSize: 20,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          child: CardCuti(
            dataCuti: dataCuti[index],
            onDelete: () => _deleteItem(
              dataCuti[index]['id_cuti'],
            ),
          ),
        ),
      ],
    );
  }

  Widget loadingIcon() {
    return SizedBox(
      child: Center(
          child: CircularProgressIndicator(
        strokeWidth: 1,
        color: Colors.white,
      )),
      width: 8,
      height: 8,
    );
  }

  Future<dynamic> _onFilterIconClicked(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheetFilter(
          dateinput: dateinput,
          searchController: searchController,
          isLoding: isLoding,
          isFilter: isFilter,
          fetchPasien: fetchCuti,
          setData: _setData,
          doFilter: doFilter,
          onClearAndCancel: _onClearCancel,
          filterData: filterData,
          selectedCategory: filterData['penjab'] ?? '',
          tglFilterKey: "tanggal",
        );
      },
    );
  }

  Future<dynamic> _onAddIconClicked(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ModalCuti(
          dateinput: dateinput,
          searchController: searchController,
          isLoding: isLoding,
          isFilter: isFilter,
          fetchPasien: fetchCuti,
          setData: _setData,
          doFilter: doPost,
          onClearAndCancel: _onClearCancel,
          filterData: filterData,
          selectedCategory: filterData['jenis'] ?? '',
          selectedIdJenis: filterData['id_jenis'] ?? '',
          tglFilterKey: "tanggal_cuti",
        );
      },
    );
  }
}
