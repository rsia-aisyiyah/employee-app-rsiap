import 'package:flutter/material.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/config/config.dart';

class Msg {
  static show(BuildContext context, String message) {
    if (ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Flexible(
        child: Text(
          message,
          style: TextStyle(color: textWhite),
        ),
      ),
      duration: const Duration(seconds: snackBarDuration),
      backgroundColor: primaryColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  static success(BuildContext context, String message) {
    if (ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: textWhite,
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: textWhite),
            ),
          )
        ],
      ),
      duration: const Duration(seconds: snackBarDuration),
      backgroundColor: successColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  static info(BuildContext context, String message) {
    if (ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: textWhite,
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: textWhite),
            )
          )
        ],
      ),
      duration: const Duration(seconds: snackBarDuration),
      backgroundColor: successColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  static warning(BuildContext context, String message) {
    if (ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: textWhite,
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: textWhite),
            ),
          )
        ],
      ),
      duration: const Duration(seconds: snackBarDuration),
      backgroundColor: successColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  static error(BuildContext context, String message) {
    if (ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.error,
            color: textWhite,
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: textWhite),
            ),
          )
        ],
      ),
      duration: const Duration(seconds: snackBarDuration),
      backgroundColor: errorColor,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
