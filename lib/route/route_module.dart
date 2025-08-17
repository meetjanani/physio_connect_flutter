
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:physio_connect/ui/signUp/signup_binding.dart';

import '../ui/logIn/login_binding.dart';
import '../ui/logIn/login_screen.dart';
import '../ui/signUp/signup_screen.dart';
import '../ui/splash_binding.dart';
import '../ui/splash_screen.dart';

class AppPage {
  AppPage._();

  static const splashScreen = '/splash';
  static const loginScreen = '/login';
  static const signUpScreen = '/register';
  static const dashboardScreen = '/dashboard';

  static final routes = [
    GetPage(
        name: AppPage.splashScreen,
        page: () => const SplashScreen(),
        binding: SplashBinding()),

    //Auth
    GetPage(
        name: AppPage.loginScreen,
        page: () => const LoginScreen(),
        binding: LoginBinding()),
    GetPage(
        name: AppPage.signUpScreen,
        page: () => SignupScreen(),
        binding: SignUpBinding()),
    GetPage(
        name: AppPage.dashboardScreen,
        page: () => SignupScreen(),
        binding: SignUpBinding()),
  ];
}