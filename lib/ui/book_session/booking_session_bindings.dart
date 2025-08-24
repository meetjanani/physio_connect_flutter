
import 'package:get/get.dart';
import 'package:physio_connect/ui/book_session/booking_controller.dart';

import '../../base_code/base_binding.dart';

class BookingSessionBindings extends BaseBinding{

  @override
  void dependencies() {
    super.dependencies();
    Get.lazyPut(() => BookingController());
  }
}