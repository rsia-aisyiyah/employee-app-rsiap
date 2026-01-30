import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/components/cards/card_list_jasa_medis.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_list.dart';
import 'package:rsia_employee_app/config/colors.dart';
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
      final url = Uri.parse(
          "$baseUrl/api/v2/pegawai/${box.read('sub')}/jasa/pelayanan");
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
      return Future.error(e.toString());
    }
  }

  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 25,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          const Text(
            "Info Jasa Medis",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: FutureBuilder<JasaPelayanan>(
              future: fetchJasaPelayanan(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<JPData>? data = snapshot.data!.data;
                  if (data == null || data.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            "Belum ada data jasa medis",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return CreateCardJasaMedis(jp: data[index]);
                    },
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('${snapshot.error}'),
                  );
                }

                return const SkeletonList();
              },
            ),
          ),
        ],
      ),
    );
  }
}
