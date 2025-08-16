
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:physio_connect/route/route_module.dart';

import '../base_code/base_binding.dart';
import '../utils/get_storage_repository.dart';

class SplashController extends GetxController with GetSingleTickerProviderStateMixin {
  static SplashController get to => Get.find();
  final GetStorageRepository _getStorageRepository;
  SplashController(this._getStorageRepository);

  late Animation<Offset> offsetAnimation;


  launchPage() async {
    await Future.delayed(const Duration(seconds: 2), () {});
    if (FirebaseAuth.instance.currentUser != null) {
      Get.offNamed(AppPage.dashboardScreen);
    } else {
      Get.offNamed(AppPage.splashScreen);
    }
  }
}