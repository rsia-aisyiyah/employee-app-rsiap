import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/screen/index.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final box = GetStorage();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _secureText = true;
  String username = '';
  String password = '';

  void _togglePasswordVisibility() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    _formKey.currentState!.save();

    // final data = {'username': username, 'password': password};
    final data = {'username': '3.928.0623', 'password': '!040601!'};

    final res = await Api().auth(data, '/user/auth/login');
    final body = jsonDecode(res.body);

    setState(() {
      _isLoading = false;
    });

    if (res.statusCode == 200) {
      String token = body['access_token'];
      Map<String, dynamic> decodeToken = JwtDecoder.decode(token);

      box.write('token', token);
      box.write('sub', decodeToken['sub']);
      box.write('role', decodeToken['role']);
      box.write('dep', decodeToken['dep']);
      box.write('jbtn', decodeToken['jbtn']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IndexScreen()),
      );
    } else {
      Msg.error(context, body['message'] ?? wrongCredentials);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(child: SafeArea(child: _buildContent())),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopContainer(),
      ],
    );
  }

  Widget _buildTopContainer() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLogoRow(),
          _buildTitle(),
          _buildLoginForm(isKeyboardVisible),
        ],
      ),
    );
  }

  Widget _buildLogoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLogo('assets/images/logo-rsia-aisyiyah.png'),
        _buildLogo('assets/images/logo-larsi.png'),
      ],
    );
  }

  Widget _buildLogo(String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Image.asset(assetPath, height: 100, width: 100),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            "Employee Self Service [ESS]",
            style: TextStyle(fontSize: 22, color: textBlue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "RSIA Aisyiyah Pekajangan",
            style: TextStyle(fontSize: 18, color: textBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isKeyboardVisible) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Form(
        key: _formKey,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLoginHeader(),
                  _buildUsernameField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  if (!isKeyboardVisible) _buildForgotPassword(),
                ],
              ),
            ),
            _buildLoginButton()
          ],
        ),
      ),
    );
  }

  Widget _buildLoginHeader() {
    return Column(
      children: [
        const Center(child: Text('Login', style: TextStyle(fontSize: 24))),
        const SizedBox(height: 5),
        Center(
          child: Container(
            decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
            width: MediaQuery.of(context).size.width / 6,
            height: 4,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        maxLines: 1,
        decoration: InputDecoration(hintText: labelUsername, border: InputBorder.none),
        onSaved: (value) => username = value!,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        maxLines: 1,
        obscureText: _secureText,
        decoration: InputDecoration(
          hintText: labelPassword,
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(_secureText ? Icons.visibility : Icons.visibility_off),
            onPressed: _togglePasswordVisibility,
          ),
        ),
        onSaved: (value) => password = value!,
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Center(
        child: GestureDetector(
          onTap: () {
            // Msg.info(context, forgotPasswordMsg);
          },
          child: const Text(""),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Positioned(
      right: -0,
      left: 0,
      bottom: -20,
      child: Center(
        child: SizedBox(
          width: 150,
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _login();
              }
            },
            style: ElevatedButton.styleFrom(
              fixedSize: const Size.fromHeight(50),
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              _isLoading ? processingText : loginText,
              style: TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}