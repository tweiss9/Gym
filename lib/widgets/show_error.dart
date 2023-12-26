
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar_helper.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    FlushbarHelper.createError(
      message: message,
      duration: const Duration(seconds: 3),
    ).show(context);
  }
}