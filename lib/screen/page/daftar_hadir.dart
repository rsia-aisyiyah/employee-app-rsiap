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
    final String url =
        "/undangan/${base64Encode(utf8.encode(widget.dataUdgn['no_surat'].toString()))}";
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
                  decoration: BoxDecoration(
                    color: bgWhite,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Section
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              penerima['pegawai']['nama'] != null &&
                                      penerima['pegawai']['nama'].isNotEmpty
                                  ? penerima['pegawai']['nama'][0]
                                  : '?',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Content Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                penerima['pegawai']['nama'] ?? '-',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: fontSemiBold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                penerima['pegawai']['jbtn'] ?? '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: penerima['kehadiran'] != null
                                          ? greenColor.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          penerima['kehadiran'] != null
                                              ? Icons.check_circle_outline
                                              : Icons.cancel_outlined,
                                          size: 14,
                                          color: penerima['kehadiran'] != null
                                              ? greenColor
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          penerima['kehadiran'] != null
                                              ? "Hadir"
                                              : "Belum Hadir",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: penerima['kehadiran'] != null
                                                ? greenColor
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (penerima['kehadiran'] != null) ...[
                                    const Spacer(),
                                    Text(
                                      penerima['kehadiran']['created_at']
                                              .toString()
                                              .split(' ')
                                              .last ??
                                          '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
