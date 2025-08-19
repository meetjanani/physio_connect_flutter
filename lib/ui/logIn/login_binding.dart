import 'package:get/get.dart';

import '../../base_code/base_binding.dart';
import '../signUp/signup_controller.dart';
import 'login_controller.dart';

class LoginBinding extends BaseBinding {

  @override
  void dependencies() {
    super.dependencies();
    Get.lazyPut(() => LoginController());
    Get.lazyPut(() => SignUpController());
  }
}