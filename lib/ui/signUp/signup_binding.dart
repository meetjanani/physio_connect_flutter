import 'package:get/get.dart';
import 'package:physio_connect/ui/signUp/signup_controller.dart';

import '../../base_code/base_binding.dart';

class SignUpBinding extends BaseBinding {

  @override
  void dependencies() {
    // TODO: implement dependencies
    super.dependencies();
    Get.lazyPut(() => SignUpController());
  }
}