import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

PreferredSizeWidget commonAppBar(String appBarTitle, {bool isBackButtonVisible = false}) {
  return PreferredSize(
    preferredSize: Size.fromHeight(kToolbarHeight),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradientColors,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Center(
              child: Visibility(
                visible: isBackButtonVisible,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: 28,),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  appBarTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fugazOne(
                    textStyle: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
