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
import 'package:rsia_employee_app/components/cards/card_health_widget.dart';

class _MenuCategory {
  final String title;
  final IconData icon;
  final Color themeColor;
  final List<String> keywords;
  final List<Map> items;

  _MenuCategory({
    required this.title,
    required this.icon,
    required this.themeColor,
    required this.keywords,
    List<Map>? items,
  }) : items = items ?? [];
}

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
  List<String> _favoriteKeys = [];
  Timer? _timer;
  DateTime _now = DateTime.now();

  // ── Mood ────────────────────────────────────────────────────────────────
  bool _moodDone = false;
  String? _todayMood;  // 'berat' | 'kurang_oke' | 'baik' | 'luar_biasa'
  final List<Map<String, dynamic>> _moodOptions = [
    {'label': 'Berat',     'emoji': '😔', 'value': 'berat',      'color': const Color(0xFFEF4444)},
    {'label': 'Kurang oke','emoji': '😐', 'value': 'kurang_oke', 'color': const Color(0xFFEAB308)},
    {'label': 'Baik',      'emoji': '😊', 'value': 'baik',       'color': const Color(0xFF0EA5E9)},
    {'label': 'Luar biasa!','emoji': '🤩','value': 'luar_biasa', 'color': const Color(0xFF10B981)},
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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
            _loadFavorites();
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
        offset: const Offset(0, -35), // Overlap upwards into header
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: primaryColor.withOpacity(0.08), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Baris 1: Presensi (Horizontal) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sisi Kiri: Icon + Shift & Jam
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.calendar_today_rounded,
                              color: primaryColor, size: 13),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _jadwal['shift']?.toString() ?? "Libur / Kosong",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_jadwal['shift'] != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${(_jadwal['jam_masuk']?.toString() ?? '00:00').split(':').take(2).join(':')} - ${(_jadwal['jam_pulang']?.toString() ?? '00:00').split(':').take(2).join(':')}",
                                    style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 9.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sisi Kanan: Check In & Check Out
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Masuk
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.login_rounded,
                                size: 12, color: Colors.green),
                          ),
                          const SizedBox(width: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Masuk",
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[500])),
                              Text(
                                _getTimeString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.grey[200],
                      ),
                      // Pulang
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.logout_rounded,
                                size: 12, color: Colors.orange),
                          ),
                          const SizedBox(width: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Pulang",
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[500])),
                              Text(
                                _rekapPresensi['jam_pulang'] ?? "--:--",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // ── Pembatas Halus ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Colors.grey[100],
                ),
              ),

              // ── Baris 2: Kebugaran (Horizontal) ──
              const CardHealthWidget(embedded: true),
            ],
          ),
        ),
      ),
    );
  }

  static const List<Color> _paletteColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFFEA580C), // Orange
    Color(0xFF7C3AED), // Purple
    Color(0xFF0D9488), // Teal
    Color(0xFFE11D48), // Rose
    Color(0xFF4F46E5), // Indigo
    Color(0xFFD97706), // Amber
    Color(0xFF0891B2), // Cyan
    Color(0xFF16A34A), // Green
    Color(0xFFDC2626), // Red
    Color(0xFF0284C7), // Sky
    Color(0xFF9333EA), // Violet
    Color(0xFF64748B), // Slate
  ];

  Color _getMenuItemColor(Map item) {
    final name = (item['nama_menu'] ?? '').toString();
    return _paletteColors[name.hashCode.abs() % _paletteColors.length];
  }

  String _getMenuIdentifier(Map item) {
    if (item['id_menu'] != null) return item['id_menu'].toString();
    if (item['route'] != null && item['route'].toString().trim().isNotEmpty) {
      return item['route'].toString().trim();
    }
    return (item['nama_menu'] ?? '').toString().trim();
  }

  List<Map> _getAllMenusWithFallback() {
    final list = <Map>[];
    for (var m in _menus) {
      if (m is Map) list.add(Map<String, dynamic>.from(m));
    }
    return list;
  }

  void _loadFavorites() {
    final stored = box.read('favorite_menus');
    if (stored != null && stored is List && stored.isNotEmpty) {
      _favoriteKeys = List<String>.from(stored.map((e) => e.toString()));
    } else {
      // Default: 4 daily routine keywords if available
      final defaultKeywords = ['presensi', 'jadwal', 'cuti', 'lembur'];
      List<String> defaults = [];
      final allAvailable = _getAllMenusWithFallback();
      for (var kw in defaultKeywords) {
        for (var raw in allAvailable) {
          String name = (raw['nama_menu'] ?? '').toString().toLowerCase();
          String route = (raw['route'] ?? '').toString().toLowerCase();
          if (name.contains(kw) || route.contains(kw)) {
            String key = _getMenuIdentifier(raw);
            if (!defaults.contains(key)) {
              defaults.add(key);
              break;
            }
          }
        }
      }
      if (defaults.isEmpty && allAvailable.isNotEmpty) {
        defaults = allAvailable.take(4).map((m) => _getMenuIdentifier(m)).toList();
      }
      _favoriteKeys = defaults;
    }
  }

  List<Map> _getFavoriteMenuItems() {
    List<Map> favs = [];
    final allAvailable = _getAllMenusWithFallback();
    for (var key in _favoriteKeys) {
      for (var m in allAvailable) {
        if (_getMenuIdentifier(m) == key) {
          favs.add(m);
          break;
        }
      }
    }
    return favs;
  }

  List<_MenuCategory> _getCategorizedMenus() {
    final categories = [
      _MenuCategory(
        title: "Kepegawaian & Rutinitas",
        icon: Icons.badge_rounded,
        themeColor: const Color(0xFF0284C7),
        keywords: ['presensi', 'jadwal', 'cuti', 'lembur', 'tukar', 'kebugaran', 'wellness', 'shift', 'jaspel'],
      ),
      _MenuCategory(
        title: "Dokumen & Berkas",
        icon: Icons.folder_shared_rounded,
        themeColor: const Color(0xFFEA580C),
        keywords: ['berkas', 'dokumen', 'surat', 'undangan', 'e-book', 'ebook', 'jurnal', 'file'],
      ),
      _MenuCategory(
        title: "Mutu & Pengembangan",
        icon: Icons.verified_user_rounded,
        themeColor: const Color(0xFF7C3AED),
        keywords: ['ikp', 'akreditasi', 'sertifikasi', 'e-learning', 'pelatihan', 'diklat', 'mutu'],
      ),
      _MenuCategory(
        title: "Layanan & Fasilitas",
        icon: Icons.local_hospital_rounded,
        themeColor: const Color(0xFF0D9488),
        keywords: ['dashboard', 'kamar', 'helpdesk', 'pasien', 'bed', 'penyakit', 'inventaris', 'perbaikan', 'service', 'kantin', 'makan'],
      ),
      _MenuCategory(
        title: "Ruang Rehat & Mini Games",
        icon: Icons.sports_esports_rounded,
        themeColor: const Color(0xFF00A896),
        keywords: ['emergency_rush', 'ambulans', 'tts', 'game', 'arcade', 'rehat', 'hiburan', 'gesit', 'virus_buster', 'super_doctor', 'dokter', 'virus'],
      ),
    ];

    final allAvailable = _getAllMenusWithFallback();
    final kepegawaian = categories[0];
    final dokumen = categories[1];
    final mutu = categories[2];
    final layanan = categories[3];
    final miniGames = categories[4];

    for (var item in allAvailable) {
      final name = (item['nama_menu'] ?? '').toString().toLowerCase();
      final route = (item['route'] ?? '').toString().toLowerCase();

      if (miniGames.keywords.any((kw) => name.contains(kw) || route.contains(kw))) {
        miniGames.items.add(item);
      } else if (kepegawaian.keywords.any((kw) => name.contains(kw) || route.contains(kw))) {
        kepegawaian.items.add(item);
      } else if (dokumen.keywords.any((kw) => name.contains(kw) || route.contains(kw))) {
        dokumen.items.add(item);
      } else if (mutu.keywords.any((kw) => name.contains(kw) || route.contains(kw))) {
        mutu.items.add(item);
      } else {
        layanan.items.add(item);
      }
    }

    return categories.where((cat) => cat.items.isNotEmpty).toList();
  }

  void _onMenuTap(Map item, Color themeColor) {
    bool isDisabled = item['disabled'] == true;
    bool hasChildren = item['children'] != null && (item['children'] as List).isNotEmpty;

    if (isDisabled) {
      Msg.warning(context, featureNotAvailableMsg);
    } else if (hasChildren) {
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
  }

  Widget _buildMenuItem(Map item, Color themeColor) {
    bool isDisabled = item['disabled'] == true;
    bool hasChildren = item['children'] != null && (item['children'] as List).isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onMenuTap(item, themeColor),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Icon Squircle Box
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.grey[100]
                          : themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: IconMapper.buildIcon(
                        item['icon']?.toString() ?? "",
                        routeKey: item['route']?.toString(),
                        size: 25,
                        color: isDisabled ? Colors.grey[400] : themeColor,
                      ),
                    ),
                  ),
                  // Submenu Indicator Badge (Mini Chevron)
                  if (hasChildren && !isDisabled)
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Menu Title Label
              Text(
                item['nama_menu'].toString(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? Colors.grey[400] : const Color(0xFF1E293B),
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGridSection(List<Map> items) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.88,
        mainAxisSpacing: 10,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final themeColor = _getMenuItemColor(item);
        return _buildMenuItem(item, themeColor);
      },
    );
  }

  Widget _buildFavoritesCard() {
    final favItems = _getFavoriteMenuItems();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Menu Favorit",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        "Pintasan menu cepat harian",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showEditFavoritesSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 13,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Atur",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (favItems.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey[400]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Belum ada menu favorit. Ketuk 'Atur' untuk memilih menu cepat.",
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildMenuGridSection(favItems),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_MenuCategory cat) {
    if (cat.items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cat.themeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    cat.icon,
                    color: cat.themeColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${cat.items.length} Menu",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildMenuGridSection(cat.items),
        ],
      ),
    );
  }

  void _showEditFavoritesSheet() {
    List<String> tempSelected = List<String>.from(_favoriteKeys);
    final categorized = _getCategorizedMenus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header with counter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Atur Menu Favorit",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Pilih menu pintasan cepat (maksimal 8 menu)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: tempSelected.length >= 8
                                ? const Color(0xFFEA580C).withOpacity(0.12)
                                : primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${tempSelected.length}/8 Dipilih",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: tempSelected.length >= 8
                                  ? const Color(0xFFEA580C)
                                  : primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 0.8),

                  // Categorized Menu Selection List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: categorized.length,
                      itemBuilder: (context, catIndex) {
                        final cat = categorized[catIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                              child: Row(
                                children: [
                                  Icon(cat.icon, size: 15, color: cat.themeColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.title,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: cat.themeColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...cat.items.map((item) {
                              final key = _getMenuIdentifier(item);
                              final isSelected = tempSelected.contains(key);
                              final itemColor = _getMenuItemColor(item);
                              final isDisabled = item['disabled'] == true;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withOpacity(0.04)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.35)
                                        : Colors.grey.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDisabled
                                          ? Colors.grey[100]
                                          : itemColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: IconMapper.buildIcon(
                                        item['icon']?.toString() ?? "",
                                        routeKey: item['route']?.toString(),
                                        size: 20,
                                        color: isDisabled ? Colors.grey[400] : itemColor,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item['nama_menu']?.toString() ?? "-",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  subtitle: item['children'] != null && (item['children'] as List).isNotEmpty
                                      ? Text(
                                          "${(item['children'] as List).length} Submenu",
                                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                        )
                                      : null,
                                  trailing: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? primaryColor : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? primaryColor : Colors.grey[300]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                                        : null,
                                  ),
                                  onTap: () {
                                    setSheetState(() {
                                      if (isSelected) {
                                        tempSelected.remove(key);
                                      } else {
                                        if (tempSelected.length < 8) {
                                          tempSelected.add(key);
                                        } else {
                                          Msg.warning(context, "Maksimal 8 menu favorit");
                                        }
                                      }
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),

                  // Bottom Action Button
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(context).padding.bottom + 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          box.write('favorite_menus', tempSelected);
                          setState(() {
                            _favoriteKeys = List<String>.from(tempSelected);
                          });
                          Navigator.pop(sheetContext);
                          Msg.success(context, "Menu favorit berhasil disimpan");
                        },
                        child: const Text(
                          "Simpan Favorit",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SkeletonHome();
    }

    final categorized = _getCategorizedMenus();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopSection(),
          _buildAttendanceStatus(),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: RefreshIndicator(
                onRefresh: _initialize,
                color: primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFavoritesCard(),
                      ...categorized.map((cat) => _buildCategoryCard(cat)),
                    ],
                  ),
                ),
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
                    child: IconMapper.buildIcon(
                      parent['icon']?.toString() ?? "",
                      routeKey: parent['route']?.toString(),
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
                          child: IconMapper.buildIcon(
                            sub['icon']?.toString() ?? "",
                            routeKey: sub['route']?.toString(),
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
