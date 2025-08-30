import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

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


Widget buildDatePickerButton({
  required String label,
  required DateTime date,
  required VoidCallback onTap
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy').format(date),
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Spacer(),
          Icon(Icons.calendar_today, size: 16, color: AppColors.medicalBlue),
        ],
      ),
    ),
  );
}