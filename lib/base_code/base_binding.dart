
import 'package:get/get.dart';
import 'package:physio_connect/supabase/supabase_controller.dart';

import '../supabase/firebase_auth_controller.dart';
import '../utils/database_schema.dart';
import '../utils/get_storage_repository.dart';

class BaseBinding extends Bindings {

  @override
  void dependencies() {
    Get.lazyPut(() => FirebaseAuthController(Get.find()));
    Get.lazyPut(() => SupabaseController());
    Get.lazyPut(() => DatabaseSchema());
    Get.lazyPut(() => GetStorageRepository(Get.find()));
  }
}