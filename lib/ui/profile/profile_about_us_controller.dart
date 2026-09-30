import 'package:get/get.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/utils/constants.dart';

import '../../model/user_model_supabase.dart';
import '../../supabase/firebase_auth_controller.dart';
import '../../supabase/supabase_controller.dart';
import '../../utils/app_shared_preference.dart';

class ProfileAboutUsController extends GetxController {
  static ProfileAboutUsController get to => Get.put(ProfileAboutUsController());

  SupabaseController supabaseController = SupabaseController.to;
  FirebaseAuthController authController = FirebaseAuthController.to;
  RxBool isLoading = false.obs;
  RxBool isDoctor = false.obs;
  Rx<UserModelSupabase?> userModelSupabase = Rx<UserModelSupabase?>(null);
  Rx<DoctorModel?> doctor =  Rx<DoctorModel?>(null);
  String patientProfileImage = "https://firebasestorage.googleapis.com/v0/b/physio-connect-app.firebasestorage.app/o/Doctor_Profile_Photos%2Fpatient_common_profile_picture.jpg?alt=media&token=0c67dc67-9f2b-401a-86f3-91ff07f5c3d9";

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    isLoading.value = true;
    try {
      await fetchUserProfile();
      await fetchDoctorProfile();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserProfile() async {
    var mobileNumber = await secureStorageRepository.read(SecureStorage.userMobileNumberSessionStorage) ?? '';
    userModelSupabase.value = await UserModelSupabase.getFromSecureStorage();
    isDoctor.value = isDoctorTypeUser(userModelSupabase.value);
    if (userModelSupabase.value?.id == null && mobileNumber.isNotEmpty) {
      userModelSupabase.value = await authController.fetchUserProfile(mobileNumber);
    }
  }

  Future<void> fetchDoctorProfile() async {
    doctor.value = await DoctorModel.getFromSecureStorage();
    if (doctor.value?.id == null &&
        (userModelSupabase.value?.doctorId ?? 0) > 0) {
      doctor.value = await supabaseController.getDoctorById(
        userModelSupabase.value!.doctorId ?? 0,
      );
      doctor.value?.saveToSecureStorage();
    }
  }

  void logout() async {
    authController.signOutUser(navigateUser: true);
  }

  Future<void> updateDisplayName(String name) async {
    final user = userModelSupabase.value;
    if (user == null || user.id <= 0) return;
    isLoading.value = true;
    try {
      await supabaseController.updateUserName(user.id, name);
      user.name = name;
      await user.saveToSecureStorage();
      userModelSupabase.value = user;
      userModelSupabase.refresh();
      Get.snackbar('Updated', 'Your name was saved.');
    } finally {
      isLoading.value = false;
    }
  }
}
