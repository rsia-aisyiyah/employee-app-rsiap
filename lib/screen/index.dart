import 'dart:io';
import 'dart:convert';
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
import 'package:rsia_employee_app/screen/menu/cuti.dart';
import 'package:rsia_employee_app/screen/menu/presensi.dart';
import 'package:rsia_employee_app/screen/menu/helpdesk_form.dart';
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

  @override
  void initState() {
    super.initState();
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
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToFirebaseMessages();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    await FirebaseApi().initNotif(context);
    final List<String> topics = ['sub', 'role', 'dep', 'jbtn'];
    for (var topic in topics) {
      var val = box.read(topic);
      if (val != null) {
        await FirebaseMessaging.instance.subscribeToTopic(val.toString());
      }
    }

    // Explicitly fetch Bio to ensure we have the latest Dept/Jabatan for IT subscription
    await _getBioAndSubscribeIT();
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
            await FirebaseMessaging.instance.subscribeToTopic('it');
            print('✅ Successfully Subscribed to IT topic from API data');
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

              // Sub Menu Items (Floating above FAB)
              if (_isMenuOpen || _animationController.isAnimating)
                Positioned(
                  bottom: Platform.isIOS ? 100 : 80, // Moved closer to main FAB
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSubMenuItem(
                        icon: Icons.location_on,
                        label: "Presensi Online",
                        onTap: () {
                          _toggleMenu();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Presensi()));
                        },
                        index: 2,
                      ),
                      _buildSubMenuItem(
                        icon: Icons.calendar_month,
                        label: "Tambah Cuti",
                        onTap: () {
                          _toggleMenu();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const Cuti(showForm: true)));
                        },
                        index: 1,
                      ),
                      _buildSubMenuItem(
                        icon: Icons.support_agent,
                        label: "Lapor Helpdesk",
                        onTap: () {
                          _toggleMenu();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const HelpdeskFormScreen()));
                        },
                        index: 0,
                      ),
                      const SizedBox(height: 10), // Extra buffer from main FAB
                    ],
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

  Widget _buildSubMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: ScaleTransition(
        scale: _expandAnimation,
        child: FadeTransition(
          opacity: _expandAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Label (Offset to the left of the icon)
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(
                            right: 12), // Space between label and icon
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 60), // Increased Gap for FAB.small
                  const Expanded(child: SizedBox()),
                ],
              ),

              // Icon (Centered)
              FloatingActionButton.small(
                heroTag: 'sub-fab-$index',
                onPressed: onTap,
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(icon),
              ),
            ],
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
