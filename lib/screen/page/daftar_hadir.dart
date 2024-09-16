import 'dart:convert';

import 'package:flutter/material.dart';

import '../../api/request.dart';
import '../../config/colors.dart';
import '../../utils/fonts.dart';
import '../../components/loadingku.dart';

class DaftarHadirPage extends StatefulWidget {
  final Map dataUdgn;

  const DaftarHadirPage({super.key, required this.dataUdgn});

  @override
  State<DaftarHadirPage> createState() => _DaftarHadirPageState();
}

class _DaftarHadirPageState extends State<DaftarHadirPage> {
  Future fetchUndangan() async {
    final String url = "/undangan/${base64Encode(utf8.encode(widget.dataUdgn['no_surat'].toString()))}";
    var res = await Api().getData(url);

    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      return body;
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgWhite.withAlpha(500),
      appBar: AppBar(
        title: Text(
          "Daftar Hadir",
          style: TextStyle(
            color: textWhite,
            fontSize: 18,
            fontWeight: fontSemiBold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: textWhite,
          ),
        ),
      ),
      body: FutureBuilder(
        future: fetchUndangan(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data['data'];
            if (data['penerima'] == null || data['penerima'].length == 0) {
              return const Center(
                child: Text("Tidak ada data"),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: data['penerima'].length,
              itemBuilder: (context, index) {
                final penerima = data['penerima'][index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: bgWhite,
                    border: Border.all(
                      color: penerima['kehadiran'] != null ? greenColor : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            penerima['pegawai']['nama'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: fontSemiBold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            penerima['pegawai']['jbtn'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            penerima['penerima'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),

                          if (penerima['kehadiran'] != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              "Kehadiran: ${penerima['kehadiran']['created_at']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ]
                        ],

                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: penerima['kehadiran'] != null ? greenColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          penerima['kehadiran'] != null ? Icons.check : Icons.close,
                          color: textWhite,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          return loadingku();
        },
      ),
    );
  }
}
