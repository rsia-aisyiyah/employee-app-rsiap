import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_presensi.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rsia_employee_app/components/filter/bottom_sheet_filter.dart';

class Presensi extends StatefulWidget {
  const Presensi({super.key});

  @override
  State<Presensi> createState() => _PresensiState();
}

class _PresensiState extends State<Presensi> {
  TextEditingController dateinput = TextEditingController();

  SharedPreferences? pref;
  List dataPresensi = [];
  late String title;
  late String url;
  late String nik;
  String nextPageUrl = '';
  String prevPageUrl = '';
  String currentPage = '';
  String lastPage = '';
  bool isLoding = true;
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
    fetchPresensi().then((value) {
      if (mounted) {
        _setData(value);
      }
    });
  }

  _initialSet() {
    // var now = DateTime.now();
    // var bulan = now.month.toString().padLeft(2, '0');
    // var tahun = now.year.toString();
    title = "Rekap Presensi";
    url = "/pegawai/presensi/rekap";
  }

  _setData(value) {
    print(value['data']);
    if (value['success']) {
      setState(() {
        dataPresensi = value['data'] ?? [];
        dataPresensi.sort((a, b) => b['jam_datang'].compareTo(a['jam_datang']));

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
        dataPresensi = [];

        // nextPageUrl = '';
        // prevPageUrl = '';
        // currentPage = value['data']['current_page'].toString();
        // lastPage = value['data']['last_page'].toString();
      });

      // _refreshController.resetNoData();
    }
  }

  _onClearCancel() {
    setState(() {
      isLoding = true;
      isFilter = false;

      dateinput.text = "";

      filterData.clear();
      searchController.clear();
    });

    fetchPresensi().then((value) {
      _setData(value);
    });
  }
  // _onRefresh() {
  //   setState(() {
  //     isFilter = false;

  //     // dateinput.text = "";

  //     filterData.clear();
  //     searchController.clear();
  //   });

  //   fetchPresensi().then((value) {
  //     _setData(value);

  //     _refreshController.refreshCompleted();
  //   });
  // }

  // void _loadMore() async {
  //   if (nextPageUrl.isNotEmpty) {
  //     if (isFilter) {
  //       await Api().postFullUrl(filterData, nextPageUrl).then((value) {
  //         var body = json.decode(value.body);
  //         if (mounted) {
  //           setState(() {
  //             nextPageUrl = body['data']['next_page_url'] ?? '';
  //             prevPageUrl = body['data']['prev_page_url'] ?? '';
  //             currentPage = body['data']['current_page'].toString();
  //             lastPage = body['data']['last_page'].toString();

  //             dataPresensi.addAll(body['data']['data']);
  //           });
  //         }
  //       });
  //     } else {
  //       await Api().getFullUrl(nextPageUrl).then((value) {
  //         var body = json.decode(value.body);
  //         if (mounted) {
  //           setState(() {
  //             nextPageUrl = body['data']['next_page_url'] ?? '';
  //             prevPageUrl = body['data']['prev_page_url'] ?? '';
  //             currentPage = body['data']['current_page'].toString();
  //             lastPage = body['data']['last_page'].toString();

  //             dataPresensi.addAll(body['data']['data']);
  //           });
  //         }
  //       });
  //     }

  //     _refreshController.loadComplete();
  //   } else {
  //     _refreshController.loadNoData();
  //   }
  // }

  Future _fetchSearch(data) async {
    var res = await Api().postData(data, '/pegawai/presensi/rekap');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);

      return body;
    }
  }

  Future fetchPresensi() async {
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

  @override
  Widget build(BuildContext context) {
    if (isLoding) {
      return loadingku();
    } else {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            "Presensi",
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
              icon: Icon(
                Icons.calendar_month,
                color: textWhite,
              ),
            ),
            if (isFilter)
              IconButton(
                onPressed: () {
                  setState(() {
                    isLoding = true;
                    isFilter = false;

                    // dateinput.text = "";

                    filterData.clear();
                    dateinput.clear();
                    searchController.clear();
                  });

                  fetchPresensi().then((value) {
                    _setData(value);
                  });
                },
                icon: Icon(
                  Icons.clear,
                  color: textWhite,
                ),
              )
            else
              const SizedBox(),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                itemCount: dataPresensi.isEmpty ? 1 : dataPresensi.length,
                itemBuilder: (context, index) {
                  if (dataPresensi.isNotEmpty) {
                    return InkWell(
                        onTap: () {}, child: cardPresensi(dataPresensi[index]));
                  }
                },
              ),
            ],
          ),
        ),
      );
    }
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
          fetchPasien: fetchPresensi,
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
}
