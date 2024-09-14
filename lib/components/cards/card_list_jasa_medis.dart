import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/table_jaspel.dart';

import '../../models/JasaPelayanan.dart';

class createCardJasaMedis extends StatefulWidget {
  final JPData jp;

  const createCardJasaMedis({
    super.key,
    required this.jp,
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
    Map map = {};
    num asistenOk = 0;
    num uangMakan = 0;
    num potAsistenOk = 0;
    num potUangMakan = 0;
    num jmBersih = 0;
    num jmPotong = 0;

    if (widget.jp.jmRuangShare != 0 && widget.jp.jmTotalShare != 0) {
      map["JasPel"] = showIcon ? '* * * * *' : Helper.convertToIdr(widget.jp.jmRuangShare! + widget.jp.jmTotalShare!, 0);
    }

    if (widget.jp.jmAsistenOk != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Asisten OK"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr((widget.jp.jmAsistenOk! / widget.jp.jasaPelayananAkun!.jmOkMitra!), 0)}';
        asistenOk = widget.jp.jmAsistenOk! / widget.jp.jasaPelayananAkun!.jmOkMitra!;
      } else {
        map["Asisten OK"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr((widget.jp.jmAsistenOk! / widget.jp.jasaPelayananAkun!.jmRs!), 0)}';
        asistenOk = widget.jp.jmAsistenOk! / widget.jp.jasaPelayananAkun!.jmRs!;
      }
    }
    if (widget.jp.uangMakan != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Uang Makan"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr((widget.jp.uangMakan! / widget.jp.jasaPelayananAkun!.jmOkMitra!), 0)}';
        uangMakan = widget.jp.uangMakan! / widget.jp.jasaPelayananAkun!.jmOkMitra!;
      } else {
        map["Uang Makan"] =
            showIcon ? '* * * * *' : '(+) ${Helper.convertToIdr((widget.jp.uangMakan! / widget.jp.jasaPelayananAkun!.jmRs!), 0)}';
        uangMakan = widget.jp.uangMakan! / widget.jp.jasaPelayananAkun!.jmRs!;
      }
    }

    map["Lebih Jam"] = showIcon ? '* * * * *' : '(+) ${Helper.convertToIdr(widget.jp.lebihJam, 0)}';

    if (widget.jp.oncallOk != 0) {
      map["Oncall"] = showIcon ? '* * * * *' : '(+) ${Helper.convertToIdr(widget.jp.oncallOk, 0)}';
    }

    map["Tambahan Lain"] = showIcon ? '* * * * *' : '(+) ${Helper.convertToIdr(widget.jp.tambahan, 0)}';

    jmBersih = (widget.jp.jmTotalFull != 0 ? widget.jp.jmTotalFull : widget.jp.jmTotalShare)! +
        (widget.jp.jmRuangFull != 0 ? widget.jp.jmRuangFull : widget.jp.jmRuangShare)! +
        asistenOk +
        widget.jp.lebihJam! +
        widget.jp.oncallOk! +
        uangMakan +
        widget.jp.tambahan!;

    if (widget.jp.jmTotalShare != 0) {
      map["JasPel Bruto"] = showIcon ? '* * * * *' : Helper.convertToIdr(jmBersih, 0);
    }
    if (widget.jp.jmTotalFull != 0 && widget.jp.jmRuangFull != 0) {
      map["Potongan JasPel"] = showIcon
          ? '* * * * *'
          : '(-) ${Helper.convertToIdr((widget.jp.jmTotalFull! + widget.jp.jmRuangFull!) - (widget.jp.jmTotalShare! + widget.jp.jmRuangShare!) + ((widget.jp.jmTotalFull! + widget.jp.jmRuangFull!) * widget.jp.potonganJaspel!), 0)}';
    }
    if (widget.jp.jmAsistenOk != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Potongan Asisten OK"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr((widget.jp.jmAsistenOk! / widget.jp.jasaPelayananAkun!.jmOkMitra!) - (widget.jp.jmAsistenOk!), 0)}';
        potAsistenOk = (widget.jp.jmAsistenOk! / widget.jp.jasaPelayananAkun!.jmOkMitra!) - widget.jp.jmAsistenOk!;
      } else {
        map["Potongan Asisten OK"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr((widget.jp.jmAsistenOk! / widget.jp.jasaPelayananAkun!.jmRs!) - (widget.jp.jmAsistenOk!), 0)}';
        potAsistenOk = (widget.jp.jmAsistenOk! / widget.jp.jasaPelayananAkun!.jmRs!) - widget.jp.jmAsistenOk!;
      }
    }
    if (widget.jp.uangMakan != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Potongan Uang Makan"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr((widget.jp.uangMakan! / widget.jp.jasaPelayananAkun!.jmOkMitra!) - (widget.jp.uangMakan!), 0)}';
        potUangMakan = (widget.jp.uangMakan! / widget.jp.jasaPelayananAkun!.jmOkMitra!) - (widget.jp.uangMakan!);
      } else {
        map["Potongan Uang Makan"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr((widget.jp.uangMakan! / widget.jp.jasaPelayananAkun!.jmRs!) - (widget.jp.uangMakan!), 0)}';
        potUangMakan = (widget.jp.uangMakan! / widget.jp.jasaPelayananAkun!.jmRs!) - (widget.jp.uangMakan!);
      }
    }

    map["Potongan Obat"] = showIcon ? '* * * * *' : '(-) ${Helper.convertToIdr((widget.jp.potonganObat), 0)}';

    map["Potongan Lain"] = showIcon ? '* * * * *' : '(-) ${Helper.convertToIdr((widget.jp.potonganLain), 0)}';

    jmPotong = widget.jp.potonganLain! +
        widget.jp.potonganObat! +
        (((widget.jp.jmTotalFull != 0 ? widget.jp.jmTotalFull : widget.jp.jmTotalShare)! +
                (widget.jp.jmRuangFull != 0 ? widget.jp.jmRuangFull : widget.jp.jmRuangShare)!) -
            (widget.jp.jmTotalShare! + widget.jp.jmRuangShare!)) +
        potAsistenOk +
        potUangMakan +
        ((widget.jp.jmTotalFull! + widget.jp.jmRuangFull!) * widget.jp.potonganJaspel!);

    if (jmPotong != 0) {
      map["Total Potongan"] = showIcon ? '* * * * *' : Helper.convertToIdr(jmPotong, 0);
    }
    map["Jaspel Diterima"] = showIcon ? '* * * * *' : Helper.convertToIdr(jmBersih - jmPotong, 0);

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
                        "${Helper.numToMonth(int.parse(widget.jp.bulan!))} ${widget.jp.tahun!}",
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
                              icon: Icon(showIcon ? Icons.visibility_off : Icons.visibility),
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GenTableJaspel(
                    data: map,
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
