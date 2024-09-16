import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/table_jaspel.dart';

import '../../models/JasaPelayanan.dart';

class CreateCardJasaMedis extends StatefulWidget {
  final JPData jp;

  const CreateCardJasaMedis({
    super.key,
    required this.jp,
  });

  @override
  State<CreateCardJasaMedis> createState() => _CreateCardJasaMedisState();
}

class _CreateCardJasaMedisState extends State<CreateCardJasaMedis> {
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
      map["JasPel"] = showIcon ? '* * * * *' : Helper.convertToIdr((widget.jp.jmRuangShare ?? 0) + (widget.jp.jmTotalShare ?? 0), 0);
    }

    if (widget.jp.jmAsistenOk != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Asisten OK"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr(((widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)), 0)}';
        asistenOk = (widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0);
      } else {
        map["Asisten OK"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr(((widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)), 0)}';
        asistenOk = (widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0);
      }
    }
    if (widget.jp.uangMakan != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Uang Makan"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr(((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)), 0)}';
        uangMakan = (widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0);
      } else {
        map["Uang Makan"] =
            showIcon ? '* * * * *' : '(+) ${Helper.convertToIdr(((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)), 0)}';
        uangMakan = (widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0);
      }
    }

    map["Lebih Jam"] = showIcon ? '* * * * *' : '(+) ${Helper.convertToIdr(widget.jp.lebihJam, 0)}';

    if (widget.jp.oncallOk != 0) {
      map["Oncall"] = showIcon ? '* * * * *' : '(+) ${Helper.convertToIdr(widget.jp.oncallOk, 0)}';
    }

    map["Tambahan Lain"] = showIcon ? '* * * * *' : '(+) ${Helper.convertToIdr(widget.jp.tambahan, 0)}';

    jmBersih = (widget.jp.jmTotalFull ?? widget.jp.jmTotalShare ?? 0) +
        (widget.jp.jmRuangFull ?? widget.jp.jmRuangShare ?? 0) +
        asistenOk +
        (widget.jp.lebihJam ?? 0) +
        (widget.jp.oncallOk ?? 0) +
        uangMakan +
        (widget.jp.tambahan ?? 0);

    if (widget.jp.jmTotalShare != 0) {
      map["JasPel Bruto"] = showIcon ? '* * * * *' : Helper.convertToIdr(jmBersih, 0);
    }
    if (widget.jp.jmTotalFull != 0 && widget.jp.jmRuangFull != 0) {
      map["Potongan JasPel"] = showIcon
          ? '* * * * *'
          : '(-) ${Helper.convertToIdr(((widget.jp.jmTotalFull ?? 0) + (widget.jp.jmRuangFull ?? 0)) - ((widget.jp.jmTotalShare ?? 0) + (widget.jp.jmRuangShare ?? 0)) + (((widget.jp.jmTotalFull ?? 0) + (widget.jp.jmRuangFull ?? 0)) * (widget.jp.potonganJaspel ?? 0)), 0)}';
    }
    if (widget.jp.jmAsistenOk != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Potongan Asisten OK"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr(((widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)) - ((widget.jp.jmAsistenOk ?? 0)), 0)}';
        potAsistenOk = ((widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)) - (widget.jp.jmAsistenOk ?? 0);
      } else {
        map["Potongan Asisten OK"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr(((widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)) - ((widget.jp.jmAsistenOk ?? 0)), 0)}';
        potAsistenOk = ((widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)) - (widget.jp.jmAsistenOk ?? 0);
      }
    }
    if (widget.jp.uangMakan != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Potongan Uang Makan"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr(((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)) - ((widget.jp.uangMakan ?? 0)), 0)}';
        potUangMakan = ((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)) - ((widget.jp.uangMakan ?? 0));
      } else {
        map["Potongan Uang Makan"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr(((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)) - ((widget.jp.uangMakan ?? 0)), 0)}';
        potUangMakan = ((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)) - ((widget.jp.uangMakan ?? 0));
      }
    }

    map["Potongan Obat"] = showIcon ? '* * * * *' : '(-) ${Helper.convertToIdr((widget.jp.potonganObat), 0)}';

    map["Potongan Lain"] = showIcon ? '* * * * *' : '(-) ${Helper.convertToIdr((widget.jp.potonganLain), 0)}';

    jmPotong = (widget.jp.potonganLain ?? 0) + (widget.jp.potonganObat ?? 0) +
        (
            (
                (widget.jp.jmTotalFull ?? widget.jp.jmTotalShare ?? 0) +
                (widget.jp.jmRuangFull ?? widget.jp.jmRuangShare ?? 0)
            ) -
            ((widget.jp.jmTotalShare ?? 0) + (widget.jp.jmRuangShare ?? 0))
        ) +
        potAsistenOk +
        potUangMakan +
        (((widget.jp.jmTotalFull ?? 0) + (widget.jp.jmRuangFull ?? 0)) * (widget.jp.potonganJaspel ?? 0));

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
                        "${Helper.numToMonth(int.tryParse(widget.jp.bulan ?? '') ?? 1)} ${widget.jp.tahun ?? ''}",
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
