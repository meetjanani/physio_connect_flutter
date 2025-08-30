
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/utils/view_extension.dart';

import '../../base_code/base_binding.dart';
import '../../model/user_model.dart';
import '../../supabase/firebase_auth_controller.dart';

class SignUpController extends GetxController {
  static SignUpController get to => Get.find();
  SignUpController();

  // PlanServiceSupabaseController planServiceSupabaseController =
  //     PlanServiceSupabaseController.to;
  FirebaseAuthController firebaseController = FirebaseAuthController.to;
  var formKey = GlobalKey<FormState>();
  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController countryCodeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  RxBool passwordVisibal = RxBool(false);
  RxBool passwordVisibal2 = RxBool(false);
  RxBool isSelect1 = RxBool(false);
  OtpFieldController otpController = OtpFieldController();
  // Rx<CityMasterModel>? cityController = Rx(CityMasterModel(id: 1, cityName: "Rajkot", isActive: true));
  // RxList<CityMasterModel> cityList = RxList();

  // FirebaseAuthController firebaseController = FirebaseAuthController.to;
  RxString pin = '0'.obs;
  RxInt seconds = 60.obs;
  Timer? timer;

  void registerUser() {
    if (!fieldValidation()) {
      Get.showErrorSnackbar('Please enter valid details.');
      return;
    } else if (!isSelect1.value) {
      Get.showErrorSnackbar(
          'Please approve Terms & Condition and Privacy Policy');
      return;
    }
    var mobileNumber = countryCodeController.text.toString() +
        mobileNumberController.text.toString();
    firebaseController.isLoginRequest = false;
    firebaseController.userRegisterData = UserModel(
        name: nameController.text.toString(),
        mobileNumber: mobileNumber,
        doctorName: "Dr. Parul Desai",
        doctorId: 1
    ).toJson();
    firebaseController.fbRegister();
  }

  bool fieldValidation() {
    return formKey.currentState?.validate() == true;
  }

  void resend() {
    Get.back();
    Get.offNamed(AppPage.loginScreen);
  }

  void startTimer() {
    seconds = 60.obs;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (seconds > 0) {
        seconds.value--;
      } else {
        timer.cancel();
      }
    });
  }

  /*Future<void> fetchCities() async {
    var response = await planServiceSupabaseController.getAllCities();
    cityList.clear();
    cityList.addAll(response);
    cityController = Rx(cityList.first);
  }*/
}