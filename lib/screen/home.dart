import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_home.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/utils/icon_mapper.dart';
import 'package:rsia_employee_app/utils/menu_navigator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = GetStorage();

  bool isLoading = true; // Set to true by default to avoid flickering
  int selectedTab = 0;
  String nik = "";
  Map _bio = {};
  Map _jadwal = {};
  Map _tempPresensi = {};
  Map _rekapPresensi = {};
  List _menus = [];

  @override
  void initState() {
    super.initState();
    if (mounted) {
      fetchAllData().then((value) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });
    }
  }

  Future<void> fetchAllData() async {
    List<Future> futures = [
      _getBio(),
      _getJadwal(),
      _getTempPresensi(),
      _getRekapPresensi(),
      _getMenus(),
    ];

    await Future.wait(futures);
  }

  Future<void> _getBio() async {
    var res = await Api().getData("/pegawai/${box.read('sub')}");
    var body = json.decode(res.body);

    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          _bio = body['data'];
        });
      }
    }
  }

  Future<void> _getJadwal() async {
    var res = await Api().getData("/pegawai/${box.read('sub')}/jadwal");
    var body = json.decode(res.body);
    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          if (body['data'] is List) {
            _jadwal = body['data'].isNotEmpty
                ? body['data'][0]['jam_masuk'] ?? {}
                : {};
          } else {
            _jadwal = body['data']['jam_masuk'] ?? {};
          }
        });
      }
    }
  }

  Future<void> _getTempPresensi() async {
    var res =
        await Api().getData("/pegawai/${box.read('sub')}/presensi/temporary");
    var body = json.decode(res.body);
    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          if (body['data'] is List) {
            _tempPresensi = body['data'].isNotEmpty ? body['data'][0] : {};
          } else {
            _tempPresensi = body['data'] ?? {};
          }
        });
      }
    }
  }

  Future<void> _getRekapPresensi() async {
    var res = await Api().postData({
      "scopes": [
        {
          "name": "withId",
          "parameters": ["${box.read('sub')}"]
        },
        {
          "name": "withDatang",
          "parameters": [DateFormat('yyyy-MM-dd').format(DateTime.now())]
        }
      ],
      "sort": [
        {"field": "jam_datang", "direction": "desc"}
      ]
    }, "/pegawai/${box.read('sub')}/presensi/search");
    var body = json.decode(res.body);
    if (res.statusCode == 200) {
      if (body['data'].length > 0) {
        if (mounted) {
          setState(() {
            _rekapPresensi = body['data'][0];
          });
        }
      }
    }
  }

  Future<void> _getMenus() async {
    var res =
        await Api().getData("/menu-management/user-menus?platform=mobile");
    var body = json.decode(res.body);
    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          _menus = body['data'] ?? [];
        });
      }
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getTimeString() {
    try {
      if (_rekapPresensi.isEmpty && _tempPresensi.isEmpty) {
        return "--:--";
      }

      String? rawDate = _rekapPresensi.isEmpty
          ? _tempPresensi['jam_datang']
          : _rekapPresensi['jam_datang'];

      if (rawDate == null) return "--:--";

      return DateFormat('HH:mm').format(DateTime.parse(rawDate));
    } catch (e) {
      return "--:--";
    }
  }

  Widget _buildTopSection() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 15,
        left: 20,
        right: 20,
        bottom: 60, // Deeper padding for deeper curve
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withBlue(210).withGreen(180), // Slightly deeper cyan
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(60), // Deeper curvature for premium look
          bottomRight: Radius.circular(60),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bio['nama']?.toString() ?? "Pegawai",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width *
                        0.05, // Adaptive scaling
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _bio['nik']?.toString() ?? "-",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                image: _bio['photo'] != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                            photoUrl + _bio['photo'].toString()),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter, // Focus on head/hair
                      )
                    : null,
              ),
              child: _bio['photo'] == null
                  ? const Icon(Icons.person, color: Colors.white, size: 35)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Transform.translate(
        offset: const Offset(0, -25), // Perfect floating overlap
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_today_rounded,
                            color: primaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Jadwal Hari Ini",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500)),
                          Text(
                            _jadwal['shift']?.toString() ?? "Libur / Kosong",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_jadwal['shift'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        "${(_jadwal['jam_masuk']?.toString() ?? '00:00').split(':').take(2).join(':')} - ${(_jadwal['jam_pulang']?.toString() ?? '00:00').split(':').take(2).join(':')}",
                        style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeDetail(
                      label: "Check In",
                      time: _getTimeString(),
                      icon: Icons.login_rounded,
                      color: Colors.green,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    color: Colors.grey[100],
                  ),
                  Expanded(
                    child: _buildTimeDetail(
                      label: "Check Out",
                      time: _rekapPresensi.isEmpty ||
                              _rekapPresensi['jam_pulang'] == null
                          ? "--:--"
                          : DateFormat('HH:mm').format(
                              DateTime.parse(_rekapPresensi['jam_pulang'])),
                      icon: Icons.logout_rounded,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDetail(
      {required String label,
      required String time,
      required IconData icon,
      required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            Text(time,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
          child: Text(
            "Layanan Kepegawaian",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            itemCount: _menus.length,
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 100,
              top: 5,
            ),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
            ),
            itemBuilder: (context, index) {
              var item = _menus[index];
              bool isDisabled = item['disabled'] == true;

              // Modern predefined colors for icons
              final colors = [
                Colors.blue,
                Colors.orange,
                Colors.purple,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
                Colors.amber,
                Colors.cyan,
                Colors.lightGreen,
                Colors.deepOrange,
                Colors.blueGrey,
                Colors.redAccent,
                Colors.deepPurple,
              ];
              final themeColor = colors[index % colors.length];

              return InkWell(
                onTap: () {
                  if (isDisabled) {
                    Msg.warning(context, featureNotAvailableMsg);
                  } else if (item['children'] != null &&
                      (item['children'] as List).isNotEmpty) {
                    _showSubMenuSheet(item, themeColor);
                  } else {
                    // Dynamic navigation for API menus
                    String routeKey = item['route']?.toString() ?? "";
                    Widget? target = MenuNavigator.getWidget(routeKey);

                    if (target != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => target),
                      );
                    } else {
                      Msg.warning(context, featureNotAvailableMsg);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? Colors.grey[100]
                              : themeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconMapper.getIcon(item['icon']?.toString() ?? ""),
                          size: 28,
                          color: isDisabled ? Colors.grey : themeColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['nama_menu'].toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDisabled ? Colors.grey : Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SkeletonHome();
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[50], // Modern clean background
      body: Column(
        children: [
          _buildTopSection(),
          Expanded(
            child: SingleChildScrollView(
              clipBehavior: Clip
                  .none, // Allow items to overlap header without being clipped
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildAttendanceStatus(),
                  const SizedBox(height: 0),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildMenuGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubMenuSheet(Map parent, Color themeColor) {
    List children = parent['children'] ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconMapper.getIcon(parent['icon']?.toString() ?? ""),
                      color: themeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    parent['nama_menu'].toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: children.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                ),
                itemBuilder: (context, index) {
                  var sub = children[index];
                  bool isSubDisabled = sub['disabled'] == true;

                  return InkWell(
                    onTap: () {
                      if (isSubDisabled) {
                        Msg.warning(context, featureNotAvailableMsg);
                      } else {
                        String routeKey = sub['route']?.toString() ?? "";
                        Widget? target = MenuNavigator.getWidget(routeKey);

                        if (target != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => target),
                          );
                        } else {
                          Msg.warning(context, featureNotAvailableMsg);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSubDisabled
                                ? Colors.grey[100]
                                : themeColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconMapper.getIcon(sub['icon']?.toString() ?? ""),
                            size: 24,
                            color: isSubDisabled ? Colors.grey : themeColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          sub['nama_menu'].toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSubDisabled ? Colors.grey : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }
}
