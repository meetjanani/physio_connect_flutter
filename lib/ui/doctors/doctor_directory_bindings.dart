import 'package:get/get.dart';
import 'package:physio_connect/base_code/base_binding.dart';
import 'package:physio_connect/ui/book_session/booking_controller.dart';
import 'package:physio_connect/ui/doctors/doctor_directory_controller.dart';

class DoctorDirectoryBindings extends BaseBinding {
  @override
  void dependencies() {
    super.dependencies();
    if (!Get.isRegistered<DoctorDirectoryController>()) {
      Get.put(DoctorDirectoryController(), permanent: true);
    }
    if (!Get.isRegistered<BookingController>()) {
      Get.put(BookingController(), permanent: true);
    }
  }
}
