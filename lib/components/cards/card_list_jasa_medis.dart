import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
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
      map["JasPel"] = showIcon
          ? '* * * * *'
          : Helper.convertToIdr(
              (widget.jp.jmRuangShare ?? 0) + (widget.jp.jmTotalShare ?? 0), 0);
    }

    if (widget.jp.jmAsistenOk != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Asisten OK"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr(((widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)), 0)}';
        asistenOk = (widget.jp.jmAsistenOk ?? 0) /
            (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0);
      } else {
        map["Asisten OK"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr(((widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)), 0)}';
        asistenOk = (widget.jp.jmAsistenOk ?? 0) /
            (widget.jp.jasaPelayananAkun?.jmRs ?? 0);
      }
    }
    if (widget.jp.uangMakan != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Uang Makan"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr(((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)), 0)}';
        uangMakan = (widget.jp.uangMakan ?? 0) /
            (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0);
      } else {
        map["Uang Makan"] = showIcon
            ? '* * * * *'
            : '(+) ${Helper.convertToIdr(((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)), 0)}';
        uangMakan = (widget.jp.uangMakan ?? 0) /
            (widget.jp.jasaPelayananAkun?.jmRs ?? 0);
      }
    }

    map["Lebih Jam"] = showIcon
        ? '* * * * *'
        : '(+) ${Helper.convertToIdr(widget.jp.lebihJam, 0)}';

    if (widget.jp.oncallOk != 0) {
      map["Oncall"] = showIcon
          ? '* * * * *'
          : '(+) ${Helper.convertToIdr(widget.jp.oncallOk, 0)}';
    }

    map["Tambahan Lain"] = showIcon
        ? '* * * * *'
        : '(+) ${Helper.convertToIdr(widget.jp.tambahan, 0)}';

    jmBersih = (widget.jp.jmTotalFull ?? widget.jp.jmTotalShare ?? 0) +
        (widget.jp.jmRuangFull ?? widget.jp.jmRuangShare ?? 0) +
        asistenOk +
        (widget.jp.lebihJam ?? 0) +
        (widget.jp.oncallOk ?? 0) +
        uangMakan +
        (widget.jp.tambahan ?? 0);

    if (widget.jp.jmTotalShare != 0) {
      map["JasPel Bruto"] =
          showIcon ? '* * * * *' : Helper.convertToIdr(jmBersih, 0);
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
        potAsistenOk = ((widget.jp.jmAsistenOk ?? 0) /
                (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)) -
            (widget.jp.jmAsistenOk ?? 0);
      } else {
        map["Potongan Asisten OK"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr(((widget.jp.jmAsistenOk ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)) - ((widget.jp.jmAsistenOk ?? 0)), 0)}';
        potAsistenOk = ((widget.jp.jmAsistenOk ?? 0) /
                (widget.jp.jasaPelayananAkun?.jmRs ?? 0)) -
            (widget.jp.jmAsistenOk ?? 0);
      }
    }
    if (widget.jp.uangMakan != 0) {
      if (widget.jp.sttsKerja == 'Karyawan Mitra') {
        map["Potongan Uang Makan"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr(((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)) - ((widget.jp.uangMakan ?? 0)), 0)}';
        potUangMakan = ((widget.jp.uangMakan ?? 0) /
                (widget.jp.jasaPelayananAkun?.jmOkMitra ?? 0)) -
            ((widget.jp.uangMakan ?? 0));
      } else {
        map["Potongan Uang Makan"] = showIcon
            ? '* * * * *'
            : '(-) ${Helper.convertToIdr(((widget.jp.uangMakan ?? 0) / (widget.jp.jasaPelayananAkun?.jmRs ?? 0)) - ((widget.jp.uangMakan ?? 0)), 0)}';
        potUangMakan = ((widget.jp.uangMakan ?? 0) /
                (widget.jp.jasaPelayananAkun?.jmRs ?? 0)) -
            ((widget.jp.uangMakan ?? 0));
      }
    }

    map["Potongan Obat"] = showIcon
        ? '* * * * *'
        : '(-) ${Helper.convertToIdr((widget.jp.potonganObat), 0)}';

    map["Potongan Lain"] = showIcon
        ? '* * * * *'
        : '(-) ${Helper.convertToIdr((widget.jp.potonganLain), 0)}';

    jmPotong = (widget.jp.potonganLain ?? 0) +
        (widget.jp.potonganObat ?? 0) +
        (((widget.jp.jmTotalFull ?? widget.jp.jmTotalShare ?? 0) +
                (widget.jp.jmRuangFull ?? widget.jp.jmRuangShare ?? 0)) -
            ((widget.jp.jmTotalShare ?? 0) + (widget.jp.jmRuangShare ?? 0))) +
        potAsistenOk +
        potUangMakan +
        (((widget.jp.jmTotalFull ?? 0) + (widget.jp.jmRuangFull ?? 0)) *
            (widget.jp.potonganJaspel ?? 0));

    if (jmPotong != 0) {
      map["Total Potongan"] =
          showIcon ? '* * * * *' : Helper.convertToIdr(jmPotong, 0);
    }
    // Removed Jaspel Diterima from map to display separately
    // map["Jaspel Diterima"] = showIcon ? '* * * * *' : Helper.convertToIdr(jmBersih - jmPotong, 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Helper.numToMonth(
                          int.tryParse(widget.jp.bulan ?? '') ?? 1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      widget.jp.tahun ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _changeIcon,
                  icon: Icon(
                    showIcon ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // Body (Table)
          Padding(
            padding: const EdgeInsets.all(15),
            child: GenTableJaspel(
              data: map,
              textStyle: const TextStyle(
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // Footer (Total)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              border:
                  Border(top: BorderSide(color: primaryColor.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Jaspel Diterima",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  showIcon
                      ? '* * * * *'
                      : Helper.convertToIdr(jmBersih - jmPotong, 0),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
