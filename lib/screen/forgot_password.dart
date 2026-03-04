import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String username = '';
  String email = '';
  String captchaCode = '';
  String? captchaId;
  String? captchaImg;

  @override
  void initState() {
    super.initState();
    _fetchCaptcha();
  }

  Future<void> _fetchCaptcha() async {
    try {
      final res = await Api().getGuestData('/user/auth/captcha');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 &&
          (body['success'] == true || body['status'] == 'success')) {
        setState(() {
          // Adapt to API structure
          final data = body['data'];
          captchaId = data['captcha_id'].toString();
          captchaImg = data['captcha_img'];
          captchaCode = '';
        });
      }
    } catch (e) {
      debugPrint("Captcha error: $e");
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (captchaId == null) {
      Msg.error(context, "Captcha belum dimuat");
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'username': username,
      'email': email,
      'captcha_id': captchaId,
      'captcha_code': captchaCode,
    };

    try {
      final res = await Api().auth(data, '/user/auth/forgot-password');
      final body = jsonDecode(res.body);

      if (res.statusCode == 200 &&
          (body['success'] == true || body['status'] == 'success')) {
        if (mounted) {
          Msg.success(context,
              body['message'] ?? "Link reset password telah dikirim ke email");
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          Msg.error(context, body['message'] ?? "Terjadi kesalahan");
          _fetchCaptcha();
        }
      }
    } catch (e) {
      debugPrint("Forgot password error: $e");
      if (mounted) {
        Msg.error(
            context, "Koneksi gagal: Silahkan periksa koneksi internet Anda.");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Lupa Password",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_reset, color: Colors.white, size: 80),
          const SizedBox(height: 20),
          const Text(
            "Pulihkan Password",
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Masukkan username dan email terdaftar Anda",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(25),
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
              _buildTextField(
                hint: "Username / NIK",
                icon: Icons.person_outline,
                onSaved: (v) => username = v!,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                hint: "Email Terdaftar",
                icon: Icons.email_outlined,
                onSaved: (v) => email = v!,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              if (captchaImg != null) ...[
                const Text(
                  "Klik gambar untuk memperbarui captcha",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _fetchCaptcha,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildCaptchaImage(),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  hint: "Masukkan Captcha",
                  icon: Icons.security,
                  onSaved: (v) => captchaCode = v!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
              ],
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptchaImage() {
    if (captchaImg == null) return const SizedBox();

    if (captchaImg!.startsWith('data:image')) {
      final base64String = captchaImg!.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        height: 60,
        fit: BoxFit.contain,
      );
    } else {
      return Image.network(
        captchaImg!,
        height: 60,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.refresh, size: 40),
      );
    }
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        textAlign: textAlign,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          filled: true,
          fillColor: Colors.transparent,
        ),
        onSaved: onSaved,
        validator: (value) =>
            value == null || value.isEmpty ? "Bidang ini harus diisi" : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
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
                "KIRIM LINK",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
