import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pinput/pinput.dart';

import '../../config/config.dart';
import 'jasa_medis.dart';

class OtpJasaMedis extends StatefulWidget {
  const OtpJasaMedis({super.key});

  @override
  State<OtpJasaMedis> createState() => _OtpJasaMedisState();
}

class _OtpJasaMedisState extends State<OtpJasaMedis> {
  final box = GetStorage();
  late final TextEditingController pinController;
  late final FocusNode focusNode;
  late final GlobalKey<FormState> formKey;
  late Timer countdownTimer;

  bool terkirim = false; // Declare 'terkirim' as an instance variable
  int remainingTime = 0; // Time left in seconds

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    pinController = TextEditingController();
    focusNode = FocusNode();

    final expirationTime = box.read<int>('expirationTime');
    if (expirationTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeLeft = expirationTime - currentTime;
      if (timeLeft > 0) {
        terkirim = true;
        remainingTime = timeLeft ~/ 1000; // Convert milliseconds to seconds
        startCountdown();
      }
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    countdownTimer.cancel(); // Cancel the timer if it's running
    super.dispose();
  }

  void startCountdown() {
    setState(() {
      terkirim = true;
    });

    final expirationTime = box.read<int>('expirationTime')!;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    remainingTime = (expirationTime - currentTime) ~/ 1000; // Convert milliseconds to seconds

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime <= 0) {
        timer.cancel();
        setState(() {
          terkirim = false;
        });
        box.remove('expirationTime'); // Clear expiration time after countdown ends
      } else {
        setState(() {
          remainingTime--;
        });
      }
    });
  }

  void sendOtp() async {
    const url = "$baseUrl/api/v2/otp/create";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer ${box.read('token')}'},
        body: jsonEncode({ 'app_id': 5 }),
      );

      if (response.statusCode >= 200) {
        final expirationTime = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
        box.write('expirationTime', expirationTime);

        startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromRGBO(57, 144, 236, 1.0),
            content: Text(
              'Kode verifikasi telah dikirim ke nomor telepon Anda yang terdaftar via WhatsApp, cek berkala pesan masuk Anda!',
            ),
          ),
        );
      } else {
        // Handle error response from the API
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Gagal mengirim OTP, coba lagi nanti.'),
          ),
        );
      }
    } catch (e) {
      // Handle any exceptions during the API call
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Terjadi kesalahan jaringan, coba lagi nanti.'),
        ),
      );
    }
  }

  Future<void> validateOtp(String pin) async {
    const url = "$baseUrl/api/v2/otp/verify";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer ${box.read('token')}'},
        body: jsonEncode({"otp": pin, "app_id": 5,}),
      );

      if (response.statusCode == 200) {
        // OTP is valid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('OTP valid!'),
          ),
        );

        // clear the countdown timer
        countdownTimer.cancel();
        box.remove('expirationTime');

        // Navigate to the next screen with class JasaMedis
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const JasaMedis()));
      } else {
        // OTP is invalid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('OTP tidak valid'),
          ),
        );
      }
    } catch (e) {
      // Handle any exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Terjadi kesalahan jaringan'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const focusedBorderColor = Color.fromRGBO(82, 162, 246, 1.0);
    const fillColor = Color.fromRGBO(243, 246, 249, 0);
    const borderColor = Color.fromRGBO(75, 147, 255, 1.0);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: FractionallySizedBox(
          widthFactor: 1,
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Verifikasi Akses',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Text(
                    'Dibutuhkan kode verifikasi untuk mengakses menu slip jada pelayanan,',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromRGBO(30, 60, 87, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Pinput(
                    controller: pinController,
                    focusNode: focusNode,
                    defaultPinTheme: defaultPinTheme,
                    separatorBuilder: (index) => const SizedBox(width: 8),
                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                    onCompleted: (pin) async {
                      await validateOtp(pin); // Call the API validation method
                    },
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: focusedBorderColor),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    submittedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: focusedBorderColor),
                      ),
                    ),
                    errorPinTheme: defaultPinTheme.copyBorderWith(
                      border: Border.all(color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                buildButtonKirimKode(),
                if (terkirim) ...[
                  Text(
                    formatDuration(Duration(seconds: remainingTime)),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromRGBO(30, 60, 87, 1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButtonKirimKode() {
    if (terkirim) {
      return Column(
        children: [
          const Text(
            'Tidak menerima kode?',
            style: TextStyle(
              fontSize: 16,
              color: Color.fromRGBO(30, 60, 87, 1),
            ),
          ),
          TextButton(
            onPressed: () {
              if(kDebugMode) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const JasaMedis()));
                return;
              }

              if (remainingTime > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text(
                      'Anda harus menunggu hingga waktu habis untuk mengirim ulang kode',
                    ),
                  ),
                );
                return;
              }

              sendOtp();
            },
            child: const Text(
              'Kirim ulang kode',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromRGBO(57, 144, 236, 1.0),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          TextButton(
            onPressed: () {
              if(kDebugMode) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const JasaMedis()));
                return;
              }
              sendOtp();
            },
            child: const Text(
              'Kirim kode',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromRGBO(57, 144, 236, 1.0),
              ),
            ),
          ),
        ],
      );
    }
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
