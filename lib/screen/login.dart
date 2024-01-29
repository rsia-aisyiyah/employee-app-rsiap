import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/screen/index.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _secureText = true;
  var username = '';
  var password = '';

  final _formKey = GlobalKey<FormState>();

  showHide() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    if (username.isEmpty) {
      Msg.error(context, 'error');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (password.isEmpty) {
      Msg.error(context, 'error');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    var data = {
      'username': username,
      'password': password,
    };

    await Api().auth(data, '/auth/login').then((res) {
      if (res.statusCode == 200) {
        var body = jsonDecode(res.body);
        if (body['success']) {
          String token = body['access_token'];
          Map<String, dynamic> decodeToken = JwtDecoder.decode(token);

          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('token', json.encode(body['access_token']));
            prefs.setString('kd_sps', json.encode(decodeToken['sps']));
            prefs.setString('spesialis', json.encode(decodeToken['spss']));

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const IndexScreen(),
              ),
            );
          });
        } else {
          Msg.error(context, body['message']);
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        Msg.error(context, wrongCredentials);
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(child: SafeArea(child: _buildColumn())),
      ),
    );
  }

  Widget _buildColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // First blue container
        _buildTopConatiner(),
        // Button with offset
      ],
    );
  }

  Widget _buildTopConatiner() {
    bool isKeyboard = MediaQuery.of(context).viewInsets.bottom != 0.0;

    return Container(
      // alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  child: Image.asset(
                    'assets/images/logo-rsia-aisyiyah.png',
                    height: 100,
                    width: 100,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  child: Image.asset(
                    'assets/images/logo-larsi.png',
                    height: 100,
                    width: 100,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    child: Container(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Text(
                              "Employee Self Service [ESS] ",
                              style: TextStyle(
                                  fontSize: 22,
                                  color: textBlue,
                                  fontWeight: FontWeight.bold),
                              // textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "RSIA Aisyiyah Pekajangan",
                              style: TextStyle(
                                fontSize: 18,
                                color: textBlue,
                              ),
                              // textAlign: TextAlign.center,
                            ),
                          ],
                        ))),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 25.0, right: 25.0, top: 15.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 350,
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              )
                            ],
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      'Login',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: line,
                                          borderRadius:
                                              BorderRadius.circular(2)),
                                      width:
                                          MediaQuery.of(context).size.width / 6,
                                      height: 4,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                ],
                              ),
                            ),
                            Form(
                              key: _formKey,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bgWhite,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                primaryColor.withOpacity(0.3),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: TextFormField(
                                        maxLines: 1,
                                        decoration: InputDecoration(
                                          hintText: labelUsername,
                                          contentPadding:
                                              const EdgeInsets.all(2),
                                          border: InputBorder.none,
                                          hintStyle:
                                              TextStyle(color: textColor),
                                        ),
                                        style: TextStyle(color: textColor),
                                        onSaved: (value) {
                                          username = value!;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bgWhite,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                primaryColor.withOpacity(0.3),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: SingleChildScrollView(
                                        child: TextFormField(
                                          maxLines: 1,
                                          obscureText: _secureText,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            hintText: labelPassword,
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.all(2),
                                            hintStyle:
                                                TextStyle(color: textColor),
                                          ),
                                          onSaved: (value) {
                                            password = value!;
                                          },
                                        ),
                                      ),
                                    ),
                                    isKeyboard
                                        ? const SizedBox(height: 10)
                                        : Padding(
                                            padding: EdgeInsets.only(top: 15),
                                            child: Center(
                                              child: GestureDetector(
                                                onTap: () {
                                                  // Msg.info(context, forgotPasswordMsg);
                                                },
                                                child: Text(""),
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 25,
                      )
                    ],
                  ),
                  Positioned(
                    right: MediaQuery.of(context).size.width -
                        (MediaQuery.of(context).size.width - 10),
                    left: MediaQuery.of(context).size.width -
                        (MediaQuery.of(context).size.width - 10),
                    bottom: 0,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            _login();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size.fromHeight(50),
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          _isLoading ? processingText : loginText,
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
