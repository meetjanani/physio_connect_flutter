
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DependencyInjection {
  static void init() {
    Get.lazyPut<GetStorage>(() => GetStorage("myData"), fenix: true);
    // Get.lazyPut<GetStorageRepository>(() => GetStorageRepository(Get.find()), fenix: true);
    // Get.lazyPut<Connectivity>(Connectivity.new, fenix: true);
    // Get.lazyPut<NetworkInfo>(() => NetworkInfoImpl(Get.find()), fenix: true);
  }
}