import 'dart:convert';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_presensi.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
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
      firstDayOfNextMonth = DateTime(now.year + 1, 1, 1); // January of the next year
    } else {
      firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
    }
    end ??= firstDayOfNextMonth.subtract(const Duration(days: 1));

    var res = await Api().postData({
      "scopes": [
        { "name" : "withRange", "parameters" : [dateFormat.format(start), dateFormat.format(end)] }
      ],
      "sort" : [
        {"field" : "jam_datang", "direction" : "desc"}
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

                  _fetchData().then((value) {
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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
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
              const Text(
                "Filter Presensi",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
                )
              ),

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
                      color: dateinput.text.isNotEmpty
                          ? primaryColor
                          : bgWhite,
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
                    _fetchData(start: res.first!, end: res.last!).then((value) => _setData(value));

                    setState(() {
                      dateinput.text = "${dateFormat.format(res.first!)} - ${dateFormat.format(res.last!)}";
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
