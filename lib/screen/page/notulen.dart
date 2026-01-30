import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/helper.dart';

class NotulenPage extends StatefulWidget {
  final Map dataUdgn;

  const NotulenPage({super.key, required this.dataUdgn});

  @override
  State<NotulenPage> createState() => _NotulenPageState();
}

class _NotulenPageState extends State<NotulenPage> {
  @override
  void initState() {
    super.initState();
  }

  Future fetchNotulen() async {
    final String url =
        "/undangan/${base64Url.encode(utf8.encode(widget.dataUdgn['id'].toString()))}/notulen";

    try {
      var res = await Api().getData(url);

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        return body;
      } else {
        throw Exception('Failed to load data: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print("DEBUG: Exception in fetchNotulen: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgWhite.withAlpha(500),
      appBar: AppBar(
        title: Text(
          "Notulen Rapat",
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
        future: fetchNotulen(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var data = snapshot.data['data'];

            if (data == null || data.isEmpty) {
              return const Center(
                child: Text("Data notulen tidak ditemukan"),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Metadata Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.description,
                                  color: primaryColor, size: 24),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Text(
                                "NOTULEN RAPAT",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          data['perihal'] ?? '-',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: fontSemiBold,
                            color: textColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              data['tanggal'] != null
                                  ? '${Helper.formatDate(data['tanggal'])} ${Helper.dateTimeToDate(data['tanggal'])}'
                                  : '-',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['tempat'] ?? '-',
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Content Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPersonRow("Pemimpin Rapat",
                            data['penanggung_jawab']['nama'] ?? '-'),
                        const SizedBox(height: 15),
                        _buildPersonRow(
                            "Notulis",
                            data['notulen'] != null
                                ? data['notulen']['nama']
                                : '-'),
                        const SizedBox(height: 25),
                        const Text(
                          "Pembahasan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: bgColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: HtmlWidget(
                            data['notulen'] != null
                                ? data['notulen']['pembahasan'] ?? '-'
                                : '-',
                            textStyle: const TextStyle(height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Dibuat: ${data['notulen'] == null ? "-" : Helper.formatDate(data['notulen']['created_at'])}",
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          return loadingku();
        },
      ),
    );
  }

  Widget _buildPersonRow(String label, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: fontSemiBold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
