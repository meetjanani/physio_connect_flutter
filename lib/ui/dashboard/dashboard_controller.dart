
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:physio_connect/supabase/supabase_controller.dart';

import '../../model/user_model_supabase.dart';
import '../../utils/app_shared_preference.dart';

class DashboardController extends GetxController {
  static DashboardController get to => Get.find();
  DashboardController();

  SupabaseController supabaseController =
      SupabaseController.to;
  RxBool isLoading = false.obs;
  UserModelSupabase? userModelSupabase;

  @override
  void onInit() async {
    super.onInit();
    await fetchFirebaseToken();
  }

  Future<void> fetchFirebaseToken() async {
    userModelSupabase = await getUserModel();
    final messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    updateFirebaseToken(token.toString());
    print('Firebase Token=$token');
    await supabaseController.updateFirebaseToken(
        userModelSupabase?.id ?? 0, token.toString());
  }

}