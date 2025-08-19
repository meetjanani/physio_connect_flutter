
import 'package:get/get.dart';

class DependencyInjection {
  static void init() {
    // Get.lazyPut<GetStorageRepository>(() => GetStorageRepository(Get.find()), fenix: true);
    // Get.lazyPut<Connectivity>(Connectivity.new, fenix: true);
    // Get.lazyPut<NetworkInfo>(() => NetworkInfoImpl(Get.find()), fenix: true);
  }
}