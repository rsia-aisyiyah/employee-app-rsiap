import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_cuti.dart';
import 'package:rsia_employee_app/components/filter/bottom_sheet_filter.dart';
import 'package:rsia_employee_app/components/modal/modal_cuti.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_list.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class Cuti extends StatefulWidget {
  final bool showForm;
  const Cuti({super.key, this.showForm = false});

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
  String selectedYear = DateTime.now().year.toString();

  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _initialSet();
    _loadData();

    if (widget.showForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onAddIconClicked(context);
      });
    }
  }

  void _loadData() {
    setState(() => isLoding = true);
    Future.wait([
      fetchCuti(selectedYear),
      _hitungData(selectedYear),
    ]).then((results) {
      if (mounted) {
        _setData(results[0]);
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
      isFilter = false;
      dateinput.text = "";
      filterData.clear();
      searchController.clear();
      selectedYear = DateTime.now().year.toString();
    });

    _loadData();
  }

  Future _fetchSearch(data) async {
    var nik = box.read('sub');
    var body = {
      "filters": [
        {
          "field": "tanggal_cuti",
          "operator": ">=",
          "value": data['tanggal_cuti']['start']
        },
        {
          "field": "tanggal_cuti",
          "operator": "<=",
          "value": data['tanggal_cuti']['end']
        },
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

  Future fetchCuti([String? tahun]) async {
    var nik = box.read('sub');
    var year = tahun ?? selectedYear;
    var res = await Api().getData("/pegawai/$nik/cuti?year=$year");
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

  Future _hitungData([String? tahun]) async {
    var nik = box.read('sub');
    var year = tahun ?? selectedYear;
    var res = await Api().getData("/pegawai/$nik/cuti/counter?year=$year");
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
      setState(() {});
    }
  }

  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 25,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Riwayat Cuti",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _onAddIconClicked(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 5),
                      Text(
                        "Pengajuan",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedYear,
                dropdownColor: primaryColor,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white),
                isExpanded: true,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
                items: List.generate(5, (index) {
                  final year = (DateTime.now().year - index).toString();
                  return DropdownMenuItem(
                    value: year,
                    child: Text("Tahun Cuti: $year"),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedYear = value;
                    });
                    _loadData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      // transform: Matrix4.translationValues(0, -20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sisa Cuti Tahunan",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                    "Semester 1", hitungCuti['jml1'] ?? 0, sisacuti1),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Expanded(
                child: _buildBalanceItem(
                    "Semester 2", hitungCuti['jml2'] ?? 0, sisacuti2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, dynamic used, num remaining) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Terpakai",
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(
                  used.toString(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Sisa",
                    style: TextStyle(fontSize: 10, color: Colors.green)),
                Text(
                  remaining.toString(),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildTopHeader(),
          const SizedBox(height: 20),
          _buildLeaveBalanceCard(),
          const SizedBox(height: 20),
          Expanded(
            child: isLoding
                ? const SkeletonList(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20))
                : dataCuti.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text(
                              "Belum ada riwayat cuti",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: dataCuti.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 5),
                        itemBuilder: (context, index) {
                          return CardCuti(
                            dataCuti: dataCuti[index],
                            onDelete: () =>
                                _deleteData(dataCuti[index]['id_cuti'])
                                    .then((value) {
                              Navigator.of(context).pop();
                              _onClearCancel();
                            }),
                          );
                        },
                      ),
          ),
        ],
      ),
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
