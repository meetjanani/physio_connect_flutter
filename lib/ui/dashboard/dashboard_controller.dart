

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:physio_connect/supabase/supabase_controller.dart';

import '../../model/bookings_model.dart';
import '../../model/user_model_supabase.dart';
import '../../utils/app_shared_preference.dart';

class DashboardController extends GetxController {
  static DashboardController get to => Get.find();
  DashboardController();

  SupabaseController supabaseController =
      SupabaseController.to;
  RxBool isLoading = false.obs;
  UserModelSupabase? userModelSupabase;
  RxList<BookingsModel> upComingBookings = RxList();

  @override
  void onInit() async {
    super.onInit();
    await fetchFirebaseToken();
    await fetchDoctorDetail();
    await getUpComingBookings();
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

  Future<void> fetchDoctorDetail() async {
    var doctor = await supabaseController.getDoctorById(
        userModelSupabase?.doctorId ?? 0);
    doctor?.saveToSecureStorage();
  }

  // TODO: Update after every 10 min. or first time app launch based on Bool login.
  Future<void> getUpComingBookings() async {
    if (userModelSupabase?.id != null) {
      upComingBookings.clear();
      isLoading.value = true;
      var response = await supabaseController.getUpComingBookings(userModelSupabase?.id ?? 0);
      upComingBookings.addAll(response);
      isLoading.value = false;
    }
  }

}