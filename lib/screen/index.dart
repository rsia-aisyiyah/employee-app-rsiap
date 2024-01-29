import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rsia_employee_app/api/firebase_api.dart';
import 'package:rsia_employee_app/api/request.dart';
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
    validasiToken();
    firebaseInit();
    checkForUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    checkForUpdate();
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
    await FirebaseMessaging.instance.subscribeToTopic(nik);

    // SharedPreferences.getInstance().then((prefs) async {
    //   var nik = prefs.getString('sub')!;
    //   print("NIK : " + nik);

    //   await FirebaseMessaging.instance
    //       .subscribeToTopic("${nik.replaceAll('"', '')}");
    // });
  }

  void _changeSelectedNavbar(int index) {
    setState(() {
      _selectedNavbar = index;
    });
  }

  // function validasi token to api/auth/me
  void validasiToken() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());

    // if token available
    if (token != null) {
      // validate token by exp
      var now = DateTime.now().millisecondsSinceEpoch / 1000;
      if (decodeToken['exp'] < now) {
        localStorage.remove('token');
        Navigator.pushReplacementNamed(context, '/login');
      }

      // validate token by api 
      await Api().postRequest('/auth/me').then((val) async {
        var res = jsonDecode(val.body);
        if (val.statusCode != 200 || res['success'] == false) {
          localStorage.remove('token');
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedNavbar != 0) {
          setState(() {
            _selectedNavbar = 0;
          });
          return false;
        }
        return true;
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
          child: Icon(
            Icons.add_circle,
            size: 36,
          ),
        ),
        // backgroundColor: bgColor,
        body: navigationItems[_selectedNavbar]['widget'] as Widget,
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          child: BottomAppBar(
            clipBehavior: Clip.antiAlias,
            shape: CircularNotchedRectangle(),
            color: Theme.of(context).primaryColor.withAlpha(255),
            child: BottomNavigationBar(
              selectedItemColor: buttonNavbar,
              unselectedItemColor: textColor.withOpacity(0.5),
              currentIndex: _selectedNavbar,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              onTap: (index) {
                _changeSelectedNavbar(index);
              },
              items: navigationItems.map((item) {
                return BottomNavigationBarItem(
                  icon: Icon(item['icon'] as IconData),
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
