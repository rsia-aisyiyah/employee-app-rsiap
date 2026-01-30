import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_berkas_pegawai.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_list.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class BerkasPegawai extends StatefulWidget {
  const BerkasPegawai({super.key});

  @override
  State<BerkasPegawai> createState() => _BerkasPegawaiState();
}

class _BerkasPegawaiState extends State<BerkasPegawai> {
  final box = GetStorage();
  List dataBerkas = [];
  List filteredBerkas = [];
  Map links = {};
  Map meta = {};
  bool isLoding = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBerkas().then((value) {
      if (mounted) {
        _setData(value);
      }
    });
  }

  _setData(value) {
    setState(() {
      dataBerkas = value['data'] ?? [];
      filteredBerkas = dataBerkas;
      links = value['links'] ?? {};
      meta = value['meta'] ?? {};
      isLoding = false;
    });
  }

  void _filterBerkas(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredBerkas = dataBerkas;
      } else {
        filteredBerkas = dataBerkas.where((berkas) {
          final master = berkas['master_berkas_pegawai'] ?? {};
          final name = master['nama_berkas']?.toString().toLowerCase() ?? '';
          final type = berkas['berkas']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              type.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future fetchBerkas() async {
    var res = await Api().getData("/pegawai/${box.read('sub')}/berkas");
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      return body;
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);
      return body;
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
      child: Column(
        children: [
          Row(
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
                "Berkas Kepegawaian",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: _filterBerkas,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Cari nama berkas...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: primaryColor,
                  size: 20,
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 35),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 30, minHeight: 0),
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          searchController.clear();
                          _filterBerkas('');
                        },
                      )
                    : null,
              ),
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
            child: isLoding
                ? const SkeletonList()
                : filteredBerkas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                searchController.text.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.folder_off,
                                size: 80,
                                color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text(
                              searchController.text.isNotEmpty
                                  ? "Berkas tidak ditemukan"
                                  : "Belum ada berkas",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredBerkas.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {},
                            child: CardBerkasPegawai(
                              dataBerkasPegawai: filteredBerkas[index],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
