import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rsia_employee_app/api/firebase_api.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/screen/menu/cuti.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  // String nik = "";
  int _selectedNavbar = 0;
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    firebaseInit();
    checkForUpdate();
    _initializeFirebase();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    checkForUpdate();
  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    await FirebaseApi().initNotif(context);
    final List<String> topics = ['sub', 'role', 'dep', 'jbtn'];
    for (var topic in topics) {
      await FirebaseMessaging.instance.subscribeToTopic(box.read(topic));
    }
  }

  Future<void> _checkForUpdate() async {
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  // In App Update
  Future<void> checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((updateInfo) {
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          // Perform immediate update
          InAppUpdate.performImmediateUpdate().then((appUpdateResult) {
            if (appUpdateResult == AppUpdateResult.success) {
              //App Update successful
            }
          });
        } else if (updateInfo.flexibleUpdateAllowed) {
          //Perform flexible update
          InAppUpdate.startFlexibleUpdate().then((appUpdateResult) {
            if (appUpdateResult == AppUpdateResult.success) {
              //App Update successful
              InAppUpdate.completeFlexibleUpdate();
            }
          });
        }
      }
    });
  }

  void firebaseInit() async {
    await Firebase.initializeApp();
    await FirebaseApi().initNotif(context);
    // await FirebaseMessaging.instance.subscribeToTopic('dokter');

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());

    var nik = decodeToken['sub'];
    var sps = decodeToken['kd_dep'];

    await FirebaseMessaging.instance.subscribeToTopic('pegawai');
    await FirebaseMessaging.instance.subscribeToTopic(nik.replaceAll('"', ''));
    await FirebaseMessaging.instance.subscribeToTopic(sps.replaceAll('"', ''));
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
        if (didPop) {
          if (_selectedNavbar != 0) {
            setState(() {
              _selectedNavbar = 0;
            });
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Cuti(),
              ),
            );
          },
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          child: Icon(
            Icons.add_circle,
            size: 36,
            color: Colors.white, 
          ),
        ),
        // backgroundColor: bgColor,
        body: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: navigationItems[_selectedNavbar]['widget'] as Widget,
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          child: BottomAppBar(
            clipBehavior: Clip.antiAlias,
            shape: CircularNotchedRectangle(),
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            height: MediaQuery.of(context).size.height * 0.09,
            child: BottomNavigationBar(
              selectedItemColor: buttonNavbar,
              unselectedItemColor: textColor.withOpacity(0.5),
              currentIndex: _selectedNavbar,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              onTap: (index) {
                _changeSelectedNavbar(index);
              },
              items: navigationItems.map((item) {
                return BottomNavigationBarItem(
                  icon: Icon(item['icon'] as IconData, size: 30),
                  label: item['label'] as String,
                );
              }).toList(),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
