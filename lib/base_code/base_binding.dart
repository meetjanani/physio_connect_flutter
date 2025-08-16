
import 'package:get/get.dart';

import '../supabase/firebase_auth_controller.dart';
import '../utils/database_schema.dart';
import '../utils/get_storage_repository.dart';

class BaseBinding extends Bindings {

  @override
  void dependencies() {
    Get.lazyPut(() => FirebaseAuthController(Get.find()));
    // Get.lazyPut(() => PlanServiceSupabaseController());
    Get.lazyPut(() => DatabaseSchema());
    Get.lazyPut(() => GetStorageRepository(Get.find()));
  }
}