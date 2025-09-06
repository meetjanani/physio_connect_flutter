

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:physio_connect/supabase/supabase_controller.dart';
import 'package:physio_connect/utils/view_extension.dart';

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
    fetchFirebaseToken();
    await fetchDoctorDetail();
  }

  Future<void> fetchFirebaseToken() async {
    userModelSupabase = await UserModelSupabase.getFromSecureStorage();
    final messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    if(token != null && ((userModelSupabase?.id ?? 0) > 0) && userModelSupabase?.firebaseToken != token) {
      userModelSupabase?.firebaseToken = token;
      userModelSupabase?.saveToSecureStorage();
    }
    print('Firebase Token=$token');
    updateFirebaseToken(token.toString());
    await supabaseController.updateFirebaseToken(
        userModelSupabase?.id ?? 0, token.toString());
  }

  Future<void> fetchDoctorDetail() async {
    var doctor = await supabaseController.getDoctorById(
        userModelSupabase?.doctorId ?? 0);
    doctor?.saveToSecureStorage();
  }

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