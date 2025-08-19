
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:physio_connect/route/route_module.dart';

class SplashController extends GetxController {
  static SplashController get to => Get.find();

  late Animation<Offset> offsetAnimation;


  launchPage() async {
    await Future.delayed(const Duration(seconds: 2), () {});
    if (FirebaseAuth.instance.currentUser != null) {
      Get.offNamed(AppPage.dashboardScreen);
    } else {
      Get.offNamed(AppPage.loginScreen);
    }
  }
}