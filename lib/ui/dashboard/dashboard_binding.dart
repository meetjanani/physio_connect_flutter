import 'package:get/get.dart';
import 'package:physio_connect/base_code/base_binding.dart';
import 'package:physio_connect/ui/dashboard/dashboard_controller.dart';

class DashboardBinding  extends BaseBinding{

  @override
  void dependencies() {
    super.dependencies();
    Get.lazyPut(() => DashboardController());
  }
}