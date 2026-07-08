import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:rsia_employee_app/api/request.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:rsia_employee_app/api/firebase_api.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:rsia_employee_app/screen/menu/cuti.dart';
import 'package:rsia_employee_app/screen/menu/e_presensi.dart';
import 'package:rsia_employee_app/screen/menu/helpdesk_form.dart';
import 'package:rsia_employee_app/screen/menu/lembur.dart';
import 'package:rsia_employee_app/screen/menu/pengajuan_jadwal.dart';
import 'package:rsia_employee_app/screen/menu/surat_eksternal/surat_eksternal_add_screen.dart';
import 'package:rsia_employee_app/screen/menu/surat_internal/surat_internal_add_screen.dart';
import 'package:rsia_employee_app/screen/menu/presensi_dokter.dart';
import 'package:rsia_employee_app/screen/menu/lapor_ikp_form.dart';
import 'package:animations/animations.dart';

import '../config/config.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen>
    with SingleTickerProviderStateMixin {
  final box = GetStorage();

  int _selectedNavbar = 0;

  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isMenuOpen = false;
  List<dynamic> _userMenus = [];
  bool _isMenuLoading = true;
  Map<String, dynamic>? _selectedSubMenu;

  @override
  void initState() {
    super.initState();
    _getBioAndSubscribeIT();
    _initializeFirebase();
    _checkForUpdate();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _fetchUserMenus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _selectedSubMenu = null;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToFirebaseMessages();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      await FirebaseApi().initNotif(context);
      final List<String> topics = ['sub', 'role', 'dep', 'jbtn'];
      for (var topic in topics) {
        var val = box.read(topic);
        if (val != null) {
          try {
            await FirebaseMessaging.instance.subscribeToTopic(val.toString());
          } catch (e) {
            print('⚠️ Error subscribing to topic $topic: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
    }
  }

  Future<void> _getBioAndSubscribeIT() async {
    final sub = box.read('sub');
    if (sub == null) return;

    try {
      // Fetch latest profile including department relationship (dep) from API
      var res = await Api().getData("/pegawai/$sub?include=dep");
      var body = json.decode(res.body);

      if (res.statusCode == 200 && body['data'] != null) {
        // Handle both Map and single-item List responses
        var userData = body['data'];
        if (userData is List && userData.isNotEmpty) {
          userData = userData[0];
        }

        if (userData is Map) {
          // Use 'dep' relationship object instead of 'departemen' string field
          var depObj = userData['dep'];
          String deptName =
              (depObj != null ? depObj['nama'] : "").toString().toUpperCase();
          String deptCode =
              (depObj != null ? depObj['dep_id'] : "").toString().toUpperCase();

          if (deptCode.isNotEmpty && deptCode != '-') {
            box.write('dep', deptCode);
          }
          String jabatan = (userData['jbtn'] ?? "").toString().toUpperCase();
          String role =
              (box.read('role') ?? "").toString().trim().toUpperCase();

          print(
              'Checking IT Subscription from API - Dept: $deptName ($deptCode), Jbtn: $jabatan');

          bool isUserIT = deptName.contains('TEKNOLOGI') ||
              deptName.contains('SISTEM') ||
              deptCode == 'IT' ||
              deptCode == 'SIT' ||
              role == 'IT' ||
              jabatan.contains('SI DAN TI') ||
              jabatan.contains('TEKNOLOGI');

          if (isUserIT) {
            try {
              await FirebaseMessaging.instance.subscribeToTopic('it');
              print('✅ Successfully Subscribed to IT topic from API data');
            } catch (fbErr) {
              print('⚠️ Could not subscribe to IT topic: $fbErr');
            }
          } else {
            print('ℹ️ Not an IT user (via API), skipping IT topic');
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching bio for IT subscription: $e');
    }
  }

  Future<void> _checkForUpdate() async {
    if (kDebugMode) {
      return;
    }

    final updateInfo = await InAppUpdate.checkForUpdate();
    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      if (updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (updateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate().then((result) {
          if (result == AppUpdateResult.success) {
            InAppUpdate.completeFlexibleUpdate();
          }
        });
      }
    }
  }

  Future<void> _fetchUserMenus() async {
    try {
      var res =
          await Api().getData("/menu-management/user-menus?platform=mobile");
      var body = json.decode(res.body);
      if (res.statusCode == 200) {
        if (mounted) {
          List<dynamic> rawMenus = body['data'] ?? [];
          setState(() {
            _userMenus = _flattenMenus(rawMenus);
            _isMenuLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isMenuLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMenuLoading = false;
        });
      }
    }
  }

  List<dynamic> _flattenMenus(List<dynamic> menus) {
    List<dynamic> flat = [];
    for (var menu in menus) {
      flat.add(menu);
      if (menu['children'] != null && (menu['children'] as List).isNotEmpty) {
        flat.addAll(_flattenMenus(menu['children']));
      }
    }
    return flat;
  }

  bool _hasAccess(String routeKey) {
    return _userMenus.any((menu) => menu['route'] == routeKey);
  }

  void _listenToFirebaseMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  void _changeSelectedNavbar(int index) {
    setState(() {
      _selectedNavbar = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop && _selectedNavbar != 0) {
          setState(() {
            _selectedNavbar = 0;
          });
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          extendBody: true,
          floatingActionButton: _buildMainFab(),
          body: Stack(
            children: [
              PageTransitionSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder:
                    (child, primaryAnimation, secondaryAnimation) {
                  return FadeThroughTransition(
                    animation: primaryAnimation,
                    secondaryAnimation: secondaryAnimation,
                    fillColor: Colors.transparent,
                    child: child,
                  );
                },
                child: Padding(
                  key: ValueKey<int>(_selectedNavbar),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: navigationItems[_selectedNavbar]['widget'] as Widget,
                ),
              ),

              // Dimmed Overlay
              if (_isMenuOpen)
                GestureDetector(
                  onTap: _toggleMenu,
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),

              // Sub Menu Items (Radial Layout around FAB)
              if (_isMenuOpen || _animationController.isAnimating)
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      // Collect visible menu items based on access
                      final List<Map<String, dynamic>> visibleItems = [];

                      bool accPresensi = _hasAccess('menu_presensi_online') || _hasAccess('e_presensi') || _hasAccess('presensi_online');
                      visibleItems.add({
                        'icon': Icons.location_on,
                        'label': 'Presensi',
                        'color': accPresensi ? const Color(0xFFFBC02D) : Colors.grey[400]!,
                        'disabled': !accPresensi,
                        'onTap': () {
                          _toggleMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const EPresensiScreen(title: "Presensi Online")));
                        },
                      });

                      bool accDokter = _hasAccess('menu_presensi_dokter') || accPresensi;
                      visibleItems.add({
                        'icon': Icons.medical_services_rounded,
                        'label': 'Presensi Dokter',
                        'color': accDokter ? Colors.redAccent : Colors.grey[400]!,
                        'disabled': !accDokter,
                        'onTap': () {
                          _toggleMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PresensiDokter()));
                        },
                      });

                      bool accLembur = _hasAccess('menu_lembur');
                      visibleItems.add({
                        'icon': Icons.more_time_rounded,
                        'label': 'Lembur',
                        'color': accLembur ? Colors.cyan : Colors.grey[400]!,
                        'disabled': !accLembur,
                        'onTap': () {
                          _toggleMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LemburScreen(title: "Lembur")));
                        },
                      });

                      bool accCuti = _hasAccess('menu_cuti') || _hasAccess('cuti');
                      visibleItems.add({
                        'icon': Icons.calendar_month,
                        'label': 'Cuti',
                        'color': accCuti ? Colors.blue : Colors.grey[400]!,
                        'disabled': !accCuti,
                        'onTap': () {
                          _toggleMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const Cuti(showForm: true)));
                        },
                      });

                      bool accJadwal = _hasAccess('menu_pengajuan_jadwal');
                      visibleItems.add({
                        'icon': Icons.event_note_rounded,
                        'label': 'Jadwal',
                        'color': accJadwal ? Colors.orange : Colors.grey[400]!,
                        'disabled': !accJadwal,
                        'onTap': () {
                          _toggleMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PengajuanJadwal()));
                        },
                      });

                      bool accSuratInternal = _hasAccess('menu_surat_internal');
                      visibleItems.add({
                        'icon': Icons.domain_rounded,
                        'label': 'S. Internal',
                        'color': accSuratInternal ? Colors.teal : Colors.grey[400]!,
                        'disabled': !accSuratInternal,
                        'onTap': () {
                          _toggleMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SuratInternalAddScreen()));
                        },
                      });

                      bool accSuratEksternal = _hasAccess('menu_surat_eksternal');
                      visibleItems.add({
                        'icon': Icons.public_rounded,
                        'label': 'S. Eksternal',
                        'color': accSuratEksternal ? Colors.indigo : Colors.grey[400]!,
                        'disabled': !accSuratEksternal,
                        'onTap': () {
                          _toggleMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SuratEksternalAddScreen()));
                        },
                      });

                      bool accHelpdesk = _hasAccess('menu_helpdesk');
                      visibleItems.add({
                        'icon': Icons.support_agent,
                        'label': 'Helpdesk',
                        'color': accHelpdesk ? Colors.redAccent : Colors.grey[400]!,
                        'disabled': !accHelpdesk,
                        'onTap': () {
                          _toggleMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpdeskFormScreen()));
                        },
                      });

                      bool accIkp = _hasAccess('lapor-ikp') || _hasAccess('menu_lapor_ikp') || _hasAccess('lapor_ikp');
                      visibleItems.add({
                        'icon': Icons.warning_amber_rounded,
                        'label': 'Lapor IKP',
                        'color': accIkp ? Colors.orange[800]! : Colors.grey[400]!,
                        'disabled': !accIkp,
                        'onTap': () {
                          _toggleMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LaporIkpFormScreen()));
                        },
                      });

                      // Calculate dynamic angles based on item count
                      final int count = visibleItems.length;
                      if (count == 0) return const SizedBox.shrink();

                      // For 1 item: center at 90°
                      // For 2+ items: evenly spread from 180° to 0°
                      final double startAngle = count == 1 ? 90.0 : 180.0;
                      final double endAngle = count == 1 ? 90.0 : 0.0;
                      final double step = count <= 1
                          ? 0.0
                          : (startAngle - endAngle) / (count - 1);

                      return Stack(
                        children: List.generate(count, (i) {
                          final item = visibleItems[i];
                          final double angle = startAngle - (step * i);
                          final isSelected = _selectedSubMenu != null && _selectedSubMenu!['label'] == item['label'];
                          return _buildRadialMenuItem(
                            icon: item['icon'] as IconData,
                            label: item['label'] as String,
                            color: item['color'] as Color,
                            angle: angle,
                            isSelected: isSelected,
                            onTap: () {
                              if (item['disabled'] == true) {
                                Msg.warning(context, featureNotAvailableMsg);
                              } else {
                                setState(() {
                                  _selectedSubMenu = item;
                                });
                              }
                            },
                            index: i,
                          );
                        }),
                      );
                    },
                  ),
                ),

              // Floating Selected Menu Action Button
              if (_isMenuOpen)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: (Platform.isIOS ? 90.0 : 70.0) + 75.0), 
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      ),
                      child: _selectedSubMenu != null
                          ? GestureDetector(
                              key: ValueKey(_selectedSubMenu!['label']),
                              onTap: _selectedSubMenu!['onTap'] as VoidCallback,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_selectedSubMenu!['color'] as Color).withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: (_selectedSubMenu!['color'] as Color).withOpacity(0.7),
                                    width: 2.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _selectedSubMenu!['icon'] as IconData,
                                      color: _selectedSubMenu!['color'] as Color,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _selectedSubMenu!['label'] as String,
                                        style: TextStyle(
                                          color: _selectedSubMenu!['color'] as Color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: (_selectedSubMenu!['color'] as Color).withOpacity(0.6),
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );
  }

  Widget _buildMainFab() {
    return FloatingActionButton(
      heroTag: 'mn-fab',
      onPressed: _toggleMenu,
      backgroundColor: primaryColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      child: RotationTransition(
        turns: Tween(begin: 0.0, end: 0.125).animate(_expandAnimation),
        child: const Icon(
          Icons.add_circle,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRadialMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required double angle, // in degrees
    required VoidCallback onTap,
    required int index,
    required bool isSelected,
  }) {
    double radius = 115.0; // Clean circular radius
    double radians = angle * math.pi / 180.0;
    double appBarHeight = Platform.isIOS ? 90 : 70;
    double x = radius * math.cos(radians);
    double y = radius * math.sin(radians);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: Offset(x, -(y + appBarHeight + 30)),
        child: ScaleTransition(
          scale: _expandAnimation,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: AnimatedScale(
              scale: isSelected ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: FloatingActionButton.small(
                heroTag: 'sub-fab-$index',
                onPressed: onTap,
                backgroundColor: isSelected ? color : Colors.white,
                foregroundColor: isSelected ? Colors.white : color,
                elevation: isSelected ? 8 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: BorderSide(
                    color: isSelected ? Colors.white : color.withOpacity(0.5),
                    width: isSelected ? 2.0 : 3.0,
                  ),
                ),
                child: Icon(icon, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            offset: const Offset(0, -5),
            blurRadius: 20,
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: Platform.isIOS ? 90 : 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.home_filled, "Home", 0),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(Icons.person, "Profile", 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedNavbar == index;
    return InkWell(
      onTap: () => _changeSelectedNavbar(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey[400],
              size: 28,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
