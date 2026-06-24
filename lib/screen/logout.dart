import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/api.dart';
import 'package:rsia_employee_app/screen/login.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  Future<bool> doLogout() async {
    final box = GetStorage();

    var res = await Api().postRequest('/auth/logout');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        box.erase();
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> unsubscribeFromTopic() async {
    try {
      final box = GetStorage();
      final List<String> keys = ['sub', 'role', 'dep', 'jbtn'];
      for (var key in keys) {
        var val = box.read(key);
        if (val != null && val.toString().isNotEmpty) {
          debugPrint("Unsubscribing from topic: ${val.toString()}");
          try {
            await FirebaseMessaging.instance.unsubscribeFromTopic(val.toString());
          } catch (e) {
            debugPrint("Error unsubscribing from topic ${val.toString()}: $e");
          }
        }
      }
      debugPrint("Unsubscribing from topic: it");
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic('it');
      } catch (e) {
        debugPrint("Error unsubscribing from topic it: $e");
      }
      
      debugPrint("Deleting FCM token...");
      await FirebaseMessaging.instance.deleteToken();
      return true;
    } catch (e) {
      debugPrint("Error in unsubscribeFromTopic: $e");
      return false;
    }
  }

  Future<void> handleLogout() async {
    await unsubscribeFromTopic();
    await doLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: handleLogout(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // show loading 2 second then navigate to login
            Future.delayed(Duration(seconds: 2), () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (route) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            });

            return loadingku();
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),

      //   body: FutureBuilder<bool>(
      //     future: doLogout(),
      //     builder: (context, snapshot) {
      //       if (snapshot.hasData) {
      //         if (snapshot.data!) {
      //           print(snapshot.data);
      //           return const Center(
      //             child: CircularProgressIndicator(),
      //           );
      //         } else {
      //           return const Center(
      //             child: Text('Gagal Logout'),
      //           );
      //         }
      //       } else {
      //         return const Center(
      //           child: CircularProgressIndicator(),
      //         );
      //       }
      //     },
      //   ),
    );
  }
}
