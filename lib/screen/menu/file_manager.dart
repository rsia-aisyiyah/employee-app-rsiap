import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/cards/card_file_manager.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_list.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class FileManager extends StatefulWidget {
  const FileManager({super.key});

  @override
  State<FileManager> createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  bool isLoding = true;
  List dataFileManager = [];
  List filteredFileManager = [];
  late String title;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialSet();
    fetchFileManager().then((value) {
      if (mounted) {
        _setData(value);
      }
    });
  }

  _initialSet() {
    title = "Dokumen & Surat";
  }

  _setData(value) {
    setState(() {
      dataFileManager = value['data'] ?? [];
      filteredFileManager = dataFileManager;
      isLoding = false;
    });
  }

  void _filterFileManager(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFileManager = dataFileManager;
      } else {
        filteredFileManager = dataFileManager.where((file) {
          final name = file['nama_file']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future fetchFileManager() async {
    var res = await Api().getData("/rsia/file/manager");
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
              Text(
                title,
                style: const TextStyle(
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
              onChanged: _filterFileManager,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Cari nama dokumen...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon:
                    Icon(Icons.search_rounded, color: primaryColor, size: 20),
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
                          _filterFileManager('');
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
                : filteredFileManager.isEmpty
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
                                  ? "Dokumen tidak ditemukan"
                                  : "Belum ada dokumen",
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
                        padding: const EdgeInsets.all(20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredFileManager.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {},
                            child: CardFileManager(
                              dataFileManager: filteredFileManager[index],
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
