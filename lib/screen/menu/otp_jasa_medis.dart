import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:rsia_employee_app/config/config.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/screen/menu/jasa_medis.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/components/loadingku.dart';
import 'package:rsia_employee_app/utils/msg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

Color accentPurpleColor = Color(0xFF6A53A1);
// Color primaryColor = Color(0xFF121212);
Color accentPinkColor = Color(0xFFF99BBD);
Color accentDarkGreenColor = Color(0xFF115C49);
Color accentYellowColor = Color(0xFFFFB612);
Color accentOrangeColor = Color(0xFFEA7A3B);

class OtpJasaMedis extends StatefulWidget {
  const OtpJasaMedis({super.key});

  @override
  State<OtpJasaMedis> createState() => _OtpJasaMedisState();
}

class _OtpJasaMedisState extends State<OtpJasaMedis> {
  late String nik;
  late Timer? countdownTimer;
  Duration myDuration = Duration(seconds: 60);
  bool isLoading = true;
  bool isLoadingButton = true;
  bool button = true;
  bool isSuccess = true;
  String kode = "";
  var email = "";
  var _pegawai = {};
  var _smtp = {};
  var random = Random().nextInt(8000) + 1000;

  final _formKey = GlobalKey<FormState>();


  final TextEditingController _otp = TextEditingController();

  void initState() {
    super.initState();
    fetchAllData().then((value) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Future updateEmail() async {
    var data = {
      'nik': nik,
      'email': email,
    };

    // print(data);
    var res = await Api().postData(data, '/pegawai/update-email');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      isSuccess = true;
      Msg.success(context, body['message']);
      return body;
    } else {
      var body = json.decode(res.body);
      isSuccess = false;
      Msg.error(context, body['message']);
      return body;
    }
  }


  void _activeButton() {
    setState(() {
      button = !button;
    });
  }

  void startTimer() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setCountDown();
    });
  }

  void stopTimer() {
    setState(() {
      countdownTimer!.cancel();
    });
  }

  void resetTimer() {
    stopTimer();
    setState(() {
      myDuration = Duration(seconds: 60);
    });
  }

  void setCountDown() {
    final reduceSecondsBy = 1;
    if (mounted) {
      setState(() {
        final seconds = myDuration.inSeconds - reduceSecondsBy;
        print(seconds);
        if (seconds < 0) {
          countdownTimer!.cancel();
          resetTimer();
          _activeButton();
        } else {
          myDuration = Duration(seconds: seconds);
        }
      });
    }
  }

  // final TextEditingController _mailMessageController = TextEditingController();
  Future<void> fetchAllData() async {
    List<Future> futures = [
      _getPegawai(),
      _getSmtp(),
      // _getJadwalOperasiNow(),
    ];

    await Future.wait(futures);
  }

  Future<void> _getPegawai() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    Map<String, dynamic> decodeToken = JwtDecoder.decode(token.toString());
    nik = decodeToken['sub'];
    var res = await Api().postData({'nik': nik}, '/pegawai/detail');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      // print(body);
      setState(() {
        _pegawai = body;
        // print(_pegawai);
      });
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);

      setState(() {
        _pegawai = {};
        isLoading = false;
      });
    }
  }

  Future<void> _getSmtp() async {
    var res = await Api().getData('/smtp');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      // print(body);
      setState(() {
        _smtp = body;
        // print(_smtp['data']['email']);
      });
    } else {
      var body = json.decode(res.body);
      Msg.error(context, body['message']);

      setState(() {
        _smtp = {};
        isLoading = false;
      });
    }
  }

  // Send Mail function
  void cekOtp({
    required String otp,
    // required String mailMessage,
  }) async {
    if (otp == random.toString()) {
      print("OTP SESUAI");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => JasaMedis(),
        ),
      );
    } else {
      showSnackbar('Kode verifikasi salah / tidak berlaku', 'fail');
    }
  }

  void sendMail({
    required String recipientEmail,
    required String mailMessage,
  }) async {
    print(random);
    setState(() {
      isLoadingButton = false;
      // random = Random().nextInt(8000) + 1000;
    });
    // change your email here
    String username = _smtp['data']['email'].toString();
    // change your password here
    String password = _smtp['data']['password'].toString();
    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Employee Self Service RSIAP')
      ..recipients.add(recipientEmail)
      ..subject = 'Kode Verifikasi Jasa Medis'
      ..text = 'Kode Verifikasi untuk akses ke menu Jasa Pelayanan anda : '
      ..html =
          '<p>Kode Verifikasi untuk akses menu Jasa Pelayanan Anda : </p><h1>$mailMessage<h1>';

    try {
      await send(message, smtpServer);
      showSnackbar('Kode verifikasi terkirim ', 'success');
      setState(() {
        isLoadingButton = true;
      });
      _activeButton();
      // resetTimer();
      startTimer();
    } on MailerException catch (e) {
      isLoadingButton = true;
      print('Message not sent.');
      showSnackbar('Format email tidak sesuai ', 'alert');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final seconds = strDigits(myDuration.inSeconds.remainder(60));
    // stopTimer();
    TextStyle? createStyle(Color color) {
      ThemeData theme = Theme.of(context);
      return theme.textTheme.displaySmall?.copyWith(color: color);
    }

    var otpTextStyles = [
      createStyle(accentPurpleColor),
      createStyle(accentYellowColor),
      createStyle(accentDarkGreenColor),
      createStyle(accentOrangeColor),
    ];
    if (isLoading) {
      return loadingku();
    } else {
      if (random != "") {
        // print(_pegawai['data']['pegawai']['npwp']);
        // sendMail(
        //     recipientEmail: _pegawai['data']['pegawai']['npwp'].toString(),
        //     mailMessage: random.toString());
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: const Text('Validasi Data'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20), color: bgWhite),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      button
                          ? "Dibutuhkan kode verifikasi untuk akses menu Slip Jaspel. \nSilahkan klik tombol Kirim Kode Verifikasi dibawah"
                          : "Cek email anda dan masukkan kode verifikasi pada kolom berikut : ",
                      textAlign: TextAlign.justify,
                      style: TextStyle(height: 1.5),
                    ),
                    SizedBox(
                      height: button ? 0 : 10,
                    ),
                    button
                        ? Text('')
                        : OtpTextField(
                            numberOfFields: 4,
                            borderColor: primaryColor,
                            disabledBorderColor: primaryColor,
                            focusedBorderColor: textColor,
                            styles: otpTextStyles,
                            showFieldAsBox: true,
                            borderWidth: 2.0,
                            enabledBorderColor: primaryColor,
                            fieldWidth: 55,
                            //runs when a code is typed in
                            onCodeChanged: (String code) {
                              //handle validation or checks here if necessary
                            },
                            //runs when every textfield is filled
                            onSubmit: (String verificationCode) {
                              kode = verificationCode;
                            },
                          ),
                    SizedBox(
                      height: button ? 0 : 10,
                    ),
                    button
                        ? Text('')
                        : RichText(
                            text: TextSpan(
                                style: TextStyle(color: textColor),
                                children: [
                                  TextSpan(
                                      text:
                                          'Kirim ulang Kode Verifikasi pada : '),
                                  TextSpan(
                                      text: '00:$seconds',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),

                    // const SizedBox(height: 20),
                    // const SizedBox(height: 30),
                    Flex(
                      direction: Axis.horizontal,
                      children: [
                        !button
                            ? buttonSubmit()
                            : Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    label: Text(!isLoadingButton
                                        ? ' Mengirim Kode Verifikasi'
                                        : 'Kirim Kode Verifikasi'),
                                    icon: !isLoadingButton
                                        ? SizedBox(
                                            child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                              color: textWhite,
                                              strokeWidth: 3,
                                            )),
                                            width: 25,
                                            height: 25,
                                          )
                                        : Icon(Icons.send),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: textWhite,
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                    onPressed: () {
                                      print(_pegawai['data']['rsia_email_pegawai']['email'].toString());
                                      if(_pegawai['data']['rsia_email_pegawai']['email'].toString()=='null'){
                                        showDataAlert();
                                      } else {
                                        sendMail(
                                          recipientEmail: _pegawai['data']
                                                  ['rsia_email_pegawai']['email']
                                              .toString(),
                                          mailMessage: random.toString(),
                                        );
                                      }
                                      // _pegawai['data']['rsia_email_pegawai']['email'].toString() ==  ? showDataAlert() :

                                    },
                                    // child: const Text('Kirim Kode Verifikasi'),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        return Scaffold();
      }
    }
  }

  Widget buttonVerif() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          label: Text(!isLoadingButton
              ? ' Mengirim Kode Verifikasi'
              : 'Kirim Kode Verifikasi'),
          icon: !isLoadingButton
              ? SizedBox(
                  child: Center(child: CircularProgressIndicator()),
                  width: 20,
                  height: 20,
                )
              : Icon(Icons.send),
          style: ElevatedButton.styleFrom(
            foregroundColor: textWhite,
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: () {
            sendMail(
                recipientEmail: _pegawai['data']['pegawai']
                        ['rsia_email_pegawai']['email']
                    .toString(),
                mailMessage: random.toString());
          },
          // child: const Text('Kirim Kode Verifikasi'),
        ),
      ),
    );
  }

  Widget buttonSubmit() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: textWhite,
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: button
              ? null
              : () {
                  print(kode);
                  cekOtp(
                    otp: kode,
                    // mailMessage: _mailMessageController.text.toString(),
                  );
                },
          // onPressed: () {
          //   print(kode);
          //   cekOtp(
          //     otp: kode,
          //     // mailMessage: _mailMessageController.text.toString(),
          //   );
          // },
          child: const Text('Submit'),
        ),
      ),
    );
  }

  void showSnackbar(String message, String alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: textWhite),
            const SizedBox(width: 10),
            Text(message, style: TextStyle(color: textWhite)),
          ],
        ),
        duration: const Duration(seconds: snackBarDuration),
        backgroundColor: alert == "success" ? primaryColor : errorColor,
      ),
    );
  }
  void main() {
    var rng = Random();
    // for (var i = 0; i < 10; i++) {
    print(rng.nextInt(8000) + 1000);
    // }
  }

  showDataAlert() {
    final OtpJasaMedis otp= new OtpJasaMedis();

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return Form(
            key: _formKey,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    15,
                  ),
                ),
              ),
              contentPadding: EdgeInsets.only(
                top: 5.0,
              ),
              // title: Text(
              //   "Tambah Email",
              //   style: TextStyle(fontSize: 24.0),
              // ),
              content: Container(
                // height: 400,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Data email belum ada",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: SizedBox(
                              // height: 50,
                              child: TextFormField(
                                maxLines: 1,
                                decoration: InputDecoration(
                                    helperText: "Silahkan masukkan email anda",
                                    contentPadding:
                                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)
                                    ),

                                    hintText: 'Masukkan email disini',

                                    labelText: 'Email'),
                                onSaved: (value) {
                                  email = value!;
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Field tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            height: 50,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25)
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  if(EmailValidator.validate(email)){
                                    updateEmail();
                                    print(isSuccess);
                                      if(isSuccess){
                                        Navigator.of(context).pop();
                                      }
                                  } else {
                                    Msg.error(context, 'Format Email tidak sesuai');
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  // primary: primaryColor,
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                              ),
                              child: Text(
                                "Submit",
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: -10,
                        right: -5,
                        child: Container(
                            decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Icon(Icons.close_rounded,color: bgWhite,))),),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}




