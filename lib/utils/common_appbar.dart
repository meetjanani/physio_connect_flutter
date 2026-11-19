import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

/// Back from a page. When the page was opened directly (website deep link
/// or refresh) there is no previous page, so go to the start page instead of
/// popping the last route and leaving a blank screen.
void goBackOrHome() {
  if (Get.key.currentState?.canPop() ?? false) {
    Get.back();
  } else {
    Get.offAllNamed('/dashboard');
  }
}

PreferredSizeWidget commonAppBar(
  String appBarTitle, {
  bool isBackButtonVisible = false,
}) {
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
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: goBackOrHome,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  appBarTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
