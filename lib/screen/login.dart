import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/string.dart';
import 'package:rsia_employee_app/screen/index.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:animations/animations.dart';
import 'package:rsia_employee_app/utils/biometric_helper.dart';
import 'package:rsia_employee_app/utils/secure_storage_helper.dart';

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
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _showBiometricPrompt = true;
  String username = '';
  String password = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  /// Check if biometric is available and enabled
  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await BiometricHelper.isBiometricAvailable();
    final isEnabled = await SecureStorageHelper.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricEnabled = isEnabled;
      });

      // Auto-trigger biometric if enabled
      if (isEnabled && isAvailable && _showBiometricPrompt) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _authenticateWithBiometric();
        });
      }
    }
  }

  /// Authenticate with biometric
  Future<void> _authenticateWithBiometric() async {
    setState(() => _showBiometricPrompt = false);

    final result = await BiometricHelper.authenticate(
      localizedReason: 'Login dengan fingerprint Anda',
    );

    if (result.success) {
      // Get saved credentials
      final credentials = await SecureStorageHelper.getCredentials();
      if (credentials != null) {
        setState(() {
          username = credentials.nik;
          password = credentials.password;
        });
        _performLogin(credentials.nik, credentials.password);
      } else {
        if (mounted) {
          Msg.error(
              context, 'Credentials tidak ditemukan. Silakan login manual');
        }
      }
    } else {
      // Show error if not user canceled
      if (result.errorCode != BiometricErrorCode.userCanceled && mounted) {
        Msg.warning(context, result.errorMessage ?? 'Autentikasi gagal');
      }
    }
  }

  /// Check if we should show biometric enrollment dialog
  Future<bool> _shouldShowBiometricDialog() async {
    final isAvailable = await BiometricHelper.isBiometricAvailable();
    if (!isAvailable) return false;

    final isEnabled = await SecureStorageHelper.isBiometricEnabled();
    if (isEnabled) return false; // Already enabled

    return true;
  }

  /// Show biometric enrollment dialog after successful login
  Future<void> _showBiometricEnrollmentDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: primaryColor, size: 28),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Aktifkan Login Fingerprint?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Login lebih cepat dan aman dengan fingerprint di lain waktu.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Trigger biometric scan for verification
              final result = await BiometricHelper.authenticate(
                localizedReason:
                    'Verifikasi fingerprint untuk mengaktifkan login otomatis',
              );

              if (result.success) {
                if (context.mounted) Navigator.pop(context);
                final saved = await SecureStorageHelper.saveCredentials(
                  nik: username,
                  password: password,
                );
                if (saved && mounted) {
                  Msg.success(context, 'Fingerprint berhasil diaktifkan!');
                }
              } else if (result.errorCode != BiometricErrorCode.userCanceled) {
                if (mounted) {
                  Msg.error(context, result.errorMessage ?? 'Verifikasi gagal');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                const Text('Aktifkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    _performLogin(username, password);
  }

  void _performLogin(String uname, String pass) async {
    setState(() {
      _isLoading = true;
    });

    final data = {'username': uname, 'password': pass};

    try {
      final res = await Api().auth(data, '/user/auth/login');
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        String token = body['access_token'];
        Map<String, dynamic> decodeToken = JwtDecoder.decode(token);

        box.write('token', token);
        box.write('sub', decodeToken['sub']);
        box.write('role', decodeToken['role']);
        box.write('dep', decodeToken['dep']);
        box.write('jbtn', decodeToken['jbtn']);

        // Check and show biometric enrollment dialog BEFORE navigation
        final shouldShowDialog = await _shouldShowBiometricDialog();

        if (shouldShowDialog && mounted) {
          await _showBiometricEnrollmentDialog();
        }

        // Then navigate
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const IndexScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      } else {
        Msg.error(context, body['message'] ?? wrongCredentials);
      }
    } catch (e) {
      debugPrint("Login error: $e");
      Msg.error(context,
          "Koneksi gagal: Silahkan periksa koneksi internet Anda atau hubungi IT.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Slightly off-white for contrast
        body: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                _buildHeader(),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Larsi Logo - Top Right & Smaller
            Positioned(
              top: 10,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Image.asset('assets/images/logo-larsi.png',
                    height: 40, width: 40),
              ),
            ),

            // Main Content - Center
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Image.asset('assets/images/logo-rsia-aisyiyah.png',
                        height: 90, width: 90),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Employee Self Service",
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "RSIA Aisyiyah Pekajangan",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 50), // Space for the card overlap
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.35,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Welcome Back!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Silahkan login untuk melanjutkan",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildUsernameField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 30),
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              "© 2024 IT RSIA Aisyiyah Pekajangan",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Username",
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.person_outline, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          filled: true,
          fillColor: Colors.transparent,
        ),
        onSaved: (value) => username = value!,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        obscureText: _secureText,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Password",
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
          suffixIcon: IconButton(
            icon: Icon(
              _secureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey[400],
            ),
            onPressed: _togglePasswordVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          filled: true,
          fillColor: Colors.transparent,
        ),
        onSaved: (value) => password = value!,
      ),
    );
  }

  Widget _buildLoginButton() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                _login();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 5,
                shadowColor: primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 25,
                      width: 25,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      "LOGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ),
        if (_biometricEnabled && _biometricAvailable) ...[
          const SizedBox(width: 12),
          _buildBiometricIconButton(),
        ],
      ],
    );
  }

  Widget _buildBiometricIconButton() {
    return InkWell(
      onTap: _authenticateWithBiometric,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 55,
        width: 60,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryColor, width: 2),
        ),
        child: Icon(Icons.fingerprint, color: primaryColor, size: 30),
      ),
    );
  }
}
