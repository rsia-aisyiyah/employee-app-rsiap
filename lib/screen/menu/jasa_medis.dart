import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_list_jasa_medis.dart';
import 'package:rsia_employee_app/components/filter/bottom_sheet_filter.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/models/JasaPelayanan.dart';

import '../../config/config.dart';


class JasaMedis extends StatefulWidget {
  const JasaMedis({
    super.key,
  });

  @override
  State<JasaMedis> createState() => JasaMedisState();
}

class JasaMedisState extends State<JasaMedis> {
  final box = GetStorage();

  // fetch data
  Future<JasaPelayanan> fetchJasaPelayanan() async {
    try {
      final url = Uri.parse("$baseUrl/api/v2/pegawai/${box.read('sub')}/jasa/pelayanan");
      final response = await http.get(
          url,
          headers: {'Authorization': 'Bearer ${box.read('token')}'},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        var jasaPelayanan = JasaPelayanan.fromJson(data);
        return jasaPelayanan;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("ERROR: $e");
      return Future.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jasa Medis', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.filter_alt_outlined),
        //     onPressed: () {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(
        //           content: Text('Filter'),
        //           duration: Duration(seconds: 1),
        //         ),
        //       );
        //
        //       // showModalBottomSheet(
        //       //   context: context,
        //       //   builder: (BuildContext context) {
        //       //     // return BottomSheetFilter();
        //       //   },
        //       // );
        //     },
        //   ),
        // ],
      ),
      body: FutureBuilder<JasaPelayanan>(
        future: fetchJasaPelayanan(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<JPData>? data = snapshot.data!.data;
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: data!.length,
              itemBuilder: (context, index) {
                return createCardJasaMedis(jp: data[index],);
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'),
            );
          }
          return loadingku();
        },
      ),
    );
  }
}
