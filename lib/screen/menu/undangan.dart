import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/screen/page/daftar_hadir.dart';
import 'package:rsia_employee_app/screen/page/notulen.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_list.dart';

import 'package:rsia_employee_app/utils/fonts.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/utils/table.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rsia_employee_app/config/colors.dart';

class Undangan extends StatefulWidget {
  const Undangan({super.key});

  @override
  State<Undangan> createState() => _UndanganState();
}

class _UndanganState extends State<Undangan> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final box = GetStorage();

  List dataUndangan = [];
  List filteredUndangan = [];
  Map links = {};
  Map meta = {};

  bool isLoading = true;
  bool btnLoading = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    fetchUndangan().then((value) {
      _setData(value['data'] ?? []);

      setState(() {
        meta = value['meta'] ?? {};
        links = value['links'] ?? {};
      });
    });
    super.initState();
  }

  Future fetchUndangan() async {
    var payload = {
      "scopes": [
        {
          "name": "filterByPenerima",
          "parameters": [box.read('sub')]
        }
      ],
      "sort": [
        {"field": "created_at", "direction": "desc"}
      ]
    };

    print("DEBUG: Sending payload: ${jsonEncode(payload)}");

    var res = await Api().postData(payload, '/undangan/search');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      return body;
    } else {
      var body = json.decode(res.body);
      print("DEBUG: Error response: ${res.body}");
      Msg.error(context, body['message'] ?? "Terjadi Kesalahan");
      if (body['errors'] != null) {
        Msg.error(context, body['errors'].toString());
      }
      return body;
    }
  }

  void _setData(value) {
    setState(() {
      dataUndangan = value ?? [];
      filteredUndangan = dataUndangan;
      isLoading = false;
    });
  }

  void _filterUndangan(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUndangan = dataUndangan;
      } else {
        filteredUndangan = dataUndangan.where((undangan) {
          final subject = undangan['perihal']?.toString().toLowerCase() ?? '';
          final location = undangan['tempat']?.toString().toLowerCase() ?? '';
          return subject.contains(query.toLowerCase()) ||
              location.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> loadMore() async {
    if (links['next'] != null) {
      var res = await Api().postFullUrl({
        "scopes": [
          {
            "name": "filterByPenerima",
            "parameters": [box.read('sub')]
          }
        ],
        "sort": [
          {"field": "created_at", "direction": "desc"}
        ]
      }, links['next']);

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        setState(() {
          dataUndangan.addAll(body['data'] ?? []);
          filteredUndangan = dataUndangan;
          meta = body['meta'] ?? [];
          links = body['links'] ?? [];
        });
      } else {
        var body = json.decode(res.body);
        Msg.error(context, body['message']);
        setState(() {
          btnLoading = false;
        });
      }
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
                "Undangan",
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
              onChanged: _filterUndangan,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Cari perihal atau tempat...",
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
                          _filterUndangan('');
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
            child: isLoading
                ? const SkeletonList()
                : SmartRefresher(
                    enablePullDown: true,
                    enablePullUp: true,
                    controller: _refreshController,
                    header: const WaterDropHeader(),
                    onRefresh: () async {
                      setState(() {});
                      fetchUndangan().then((value) {
                        _setData(value['data'] ?? []);
                        setState(() {
                          meta = value['meta'] ?? [];
                          links = value['links'] ?? [];
                        });
                      });
                      await Future.delayed(const Duration(milliseconds: 1000));
                      _refreshController.refreshCompleted();
                    },
                    onLoading: () async {
                      await loadMore();

                      if (links['next'] == null) {
                        _refreshController.loadNoData();
                      } else {
                        _refreshController.loadComplete();
                      }
                    },
                    child: filteredUndangan.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    searchController.text.isNotEmpty
                                        ? Icons.search_off_rounded
                                        : Icons.mail_outline,
                                    size: 80,
                                    color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                Text(
                                  searchController.text.isNotEmpty
                                      ? "Undangan tidak ditemukan"
                                      : "Belum ada undangan",
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
                            itemCount: filteredUndangan.length,
                            itemBuilder: (context, i) {
                              var dataUdgn = filteredUndangan[i];
                              bool isUpcoming = false;
                              if (dataUdgn['tanggal'] != null) {
                                isUpcoming = DateTime.parse(dataUdgn['tanggal'])
                                    .isAfter(DateTime.now());
                              }

                              return InkWell(
                                onTap: () => showModalBottomSheet(
                                  showDragHandle: true,
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) => Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.55,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        // Header Handle
                                        Center(
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                top: 10, bottom: 20),
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),

                                        Expanded(
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Title Section
                                                Text(
                                                  dataUdgn['perihal'] ??
                                                      'Perihal tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: fontSemiBold,
                                                    color: textColor,
                                                    height: 1.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),

                                                // Details Section
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    color: bgColor
                                                        .withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                      color: primaryColor
                                                          .withOpacity(0.1),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      _buildDetailRow(
                                                        Icons
                                                            .calendar_today_outlined,
                                                        "Tanggal",
                                                        dataUdgn['tanggal'] !=
                                                                null
                                                            ? DateFormat(
                                                                    'EEEE, dd MMMM yyyy',
                                                                    'id_ID')
                                                                .format(DateTime.tryParse(
                                                                        dataUdgn[
                                                                            'tanggal']) ??
                                                                    DateTime
                                                                        .now())
                                                            : '-',
                                                      ),
                                                      const Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 12),
                                                        child:
                                                            Divider(height: 1),
                                                      ),
                                                      _buildDetailRow(
                                                        Icons
                                                            .access_time_outlined,
                                                        "Waktu",
                                                        dataUdgn['tanggal'] !=
                                                                null
                                                            ? "${DateFormat('HH:mm').format(DateTime.tryParse(dataUdgn['tanggal']) ?? DateTime.now())} WIB"
                                                            : '-',
                                                      ),
                                                      const Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 12),
                                                        child:
                                                            Divider(height: 1),
                                                      ),
                                                      _buildDetailRow(
                                                        Icons
                                                            .location_on_outlined,
                                                        "Tempat",
                                                        dataUdgn['tempat'] ??
                                                            '-',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Bottom Buttons
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.1),
                                                blurRadius: 10,
                                                offset: const Offset(0, -5),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(
                                                      Icons
                                                          .assignment_ind_outlined,
                                                      size: 20),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    foregroundColor: textWhite,
                                                    backgroundColor:
                                                        primaryColor,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                    elevation: 0,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                DaftarHadirPage(
                                                                    dataUdgn:
                                                                        dataUdgn)));
                                                  },
                                                  label: const Text(
                                                      "Daftar Hadir"),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  icon: const Icon(
                                                      Icons
                                                          .description_outlined,
                                                      size: 20),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        primaryColor,
                                                    side: BorderSide(
                                                        color: primaryColor),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                NotulenPage(
                                                                    dataUdgn:
                                                                        dataUdgn)));
                                                  },
                                                  label: const Text("Notulen"),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Date Box
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: isUpcoming
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              dataUdgn['tanggal'] != null
                                                  ? DateFormat('dd').format(
                                                      DateTime.parse(
                                                          dataUdgn['tanggal']))
                                                  : '--',
                                              style: TextStyle(
                                                color: isUpcoming
                                                    ? Colors.blue
                                                    : Colors.green,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              dataUdgn['tanggal'] != null
                                                  ? DateFormat('MMM').format(
                                                      DateTime.parse(
                                                          dataUdgn['tanggal']))
                                                  : '-',
                                              style: TextStyle(
                                                color: isUpcoming
                                                    ? Colors.blue
                                                    : Colors.green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              dataUdgn['tanggal'] != null
                                                  ? DateFormat('yyyy').format(
                                                      DateTime.parse(
                                                          dataUdgn['tanggal']))
                                                  : '-',
                                              style: TextStyle(
                                                color: isUpcoming
                                                    ? Colors.blue
                                                    : Colors.green,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 4),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isUpcoming
                                                    ? Colors.blue
                                                    : Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                dataUdgn['tanggal'] != null
                                                    ? DateFormat('HH:mm')
                                                        .format(DateTime.parse(
                                                            dataUdgn[
                                                                'tanggal']))
                                                    : '--:--',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dataUdgn['perihal'] ??
                                                  'Perihal tidak tersedia',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(Icons.location_on_outlined,
                                                    size: 14,
                                                    color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    dataUdgn['tempat'] ??
                                                        'Tempat belum ditentukan',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
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
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: fontSemiBold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
