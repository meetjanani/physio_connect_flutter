import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/ui/signUp/signup_controller.dart';
import 'package:physio_connect/utils/field_validations.dart';
import 'package:physio_connect/utils/view_extension.dart';

import '../../custom_widget/custom_button.dart';
import '../../custom_widget/custom_text_field.dart';
import '../../utils/database_schema.dart';
import '../../utils/theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  SignUpController controller = SignUpController.to;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    controller.countryCodeController.text = '+91';
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: Get.height * 0.3,
                  width: Get.width,
                  decoration: BoxDecoration(
                     /* image: DecorationImage(
                          image: AssetImage(bg), fit: BoxFit.fill),*/
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20)),
                      gradient: LinearGradient(colors: AppColors.primaryGradientColors)),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                      ),
                      Text(
                        DatabaseSchema.projectName,
                        style: GoogleFonts.fugazOne(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                      ),
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // myText(title: 'Welcome', textColor:  Colors.white,fontWeight:  FontWeight.w800, titleSize: 24),
                      SizedBox(
                        height: 24,
                      ),
                      myText(title: 'Glad to see you !', textColor:  Colors.white,fontWeight:  FontWeight.w500, titleSize: 14),
                      SizedBox(
                        height: 8,
                      ),
                      myText(title: 'Sign in to continue your physiotherapy journey', textColor:  Colors.white,fontWeight:  FontWeight.w500, titleSize: 14),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: controller.nameController,
                          labelText: 'Name',
                          hintText: 'Enter your Full name',
                          keyboardType: TextInputType.name,
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            return value?.validateEmpty();
                          },
                        ),
                        SizedBox(
                          height: 24,
                        ),
                        CustomTextField(
                          controller: controller.mobileNumberController,
                          labelText: 'Mobile Number',
                          hintText: 'Enter your mobile number',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_android_outlined,
                          validator: (value) {
                            return value?.validateMobile();
                          },
                        ),
                        SizedBox(
                          height: 24,
                        ),
                        Obx(() => _buildIAgreeAndTermsAndConditions()),
                        SizedBox(
                          height: 24,
                        ),
                        CustomButton(
                          text: 'Sign Up',
                          onPressed: () {
                            controller.registerUser();
                          },
                          isLoading: false,
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradientColors,
                          ),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        _buildSignInLink()
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIAgreeAndTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          value: controller.isSelect1.value,
          onChanged: (value) {
            setState(() {
              controller.isSelect1.value = value ?? false;
            });
          },
        ),
        Expanded(
          child: Text(
            'I have read and agree to the Terms & Conditions and Privacy Policy',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already Have an Account? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => Get.offNamed(AppPage.loginScreen),
          child: Text(
            'Sign In',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.medicalBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}