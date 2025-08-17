import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../supabase/firebase_auth_controller.dart';
import '../../utils/get_storage_repository.dart';

class LoginController extends GetxController {
  static LoginController get to => Get.find();
  final GetStorageRepository _getStorageRepository;
  LoginController(this._getStorageRepository);

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