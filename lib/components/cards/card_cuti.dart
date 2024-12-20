
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/helper.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class CardCuti extends StatefulWidget {
  final Map dataCuti;
  final Function onDelete;

  const CardCuti({
    super.key,
    required this.dataCuti,
    required this.onDelete,
  });

  @override
  State<CardCuti> createState() => _CardCutiState();
}

class _CardCutiState extends State<CardCuti> {
  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 90,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: bgWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            Helper.dayToNum(
                              widget.dataCuti['tanggal_cuti'].toString(),
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              color: textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Helper.daytoMonth(
                              widget.dataCuti['tanggal_cuti'].toString(),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: textWhite,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Text(
                            Helper.daytoYear(
                              widget.dataCuti['tanggal_cuti'].toString(),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Helper.numtoDayFull(widget
                                      .dataCuti['tanggal_cuti']
                                      .toString()),
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  widget.dataCuti['jenis'].toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                              ],
                            ),
                            widget.dataCuti['status_cuti'].toString() == "2"
                                ? textDisetujui()
                                : widget.dataCuti['status_cuti'].toString() == "0"
                                    ? textPengajuan()
                                    : textDitolak(),
                            // Icon(
                            //   Icons.check_circle_rounded,
                            //   color: Colors.green,
                            //   size: 28,
                            // )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            widget.dataCuti['status_cuti'].toString() == "0"
                ? Positioned(
                    top: -18,
                    right: -18,
                    child: ElevatedButton(
                      onPressed: () async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              iconPadding: const EdgeInsets.only(top: 15,bottom: 10),
                              icon: const Icon(Icons.warning,color: Colors.orangeAccent,size: 32,),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              title: const Text("Hapus Pengajuan Cuti"),
                              content: const Text(
                                "Apakah anda yakin akan menghapus pengajuan cuti ?",
                              ),
                              actionsAlignment: MainAxisAlignment.spaceAround,
                              actions: <Widget>[
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("NO"),
                                ),
                                ElevatedButton(
                                  style:
                                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => widget.onDelete().then((value) {
                                    if (value) {
                                      Navigator.of(context).pop(true);
                                    } else {
                                      Msg.error(
                                        context,
                                        "Gagal menghapus pengajuan cuti",
                                      );
                                    }
                                  }),
                                  child: const Text("YES"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(5),
                        minimumSize: const Size(25, 25),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.dangerous_sharp,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  )
                : Container()
          ],
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}

Widget textDisetujui() {
  return const Row(
    children: [
      Text(
        "Disetujui",
        style: TextStyle(
          fontSize: 16,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(width: 10),
      Icon(
        Icons.check_circle_rounded,
        color: Colors.green,
        size: 28,
      )
    ],
  );
}

Widget textPengajuan() {
  return const Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        "Pengajuan",
        style: TextStyle(
          fontSize: 16,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(width: 10),
      Icon(
        Icons.send_rounded,
        color: Colors.blue,
        size: 20,
      )
    ],
  );
}

Widget textDitolak() {
  return const Row(
    children: [
      Text(
        "Ditolak",
        style: TextStyle(
          fontSize: 16,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(width: 10),
      Icon(
        Icons.dangerous,
        color: Colors.red,
        size: 28,
      )
    ],
  );
}
