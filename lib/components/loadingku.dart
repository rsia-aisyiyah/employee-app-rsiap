import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';

loadingku() {
  return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      ));
}
