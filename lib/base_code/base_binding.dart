
import 'package:get/get.dart';
import 'package:physio_connect/supabase/supabase_controller.dart';

import '../supabase/firebase_auth_controller.dart';
import '../utils/database_schema.dart';
import '../utils/secure_storage/secure_storage_repository.dart';

class BaseBinding extends Bindings {

  @override
  void dependencies() {
    Get.lazyPut(() => FirebaseAuthController());
    Get.lazyPut(() => SupabaseController());
    Get.lazyPut(() => DatabaseSchema());
    Get.lazyPut<SecureStorageRepository>(
          () => SecureStorageRepository(),
      fenix: true,
    );
  }
}
/// App-wide services registered once at start-up (`initialBinding`).
///
/// `fenix: true` re-creates a service if GetX disposed it together with the
/// page that first used it, so pages without their own binding (and pages
/// opened directly from a website URL) can always find them.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FirebaseAuthController(), fenix: true);
    Get.lazyPut(() => SupabaseController(), fenix: true);
    Get.lazyPut(() => DatabaseSchema(), fenix: true);
    Get.lazyPut<SecureStorageRepository>(
      () => SecureStorageRepository(),
      fenix: true,
    );
  }
}
