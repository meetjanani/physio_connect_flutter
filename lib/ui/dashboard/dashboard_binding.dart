import 'package:get/get.dart';
import 'package:physio_connect/base_code/base_binding.dart';
import 'package:physio_connect/ui/dashboard/dashboard_controller.dart';
import 'package:physio_connect/ui/doctors/doctor_directory_controller.dart';

class DashboardBinding  extends BaseBinding{

  @override
  void dependencies() {
    super.dependencies();
    Get.lazyPut(() => DashboardController());
    if (!Get.isRegistered<DoctorDirectoryController>()) {
      Get.put(DoctorDirectoryController(), permanent: true);
    }
  }
}