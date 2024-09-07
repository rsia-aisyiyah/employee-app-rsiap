import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_cuti.dart';
import 'package:rsia_employee_app/components/filter/bottom_sheet_filter.dart';
import 'package:rsia_employee_app/components/modal/modal_cuti.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/components/loadingku.dart';

class Cuti extends StatefulWidget {
  const Cuti({super.key});

  @override
  State<Cuti> createState() => _CutiState();
}

class _CutiState extends State<Cuti> {
  TextEditingController dateinput = TextEditingController();

  List dataCuti = [];
  Map hitungCuti = {};

  late String title;
  late String jenis;
  late String id_jenis;
  num sisacuti1 = 0;
  num sisacuti2 = 0;

  bool isLoding = true;
  bool isLodingButton = true;
  bool isFilter = false;

  TextEditingController searchController = TextEditingController();
  Map filterData = {};

  final box = GetStorage();

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
    title = "Rekap Cuti";
  }

  _setData(value) {
    setState(() {
      dataCuti = value['data'] ?? [];
      isLoding = false;
    });
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
    var nik = box.read('sub');
    var body = {
      "filters": [
        { "field": "tanggal_cuti", "operator": ">=", "value": data['tanggal_cuti']['start'] },
        { "field": "tanggal_cuti", "operator": "<=", "value": data['tanggal_cuti']['end'] },
      ]
    };

    var res = await Api().postData(body, "/pegawai/$nik/cuti/search");

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
    var nik = box.read('sub');
    var res = await Api().postData(data, '/pegawai/$nik/cuti');

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
    var nik = box.read('sub');
    var res = await Api().getData("/pegawai/$nik/cuti");
    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);

      return body;
    }
  }

  void doFilter() async {
    setState(() {
      isLoding = true;
      isFilter = true;
    });

    _fetchSearch(filterData).then((value) {
      _setData(value);
    });
  }

  void doPost() async {
    setState(() {
      isLoding = true;
      isFilter = true;
    });

    _postData(filterData).then((value) {
      _onClearCancel();
      Msg.success(context, "Berhasil simpan data");
    });
  }

  Future _hitungData() async {
    var nik = box.read('sub');
    var res = await Api().getData("/pegawai/$nik/cuti/counter");
    var body = json.decode(res.body);

    if (res.statusCode == 200 && mounted) {
      setState(() {
        hitungCuti = body['data'];
        final jml1 = hitungCuti['jml1'] ?? 0;
        final jml2 = hitungCuti['jml2'] ?? 0;

        sisacuti1 = (jml1 >= 6) ? 0 : 6 - jml1;
        sisacuti2 = (jml1 >= 6) ? 12 - (jml1 + jml2) : 6 - jml2;

        isLodingButton = false;
      });
    } else if (mounted) {
      setState(() {
        hitungCuti = {};
        isLodingButton = false;
      });
    }
  }

  Future _deleteData(data) async {
    var nik = box.read('sub');
    var res = await Api().deleteWitoutData("/pegawai/$nik/cuti/$data");
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
    if (mounted) {
      setState(() {

      });
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
              icon: const Icon(Icons.calendar_month),
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
                          const Text(
                            "SEMESTER I",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
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
                          const Text(
                            "SEMESTER II",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
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
                                      : Text(hitungCuti['jml2'].toString(),
                                          style: TextStyle(color: textWhite),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Container(
                            height: 25,
                            width: MediaQuery.of(context).size.width / 2 - 30 - 10,
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
              const SizedBox(
                height: 10,
              ),
              Column(
                // mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: dataCuti.isEmpty ? 1 : dataCuti.length,
                    itemBuilder: (context, index) {
                      if (dataCuti.isNotEmpty) {
                        return dataCuti[index]['status_cuti'] == 0
                            ? slideToDelete(index)
                            : CardCuti(
                                dataCuti: dataCuti[index],
                                onDelete: () => _deleteData(dataCuti[index]['id_cuti']).then((value) {
                                  Navigator.of(context).pop();
                                  _onClearCancel();
                                }),
                              );
                      }
                      return null;
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
          child: const Icon(
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
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                    padding: EdgeInsets.only(right: 20),
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
              _deleteData(dataCuti[index]['id_cuti']);
              dataCuti.removeAt(index);
            });

            Msg.success(context, "Cuti dalam proses penghapusan");
          },
          confirmDismiss: (DismissDirection direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  iconPadding: const EdgeInsets.only(top: 15,bottom: 10),
                  icon: const Icon(Icons.warning,color: Colors.orangeAccent,size: 32,),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          child: CardCuti(
            dataCuti: dataCuti[index],
            onDelete: () => _deleteData(dataCuti[index]['id_cuti']).then((value) {
              Navigator.of(context).pop();
              _onClearCancel();
            }),
          ),
        ),
      ],
    );
  }

  Widget loadingIcon() {
    return const SizedBox(
      width: 8,
      height: 8,
      child: Center(
          child: CircularProgressIndicator(
        strokeWidth: 1,
        color: Colors.white,
      )),
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
          setData: _setData,
          fetchPresensi: doFilter,
          onClearAndCancel: _onClearCancel,
          filterData: filterData,
          tglFilterKey: "tanggal_cuti",
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
