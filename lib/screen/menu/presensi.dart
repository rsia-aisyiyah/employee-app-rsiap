import 'dart:convert';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_presensi.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_list.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class Presensi extends StatefulWidget {
  const Presensi({super.key});

  @override
  State<Presensi> createState() => _PresensiState();
}

class _PresensiState extends State<Presensi> {
  TextEditingController dateinput = TextEditingController();
  TextEditingController searchController = TextEditingController();

  final box = GetStorage();

  List dataPresensi = [];

  String nextPageUrl = '';
  String prevPageUrl = '';
  String currentPage = '';
  String lastPage = '';
  bool isLoding = true;
  bool isFilter = false;
  Map filterData = {};

  @override
  void initState() {
    super.initState();
    _fetchData().then((value) {
      if (mounted) {
        _setData(value);
      }
    });
  }

  _setData(value) {
    if (value['meta']['total'] > 0) {
      setState(() {
        dataPresensi = value['data'] ?? [];
        isLoding = false;
      });
    } else {
      setState(() {
        isLoding = false;
        dataPresensi = [];
      });
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

    _fetchData().then((value) {
      _setData(value);
    });
  }

  Future _fetchData({DateTime? start, DateTime? end}) async {
    print("called");
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');

    // If start is not provided, default to the first day of the current month
    start ??= DateTime(now.year, now.month, 1);

    // If end is not provided, default to the last day of the current month
    DateTime firstDayOfNextMonth;
    if (now.month == 12) {
      firstDayOfNextMonth =
          DateTime(now.year + 1, 1, 1); // January of the next year
    } else {
      firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
    }
    end ??= firstDayOfNextMonth.subtract(const Duration(days: 1));

    var res = await Api().postData({
      "scopes": [
        {
          "name": "withRange",
          "parameters": [dateFormat.format(start), dateFormat.format(end)]
        }
      ],
      "sort": [
        {"field": "jam_datang", "direction": "desc"}
      ]
    }, "/pegawai/${box.read('sub')}/presensi/search?limit=31");

    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);

      return body;
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
      child: Row(
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
                "Riwayat Presensi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isFilter)
                InkWell(
                  onTap: () {
                    setState(() {
                      isLoding = true;
                      isFilter = false;
                      filterData.clear();
                      dateinput.clear();
                      searchController.clear();
                    });
                    _fetchData().then((value) {
                      _setData(value);
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _onFilterIconClicked(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: isLoding
                ? const SkeletonList()
                : dataPresensi.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text(
                              "Belum ada data presensi",
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: dataPresensi.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 5),
                        itemBuilder: (context, index) {
                          return cardPresensi(dataPresensi[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<dynamic> _onFilterIconClicked(BuildContext context) {
    return showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      enableDrag: true,
      context: context,
      builder: (context) {
        return Container(
          height: 130,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filter Presensi",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextField(
                controller: dateinput,
                decoration: InputDecoration(
                  hintText: "Select Date",
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: dateinput.text.isNotEmpty ? primaryColor : line,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: line, width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: dateinput.text.isNotEmpty ? primaryColor : bgWhite,
                      width: 2,
                    ),
                  ),
                ),
                readOnly: true,
                onTap: () async {
                  var res = await showCalendarDatePicker2Dialog(
                    context: context,
                    useSafeArea: true,
                    dialogSize: const Size(325, 400),
                    borderRadius: BorderRadius.circular(15),
                    config: CalendarDatePicker2WithActionButtonsConfig(
                      centerAlignModePicker: true,
                      customModePickerIcon: const SizedBox(),
                      selectedDayTextStyle: TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDayHighlightColor: primaryColor,
                      calendarType: CalendarDatePicker2Type.range,
                    ),
                  );

                  if (res != null) {
                    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
                    _fetchData(start: res.first!, end: res.last!)
                        .then((value) => _setData(value));

                    setState(() {
                      dateinput.text =
                          "${dateFormat.format(res.first!)} - ${dateFormat.format(res.last!)}";
                    });

                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
