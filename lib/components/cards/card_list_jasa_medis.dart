import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/table.dart';

class createCardJasaMedis extends StatefulWidget {
  final Map dataJasaMedis;

  const createCardJasaMedis({
    super.key,
    required this.dataJasaMedis,
    // required this.dataJasaMedis,
  });

  @override
  State<createCardJasaMedis> createState() => _createCardJasaMedisState();
}

class _createCardJasaMedisState extends State<createCardJasaMedis> {
  // IconData _currentIcon = Icons.star; // Initial icon
  bool showIcon = true;

  void _changeIcon() {
    setState(() {
      showIcon = !showIcon;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.dataJasaMedis);
    Map map = {};
    if (widget.dataJasaMedis['jm_ruang_share'] != 0 &&
        widget.dataJasaMedis['jm_total_share'] != 0) {
      map["JasPel"] = showIcon
          ? '* * * * *'
          : '(+) ' +
              Helper.convertToIdr(
                widget.dataJasaMedis['jm_ruang_share'] +
                    widget.dataJasaMedis['jm_total_share'],
                2,
              );
    }
    if (widget.dataJasaMedis['lebih_jam'] != 0) {
      map["Lebih Jam"] = showIcon
          ? '* * * * *'
          : '(+) ' +
              Helper.convertToIdr(
                widget.dataJasaMedis['lebih_jam'],
                2,
              );
    }
    if (widget.dataJasaMedis['jm_asisten_ok'] != 0) {
      map["Asisten OK"] = showIcon
          ? '* * * * *'
          : '(+) ' +
              Helper.convertToIdr(
                widget.dataJasaMedis['jm_asisten_ok'],
                2,
              );
    }
    if (widget.dataJasaMedis['uang_makan'] != 0) {
      map["Uang Makan"] = showIcon
          ? '* * * * *'
          : '(+) ' +
              Helper.convertToIdr(
                widget.dataJasaMedis['uang_makan'],
                2,
              );
    }
    if (widget.dataJasaMedis['oncall_ok'] != 0) {
      map["Oncall"] = showIcon
          ? '* * * * *'
          : '(+) ' +
              Helper.convertToIdr(
                widget.dataJasaMedis['oncall_ok'],
                2,
              );
    }
    if (widget.dataJasaMedis['tambahan'] != 0) {
      map["Tambahan"] = showIcon
          ? '* * * * *'
          : '(+) ' +
              Helper.convertToIdr(
                widget.dataJasaMedis['tambahan'],
                2,
              );
    }
    if (widget.dataJasaMedis['jm_total_share'] != 0) {
      map["JasPel Bruto"] = showIcon
          ? '* * * * *'
          : Helper.convertToIdr(
              widget.dataJasaMedis['jm_ruang_share'] +
                  widget.dataJasaMedis['jm_total_share'] +
                  widget.dataJasaMedis['lebih_jam'] +
                  widget.dataJasaMedis['jm_asisten_ok'] +
                  widget.dataJasaMedis['uang_makan'] +
                  widget.dataJasaMedis['oncall_ok'] +
                  widget.dataJasaMedis['tambahan'],
              2,
            );
    }
    if (widget.dataJasaMedis['jm_total_full'] != 0 &&
        widget.dataJasaMedis['jm_ruang_full'] != 0) {
      map["Potongan JasPel"] = showIcon
          ? '* * * * *'
          : '(-) ' +
              Helper.convertToIdr(
                (widget.dataJasaMedis['jm_total_full'] +
                        widget.dataJasaMedis['jm_ruang_full']) -
                    (widget.dataJasaMedis['jm_total_share'] +
                        widget.dataJasaMedis['jm_ruang_share']),
                2,
              );
    }
    if (widget.dataJasaMedis['jm_asisten_ok'] != 0) {
      // if (widget.dataJasaMedis['stts_kerja'] == 'Karyawan Mitra') {
      //   map["Potongan Asisten OK"] = showIcon
      //       ? '* * * * *'
      //       : '(-) ' +
      //           Helper.convertToIdr(
      //             (widget.dataJasaMedis['jm_asisten_ok'] /
      //                     widget.dataJasaMedis['jm_ok_mitra']) -
      //                 widget.dataJasaMedis['jm_asisten_ok'],
      //             2,
      //           );
      // } else {
      //   map["Potongan Asisten OK"] = showIcon
      //       ? '* * * * *'
      //       : '(-) ' +
      //       Helper.convertToIdr(
      //         (widget.dataJasaMedis['jm_asisten_ok'] /
      //             widget.dataJasaMedis['jm_ok_mitra']) -
      //             widget.dataJasaMedis['jm_asisten_ok'],
      //         2,
      //       );
      // }
    }

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 0,
                left: 15,
                right: 15,
                bottom: 10,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primaryColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor,
                    blurRadius: 3,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        Helper.numToMonth(
                                int.parse(widget.dataJasaMedis['bulan'])) +
                            " " +
                            widget.dataJasaMedis['tahun'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: fontSemiBold,
                        ),
                      ),
                      Expanded(
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () {
                                _changeIcon();
                              },
                              icon: Icon(showIcon
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GenTable(
                    data:
                        // {
                        map,
                    // "Jasa Pelayanan": showIcon
                    //     ? '* * * * *'
                    //     : Helper.convertToIdr(
                    //         widget.dataJasaMedis['jm_ruang_share'] +
                    //             widget.dataJasaMedis['jm_total_share'],
                    //         2,
                    //       ),
                    // tambahanText: showIcon
                    //     ? '* * * * *'
                    //     : '(+) ' +
                    //         Helper.convertToIdr(
                    //           widget.dataJasaMedis['tambahan'],
                    //           2,
                    //         ),
                    // potonganText: showIcon
                    //     ? '* * * * *'
                    //     : '(-) ' +
                    //         Helper.convertToIdr(
                    //           widget.dataJasaMedis['potongan_lain'] +
                    //               widget.dataJasaMedis['potongan_obat'],
                    //           2,
                    //         ),
                    // "Jasa Pelayanan Diterima": showIcon
                    //     ? '* * * * *'
                    //     : Helper.convertToIdr(
                    //         widget.dataJasaMedis['jm_bersih_share'],
                    //         2,
                    //       ),
                    // },
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: fontSemiBold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
