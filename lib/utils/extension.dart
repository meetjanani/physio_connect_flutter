import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension VoidExtensions on void {
  showProgress() {
    Get.dialog(Container(
        alignment: FractionalOffset.center,
        child: const CircularProgressIndicator(strokeWidth: 1)));
  }

  void hideProgressBar() {
    Get.back();
  }

  showErrorSnackbar(String? message) {
    Get.snackbar("There was a problem", message!,
        colorText: Colors.white, backgroundColor: Colors.red);
  }

  showSuccessSnackbar(String? message) {
    Get.snackbar("Success", message!,
        colorText: Colors.black, backgroundColor: Colors.greenAccent);
  }

  showSnackbar(String? title,String? message) {
    Get.snackbar(title!, message!,
        colorText: Colors.black, backgroundColor: Colors.white);
  }
}

extension DateFormatExtensions on String {
  String getColabDateFormat() {
    String inputDateStr = this; // "2023-09-24T16:47:03.385503+00:00"
    DateTime inputDate = DateTime.parse(inputDateStr);

    String formattedDate = DateFormat('dd-MM-yyyy').format(inputDate);
    return formattedDate; // Output: Sep 24, 2023
  }
}