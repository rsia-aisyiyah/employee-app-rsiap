import 'package:flutter/material.dart';

// ignore: must_be_immutable
class GenTableJaspel extends StatelessWidget {
  Map data;
  TextStyle? textStyle;
  TextAlign? textAlign;

  GenTableJaspel({
    super.key,
    required this.data,
    this.textStyle,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
      },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      textBaseline: TextBaseline.alphabetic,
      children: data.entries.map((e) {
        print(e.key);
        return TableRow(
          children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.fill,
              child: Container(
                color: e.key == "JasPel" ||
                    e.key == "JasPel Bruto" ||
                    e.key == "Total Potongan" ||
                    e.key == "Jaspel Diterima"
                    ? Colors.grey[300] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: e.key == "JasPel" ||
                          e.key == "JasPel Bruto" ||
                          e.key == "Total Potongan" ||
                          e.key == "Jaspel Diterima"
                      ? Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
            TableCell(
              child: Container(
                color: e.key == "JasPel" ||
                    e.key == "JasPel Bruto" ||
                    e.key == "Total Potongan" ||
                    e.key == "Jaspel Diterima"
                    ? Colors.grey[300] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: e.key == "JasPel" ||
                          e.key == "JasPel Bruto" ||
                          e.key == "Total Potongan" ||
                          e.key == "Jaspel Diterima"
                      ? Text(
                          e.value,
                          textAlign: textAlign ?? TextAlign.right,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold,),
                        )
                      : Text(
                          e.value,
                          textAlign: textAlign ?? TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
