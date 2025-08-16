
import 'package:get/get_navigation/src/routes/get_route.dart';

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

    /*//Auth
    GetPage(
        name: AppRoute.login,
        page: () => const LoginScreen(),
        binding: LoginBinding()),
    GetPage(
        name: AppRoute.register,
        page: () => RegisterScreen(),
        binding: RegisterBinding()),*/
  ];
}