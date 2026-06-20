import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rsia_employee_app/components/skeletons/skeleton_home.dart';
import 'package:rsia_employee_app/utils/icon_mapper.dart';
import 'package:rsia_employee_app/utils/menu_navigator.dart';
import 'package:rsia_employee_app/screen/menu/mood_checkin.dart';

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
  Map _rekapPresensi = {};
  List _menus = [];
  Timer? _timer;
  DateTime _now = DateTime.now();

  // ── Mood ────────────────────────────────────────────────────────────────
  bool _moodDone = false;
  String? _todayMood;  // 'berat' | 'kurang_oke' | 'baik' | 'luar_biasa'
  int _moodStreak = 0;
  final List<Map<String, dynamic>> _moodOptions = [
    {'label': 'Berat',     'emoji': '😔', 'value': 'berat',      'color': const Color(0xFFEF4444)},
    {'label': 'Kurang oke','emoji': '😐', 'value': 'kurang_oke', 'color': const Color(0xFFEAB308)},
    {'label': 'Baik',      'emoji': '😊', 'value': 'baik',       'color': const Color(0xFF0EA5E9)},
    {'label': 'Luar biasa!','emoji': '🤩','value': 'luar_biasa', 'color': const Color(0xFF10B981)},
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    await _getBio();
    await _getJadwal();
    await _getPresensiStatus();
    await _getMenus();
    await _getMoodStatus();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getBio() async {
    try {
      var res = await Api().getData("/pegawai/${box.read('sub')}");
      var body = json.decode(res.body);

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _bio = body['data'];
          });
        }
      }
    } catch (e) {
      print("DEBUG BIO: Error fetching bio: $e");
    }
  }

  Future<void> _getJadwal() async {
    try {
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
    } catch (e) {
      print("DEBUG JADWAL: Error fetching jadwal: $e");
    }
  }

  Future<void> _getPresensiStatus() async {
    String endpoint = "/presensi-online/status";

    if (_bio.isNotEmpty && _bio['nik'] != null) {
      endpoint += "?nik=${_bio['nik']}";
    }

    try {
      var res = await Api().getData(endpoint);

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (mounted) {
          setState(() {
            var data = body['data'];
            _rekapPresensi = data is Map ? data : {};
          });
        }
      }
    } catch (e) {
      print("DEBUG PRESENSI: Error fetching status: $e");
    }
  }

  Future<void> _getMenus() async {
    try {
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
    } catch (e) {
      print("DEBUG MENUS: Error fetching menus: $e");
    }
  }

  Future<void> _getMoodStatus() async {
    try {
      final nik = box.read('sub');
      final res = await Api().getData('/sdi/mood/today?nik=$nik');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (mounted) {
          setState(() {
            _moodDone   = body['already_done'] == true;
            _moodStreak = body['streak'] ?? 0;
            _todayMood  = body['data']?['mood'];
          });
        }
      }
    } catch (_) {}
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getTimeString() {
    if (_rekapPresensi.isEmpty) return "--:--";
    return _rekapPresensi['jam_masuk']?.toString() ?? "--:--";
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
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat("EEEE, d MMM yyyy • HH:mm", "id_ID")
                            .format(_now),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8), // Reduced from 12
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 4
                Text(
                  _bio['nama']?.toString() ?? "Pegawai",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width *
                        0.045, // Slightly smaller
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1, // Restrict to 1 line for space
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Reduced from 4
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _bio['nik']?.toString() ?? "-",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    image: _bio['photo'] != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                                photoUrl + _bio['photo'].toString()),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          )
                        : null,
                  ),
                  child: _bio['photo'] == null
                      ? const Icon(Icons.person, color: Colors.white, size: 35)
                      : null,
                ),
              ),
              Positioned(
                top: -2,
                right: -2, // Intersects the circular border at the top-right
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodCheckinScreen()),
                    );
                    _getMoodStatus();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _moodDone && _todayMood != null
                          ? _moodOptions.firstWhere(
                              (o) => o['value'] == _todayMood,
                              orElse: () => {'emoji': '😶'},
                            )['emoji']
                          : '😶', // Blank emoticon placeholder
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Transform.translate(
        offset: const Offset(0, -35), // Increased overlap upwards
        child: Container(
          padding: const EdgeInsets.all(16), // Reduced from 20
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // Reduced from 25
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
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
                        padding: const EdgeInsets.all(8), // Reduced from 10
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_today_rounded,
                            color: primaryColor, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Jadwal Hari Ini",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500)),
                          Text(
                            _jadwal['shift']?.toString() ?? "Libur / Kosong",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_jadwal['shift'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${(_jadwal['jam_masuk']?.toString() ?? '00:00').split(':').take(2).join(':')} - ${(_jadwal['jam_pulang']?.toString() ?? '00:00').split(':').take(2).join(':')}",
                        style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14), // Reduced from 20
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
                    height: 30, // Reduced from 40
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.grey[100],
                  ),
                  Expanded(
                    child: _buildTimeDetail(
                      label: "Check Out",
                      time: _rekapPresensi['jam_pulang'] ?? "--:--",
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
    final colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.teal,
      Colors.pink, Colors.indigo, Colors.amber, Colors.cyan,
      Colors.lightGreen, Colors.deepOrange, Colors.blueGrey,
      Colors.redAccent, Colors.deepPurple,
    ];

    return GridView.builder(
      itemCount: _menus.length,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 100,
        top: 5,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        var item = _menus[index];
        bool isDisabled = item['disabled'] == true;
        final themeColor = colors[index % colors.length];

        return InkWell(
          onTap: () {
            if (isDisabled) {
              Msg.warning(context, featureNotAvailableMsg);
            } else if (item['children'] != null &&
                (item['children'] as List).isNotEmpty) {
              _showSubMenuSheet(item, themeColor);
            } else {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SkeletonHome();
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopSection(),
          _buildAttendanceStatus(),
          Transform.translate(
            offset: const Offset(0, -10), // Shift title up slightly (adds spacing from top card)
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 5),
              child: Text(
                "Layanan Kepegawaian",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -10), // Shift grid up slightly (matches title offset)
              child: RefreshIndicator(
                onRefresh: _initialize,
                color: primaryColor,
                child: _buildMenuGrid(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mood Banner ─────────────────────────────────────────────────────────
  Widget _buildMoodBanner() {
    // Already done today → show summary chip
    if (_moodDone && _todayMood != null) {
      final opt = _moodOptions.firstWhere(
        (o) => o['value'] == _todayMood,
        orElse: () => _moodOptions[2],
      );
      return GestureDetector(
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MoodCheckinScreen()));
          _getMoodStatus();
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (opt['color'] as Color).withOpacity(0.85),
                (opt['color'] as Color).withOpacity(0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (opt['color'] as Color).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(opt['emoji'] as String,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mood hari ini: ${opt['label']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        )),
                    if (_moodStreak > 1)
                      Text('🔥 Streak $_moodStreak hari berturut-turut!',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white70, size: 22),
            ],
          ),
        ),
      );
    }

    // Not done yet → show compact horizontal emoji picker
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF3BC8ED).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bagaimana perasaanmu hari ini?',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _moodOptions.map((opt) {
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MoodCheckinScreen()),
                  );
                  _getMoodStatus();
                },
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (opt['color'] as Color).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Text(opt['emoji'] as String,
                      style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
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
