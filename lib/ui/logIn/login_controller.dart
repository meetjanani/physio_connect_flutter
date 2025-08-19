import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../supabase/firebase_auth_controller.dart';

class LoginController extends GetxController {
  static LoginController get to => Get.find();
  LoginController();

  var formKey = GlobalKey<FormState>();
  TextEditingController mobileNumber = TextEditingController();
  TextEditingController countryCodeController = TextEditingController();
  FirebaseAuthController firebaseController = FirebaseAuthController.to;
  RxBool passwordVisibal = RxBool(false);
  RxBool isLoading = RxBool(false);

  Future<void> signIn() async {
    if (fieldValidation()) {
      isLoading.value = true;
      firebaseController.isLoginRequest = true;
      firebaseController.fbLogin(
          countryCodeController.text.toString() + mobileNumber.text.toString());
      isLoading.value = false;
    }
  }

  bool fieldValidation() {
    return formKey.currentState?.validate() == true;
  }
}