import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/ui/logIn/login_controller.dart';
import 'package:physio_connect/utils/field_validations.dart';

import '../../custom_widget/custom_button.dart';
import '../../custom_widget/custom_text_field.dart';
import '../../custom_widget/physio_connect_logo.dart';
import '../../utils/enum.dart';
import '../../utils/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginController controller = LoginController.to;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  UserType _selectedUserType = UserType.patient;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.countryCodeController.text = '+91';
    controller.mobileNumber.text = '1122334455';
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Obx(
              () => Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildLoginForm(),
                  const SizedBox(height: 40),
                  // _buildForgotPassword(),
                  // const SizedBox(height: 32),
                  // _buildSocialLogin(),
                  // const SizedBox(height: 32),
                  _buildSignUpLink(),
                ],
              )
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const PhysioConnectLogo(
          size: LogoSize.extraLarge,
          variant: LogoVariant.colored,
          showText: true,
        ),
        const SizedBox(height: 16),
        /*Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),*/
        const SizedBox(height: 40),
        Text(
          'Sign in to continue your physiotherapy journey',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: controller.mobileNumber,
            labelText: 'Mobile Number',
            hintText: 'Enter your mobile number',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_android_outlined,
            validator: (value) {
              return value?.validateMobile();
            },
          ),
          const SizedBox(height: 40),
        /*  CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textMuted,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 16),
          _buildRememberMeRow(),
          const SizedBox(height: 24),*/
          CustomButton(
            text: 'Sign In',
            onPressed: _handleLogin,
            isLoading: controller.isLoading.value,
            gradient: const LinearGradient(
              colors: AppColors.primaryGradientColors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
        ),
        Text(
          'Remember me',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /*Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () => context.push('/forgot-password'),
      child: Text(
        'Forgot Password?',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.medicalBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }*/

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => Get.offNamed(AppPage.signUpScreen),
          child: Text(
            'Sign Up',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.medicalBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

/*  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }*/

  Future<void> _handleLogin() async {
    // if (!_formKey.currentState!.validate()) return;

    try {
      controller.signIn();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  /*void _navigateToHome() {
    if (_selectedUserType == UserType.patient) {
      context.go('/bookingCalender'); // patient/home
    } else {
      context.go('/therapistSearch'); //therapist/dashboard
    }
  }*/

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
