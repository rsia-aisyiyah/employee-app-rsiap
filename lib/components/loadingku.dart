import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:lottie/lottie.dart';

loadingku({bool fullPage = true}) {
  if (!fullPage) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  return Scaffold(
    backgroundColor: bgColor,
    body: SafeArea(
      child: Center(
          child: LottieBuilder.asset(
        'assets/images/loading2.json',
        width: 120,
      )),
    ),
  );
}
