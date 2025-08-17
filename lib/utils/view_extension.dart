import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension ViewExtensions on void {
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

extension ScreenSizeResolutionDouble on double {
  dynamicHeight() {
    double originalHeight = 800;
    double currentHeight = Get.height;
    double givenHeight = this;
    double calculatedHeight = 0;
    calculatedHeight = ((currentHeight * givenHeight) / originalHeight);
    return calculatedHeight;
  }
  dynamicWidth() {
    double originalWidth = 375;
    double currentWidth = Get.height;
    double givenWidth = this;
    double calculatedWidth = 0;
    calculatedWidth = ((currentWidth * givenWidth) / originalWidth);
    return calculatedWidth;
  }
}

extension ScreenSizeResolutionInt on int {
  dynamicHeight() {
    double originalHeight = 800;
    double currentHeight = Get.height;
    int givenHeight = this;
    double calculatedHeight = 0;
    calculatedHeight = ((currentHeight * givenHeight) / originalHeight);
    return calculatedHeight;
  }
  dynamicWidth() {
    double originalWidth = 375;
    double currentWidth = Get.width;
    int givenWidth = this;
    double calculatedWidth = 0;
    calculatedWidth = ((currentWidth * givenWidth) / originalWidth);
    return calculatedWidth;
  }
}

circleProgressIndicator() =>
    Container(
        alignment: FractionalOffset.center,
        child: const CircularProgressIndicator(strokeWidth: 1));

myText({ required String title,
  Color textColor = Colors.white,
  FontWeight fontWeight = FontWeight.normal,
  double titleSize = 18}) =>
    Text(
      title,
      style: TextStyle(
          color: textColor, fontSize: titleSize, fontWeight: fontWeight),
    );
