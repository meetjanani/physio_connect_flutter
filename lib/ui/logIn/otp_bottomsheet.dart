import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:physio_connect/ui/signUp/signup_controller.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../../custom_widget/custom_button.dart';
import '../../supabase/firebase_auth_controller.dart';

class OtpPage extends StatefulWidget {
  OtpPage({required this.verificationId, required this.phoneNumber, Key? key})
      : super(key: key);
  final String verificationId;
  final String phoneNumber;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  SignUpController controller = SignUpController.to;
  FirebaseAuthController firebaseController = FirebaseAuthController.to;
  /*late OTPTextEditController otpController;
  late OTPInteractor _otpInteractor;
  final scaffoldKey = GlobalKey();*/
  @override
  void initState() {
    super.initState();
    controller.startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: Get.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Enter Verification Code',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                 /* text('Enter Verification Code', Colors.black, 22,
                      FontWeight.w800),*/
                  const SizedBox(height: 10),
                  Text(
                    'Enter 6 digits OTP that you received on your phone. ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  /*text('Enter 6 digits OTP that you received on your phone. ',
                      hintTextColor, 14, FontWeight.w500),*/
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: OTPTextField(
                      length: 6,
                      controller: controller.otpController,
                      width: MediaQuery.of(context).size.width,
                      fieldWidth: 50,
                      style: TextStyle(
                        fontSize: 17,
                      ),
                      textFieldAlignment: MainAxisAlignment.spaceAround,
                      fieldStyle: FieldStyle.box,
                      otpFieldStyle: OtpFieldStyle(
                          borderColor: AppColors.uploadImageDottedBorderColor,
                          disabledBorderColor: AppColors.uploadImageDottedBorderColor,
                          enabledBorderColor: AppColors.uploadImageDottedBorderColor,
                          focusBorderColor: AppColors.uploadImageDottedBorderColor),
                      onCompleted: (pin) {
                        print("Completed: " + pin);
                        controller.pin.value = pin.toString();

                        // if(controller.type != '1'){
                        //   controller.verifyOTP(controller.data.id,pin);
                        // }else{
                        //   controller.vefifyForgotPassOtp(controller.userID, pin);
                        // }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Confirm',
                    onPressed: () {
                      // verify OTP function
                      firebaseController.verifyOtpForLoginUser(
                        widget.verificationId,
                        controller.pin.value,
                        widget.phoneNumber,
                      );
                    },
                    isLoading: false,
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradientColors,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t receive OTP ? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Obx(
                            () => controller.seconds.value == 0 ?
                        InkWell(
                            onTap: () {
                              // controller.resend();
                              verifyOtp();
                            },
                            child: Text(
                              'Resend',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.medicalBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            )) :
                        Text('Resend OTP in ${controller.seconds} secs.'),
                      ),
                    ],
                  ),
                  SizedBox(height: Get.width / 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void verifyOtp() {
     Get.back(); // dismiss otp screen
    controller.firebaseController
            .fbLogin(widget.phoneNumber);
  }
}