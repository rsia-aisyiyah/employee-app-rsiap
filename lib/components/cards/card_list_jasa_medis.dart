import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/table.dart';
import 'package:rsia_employee_app/utils/table_jaspel.dart';

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
    double asisten_ok = 0;
    double uang_makan = 0;
    double pot_asisten_ok = 0;
    double pot_uang_makan = 0;
    double jm_bersih = 0;
    double jm_potong = 0;

    if (widget.dataJasaMedis['jm_ruang_share'] != 0 &&
        widget.dataJasaMedis['jm_total_share'] != 0) {
      map["JasPel"] = showIcon
          ? '* * * * *'
          : Helper.convertToIdr(
              widget.dataJasaMedis['jm_ruang_share'] +
                  widget.dataJasaMedis['jm_total_share'],
              0,
            );
    }
    if (widget.dataJasaMedis['jm_asisten_ok'] != 0) {
      if (widget.dataJasaMedis['stts_kerja'] == 'Karyawan Mitra') {
        map["Asisten OK"] = showIcon
            ? '* * * * *'
            : '(+) ' +
                Helper.convertToIdr(
                  (widget.dataJasaMedis['jm_asisten_ok'] /
                      widget.dataJasaMedis['jasa_pelayanan_akun']
                          ['jm_ok_mitra']),
                  0,
                );
        asisten_ok = widget.dataJasaMedis['jm_asisten_ok'] /
            widget.dataJasaMedis['jasa_pelayanan_akun']['jm_ok_mitra'];
      } else {
        map["Asisten OK"] = showIcon
            ? '* * * * *'
            : '(+) ' +
                Helper.convertToIdr(
                  (widget.dataJasaMedis['jm_asisten_ok'] /
                      widget.dataJasaMedis['jasa_pelayanan_akun']['jm_rs']),
                  0,
                );
        asisten_ok = widget.dataJasaMedis['jm_asisten_ok'] /
            widget.dataJasaMedis['jasa_pelayanan_akun']['jm_rs'];
      }
    }
    if (widget.dataJasaMedis['uang_makan'] != 0) {
      if (widget.dataJasaMedis['stts_kerja'] == 'Karyawan Mitra') {
        map["Uang Makan"] = showIcon
            ? '* * * * *'
            : '(+) ' +
                Helper.convertToIdr(
                  (widget.dataJasaMedis['uang_makan'] /
                      widget.dataJasaMedis['jasa_pelayanan_akun']
                          ['jm_ok_mitra']),
                  0,
                );
        uang_makan = widget.dataJasaMedis['uang_makan'] /
            widget.dataJasaMedis['jasa_pelayanan_akun']['jm_ok_mitra'];
      } else {
        map["Uang Makan"] = showIcon
            ? '* * * * *'
            : '(+) ' +
                Helper.convertToIdr(
                  (widget.dataJasaMedis['uang_makan'] /
                      widget.dataJasaMedis['jasa_pelayanan_akun']['jm_rs']),
                  0,
                );
        uang_makan = widget.dataJasaMedis['uang_makan'] /
            widget.dataJasaMedis['jasa_pelayanan_akun']['jm_rs'];
      }
    }

      map["Lebih Jam"] = showIcon
          ? '* * * * *'
          : '(+) ' +
              Helper.convertToIdr(
                widget.dataJasaMedis['lebih_jam'],
                0,
              );

    if (widget.dataJasaMedis['oncall_ok'] != 0) {
      map["Oncall"] = showIcon
          ? '* * * * *'
          : '(+) ' +
              Helper.convertToIdr(
                widget.dataJasaMedis['oncall_ok'],
                0,
              );
    }

      map["Tambahan Lain"] = showIcon
          ? '* * * * *'
          : '(+) ' +
              Helper.convertToIdr(
                widget.dataJasaMedis['tambahan'],
                0,
              );

    jm_bersih = (widget.dataJasaMedis['jm_total_full'] != 0
            ? widget.dataJasaMedis['jm_total_full']
            : widget.dataJasaMedis['jm_total_share']) +
        (widget.dataJasaMedis['jm_ruang_full'] != 0
            ? widget.dataJasaMedis['jm_ruang_full']
            : widget.dataJasaMedis['jm_ruang_share']) +
        asisten_ok +
        widget.dataJasaMedis['lebih_jam'] +
        widget.dataJasaMedis['oncall_ok'] +
        uang_makan +
        widget.dataJasaMedis['tambahan'];
    if (widget.dataJasaMedis['jm_total_share'] != 0) {
      map["JasPel Bruto"] = showIcon
          ? '* * * * *'
          : Helper.convertToIdr(
              jm_bersih,
              0,
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
                        widget.dataJasaMedis['jm_ruang_share']) + ((widget.dataJasaMedis['jm_total_full'] +
                    widget.dataJasaMedis['jm_ruang_full']) * widget.dataJasaMedis['potongan_jaspel']),
                0,
              );
    }
    if (widget.dataJasaMedis['jm_asisten_ok'] != 0) {
      if (widget.dataJasaMedis['stts_kerja'] == 'Karyawan Mitra') {
        map["Potongan Asisten OK"] = showIcon
            ? '* * * * *'
            : '(-) ' +
                Helper.convertToIdr(
                  (widget.dataJasaMedis['jm_asisten_ok'] /
                          widget.dataJasaMedis['jasa_pelayanan_akun']
                              ['jm_ok_mitra']) -
                      (widget.dataJasaMedis['jm_asisten_ok']),
                  0,
                );
        pot_asisten_ok = (widget.dataJasaMedis['jm_asisten_ok'] /
                widget.dataJasaMedis['jasa_pelayanan_akun']['jm_ok_mitra']) -
            widget.dataJasaMedis['jm_asisten_ok'];
      } else {
        map["Potongan Asisten OK"] = showIcon
            ? '* * * * *'
            : '(-) ' +
                Helper.convertToIdr(
                  (widget.dataJasaMedis['jm_asisten_ok'] /
                          widget.dataJasaMedis['jasa_pelayanan_akun']
                              ['jm_rs']) -
                      (widget.dataJasaMedis['jm_asisten_ok']),
                  0,
                );
        pot_asisten_ok = (widget.dataJasaMedis['jm_asisten_ok'] /
                widget.dataJasaMedis['jasa_pelayanan_akun']['jm_rs']) -
            widget.dataJasaMedis['jm_asisten_ok'];
      }
    }
    if (widget.dataJasaMedis['uang_makan'] != 0) {
      if (widget.dataJasaMedis['stts_kerja'] == 'Karyawan Mitra') {
        map["Potongan Uang Makan"] = showIcon
            ? '* * * * *'
            : '(-) ' +
                Helper.convertToIdr(
                  (widget.dataJasaMedis['uang_makan'] /
                          widget.dataJasaMedis['jasa_pelayanan_akun']
                              ['jm_ok_mitra']) -
                      (widget.dataJasaMedis['uang_makan']),
                  0,
                );
        pot_uang_makan = (widget.dataJasaMedis['uang_makan'] /
                widget.dataJasaMedis['jasa_pelayanan_akun']['jm_ok_mitra']) -
            (widget.dataJasaMedis['uang_makan']);
      } else {
        map["Potongan Uang Makan"] = showIcon
            ? '* * * * *'
            : '(-) ' +
                Helper.convertToIdr(
                  (widget.dataJasaMedis['uang_makan'] /
                          widget.dataJasaMedis['jasa_pelayanan_akun']
                              ['jm_rs']) -
                      (widget.dataJasaMedis['uang_makan']),
                  0,
                );
        pot_uang_makan = (widget.dataJasaMedis['uang_makan'] /
                widget.dataJasaMedis['jasa_pelayanan_akun']['jm_rs']) -
            (widget.dataJasaMedis['uang_makan']);
      }
    }

      map["Potongan Obat"] = showIcon
          ? '* * * * *'
          : '(-) ' +
              Helper.convertToIdr(
                (widget.dataJasaMedis['potongan_obat']),
                0,
              );


      map["Potongan Lain"] = showIcon
          ? '* * * * *'
          : '(-) ' +
              Helper.convertToIdr(
                (widget.dataJasaMedis['potongan_lain']),
                0,
              );

    jm_potong = widget.dataJasaMedis['potongan_lain'] +
        widget.dataJasaMedis['potongan_obat'] +
        (((widget.dataJasaMedis['jm_total_full'] != 0
                    ? widget.dataJasaMedis['jm_total_full']
                    : widget.dataJasaMedis['jm_total_share']) +
                (widget.dataJasaMedis['jm_ruang_full'] != 0
                    ? widget.dataJasaMedis['jm_ruang_full']
                    : widget.dataJasaMedis['jm_ruang_share'])) -
            (widget.dataJasaMedis['jm_total_share'] +
                widget.dataJasaMedis['jm_ruang_share'])) +
        pot_asisten_ok +
        pot_uang_makan + ((widget.dataJasaMedis['jm_total_full'] +
        widget.dataJasaMedis['jm_ruang_full']) * widget.dataJasaMedis['potongan_jaspel']);
    if (jm_potong != 0) {
      map["Total Potongan"] = showIcon
          ? '* * * * *'
          : Helper.convertToIdr(
              jm_potong,
              0,
            );
    }
    map["Jaspel Diterima"] = showIcon
        ? '* * * * *'
        : Helper.convertToIdr(
            jm_bersih - jm_potong,
            0,
          );

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
                          fontSize: 18,
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
                  GenTableJaspel(
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
