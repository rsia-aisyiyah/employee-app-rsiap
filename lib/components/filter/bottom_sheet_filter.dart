import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
// import 'package:rsia_employee_app/utils/fonts.dart';

//ignore: must_be_immutable
class BottomSheetFilter extends StatefulWidget {
  TextEditingController dateinput;
  TextEditingController searchController;

  bool isLoding;
  bool isFilter;
  bool isRanap;

  Function fetchPasien;
  Function setData;
  Function doFilter;
  Function onClearAndCancel;

  Map filterData;

  String selectedCategory;
  String tglFilterKey;

  BottomSheetFilter({
    super.key,
    required this.dateinput,
    required this.searchController,
    required this.isLoding,
    required this.isFilter,
    required this.fetchPasien,
    required this.setData,
    required this.doFilter,
    required this.filterData,
    required this.selectedCategory,
    required this.onClearAndCancel,
    required this.tglFilterKey,
    this.isRanap = false,
  });

  @override
  State<BottomSheetFilter> createState() => _BottomSheetFilterState();
}

class _BottomSheetFilterState extends State<BottomSheetFilter> {
  Widget _customCapsuleFilter(String title, String key, String value) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            widget.filterData[key] = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: widget.filterData[key] == value
                ? primaryColor.withOpacity(0.2)
                : bgWhite,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: widget.filterData[key] == value ? primaryColor : bgWhite,
              width: 1.5,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.filterData[key] == value ? primaryColor : bgWhite,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            Icons.filter_alt,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Filter Presensi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.close,
                        color: textColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Select Date",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: widget.dateinput,
                decoration: InputDecoration(
                  hintText: "Select Date",
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color:
                        widget.dateinput.text.isNotEmpty ? primaryColor : line,
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
                      color: widget.dateinput.text.isNotEmpty
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
                    String startDate = DateFormat('yyyy-MM-dd').format(
                      res.first!,
                    );

                    String endDate = DateFormat('yyyy-MM-dd').format(
                      res.last!,
                    );

                    setState(() {
                      widget.dateinput.text = "$startDate - $endDate";
                      widget.filterData[widget.tglFilterKey] = {
                        "start": startDate,
                        "end": endDate
                      };
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 50),
          Flex(
            direction: Axis.horizontal,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: textColor,
                      backgroundColor: bgWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      widget.onClearAndCancel();
                      Navigator.pop(context);
                    },
                    child: Text("Reset & Close"),
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
                      widget.doFilter();
                      Navigator.pop(context);
                    },
                    child: Text("Submit"),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}