import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:permission_handler/permission_handler.dart';
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
    firebaseInit();
  }

  void reqPermission() async {
    var manageExtStorage = await Permission.manageExternalStorage.status;
    if (!manageExtStorage.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
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
    await FirebaseMessaging.instance.subscribeToTopic("3.912.0819");

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
        return false;
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
