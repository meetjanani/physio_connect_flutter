import 'package:get/get.dart';
import 'package:physio_connect/ui/splash_controller.dart';

import '../base_code/base_binding.dart';

class SplashBinding extends BaseBinding {

  @override
  void dependencies() {
    super.dependencies();
    Get.lazyPut(() => SplashController());
  }
}