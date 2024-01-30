import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/config/api.dart';
import 'package:rsia_employee_app/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  Future<bool> doLogout() async {
    final prefs = await SharedPreferences.getInstance();

    var res = await Api().postRequest('/auth/logout');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        await prefs.clear();
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Future unsubscribeFromTopic() async {
    String token;
    var firebaseMessaging = await FirebaseMessaging.instance;
    token = (await firebaseMessaging.getToken())!;

    String url = "https://iid.googleapis.com/iid/info/" + token + "?details=true";
    var res = await http.get(Uri.parse(url), headers: {
      "Authorization": "Bearer ${ApiConfig.fsk}",
    });


    if (res.statusCode == 200) {
      var body = jsonDecode(res.body);
      Map<String, dynamic> subscribedTopics = body['rel']['topics'];

      subscribedTopics.forEach((key, value) async {
        await Future.delayed(Duration(milliseconds: 10));
        await FirebaseMessaging.instance.unsubscribeFromTopic(key);
        debugPrint("Unsubscribed from topic: $key");
      });

      firebaseMessaging.deleteToken();
      await FirebaseMessaging.instance.deleteToken();

      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([unsubscribeFromTopic(), doLogout()]),
        builder: (context, snapshot) {
          // if 2 od  them finished
          if (snapshot.connectionState == ConnectionState.done) {
            // show loading 2 second then navigate to login
            Future.delayed(Duration(seconds: 2), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
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