
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:physio_connect/route/route_module.dart';

class SplashController extends GetxController {
  static SplashController get to => Get.find();

  late Animation<Offset> offsetAnimation;


  launchPage() async {
    await Future.delayed(const Duration(seconds: 3), () {});
    if (FirebaseAuth.instance.currentUser != null) {
      Get.offNamed(AppPage.dashboardScreen);
    } else {
      Get.offNamed(AppPage.loginScreen);
    }
  }
}

// TODO NOTE
/*
* Add some bullet points here about what session type
* Lower back pain, neck pain, knee pain, shoulder pain, headache, arthritis, sports injuries, post-surgical rehabilitation, general fitness and wellness, prenatal and postnatal care
* CURA leasor, machine type , photo
*
* Reminder notification upon booking placed. & remind then 1 hour before session
*
* invoice share option
* */