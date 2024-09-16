import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/helper.dart';

cardPresensi(presensi) {
  return Column(
    children: [
      Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      height: 55,
                      width: 65,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: bgWhite,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Helper.dayToNum(presensi['jam_datang']),
                            style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            Helper.numtoDay(presensi['jam_datang']),
                            style: TextStyle(color: textColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      alignment: Alignment.topCenter,
                      height: 55,
                      width: 70,
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        Helper.dateToMonthYear(presensi['jam_datang']),
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgWhite,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "Masuk",
                                  style: TextStyle(color: textColor),
                                ),
                                Text(
                                  Helper.dateTimeToDate(presensi['jam_datang']),
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.green,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgWhite,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "Pulang",
                                  style: TextStyle(color: textColor),
                                ),
                                Text(
                                  Helper.dateTimeToDate(presensi['jam_pulang']),
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.timer_off_outlined,
                              color: Colors.red,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                        // alignment: Alignment.center,
                        height: 40,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgWhite,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  presensi['status'],
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            presensi['status'] == "Tepat Waktu"
                                ? const Icon(
                                    Icons.info_rounded,
                                    color: Colors.greenAccent,
                                  )
                                : presensi['status'] == "Terlambat Toleransi"
                                    ? Icon(
                                        Icons.info_rounded,
                                        color: Colors.amber[300],
                                      )
                                    : const Icon(
                                        Icons.info_rounded,
                                        color: Colors.red,
                                      )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      )
    ],
  );
}
