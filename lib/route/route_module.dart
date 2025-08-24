import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:physio_connect/ui/dashboard/dashboard_binding.dart';
import 'package:physio_connect/ui/signUp/signup_binding.dart';

import '../ui/book_session/booking_session_bindings.dart';
import '../ui/book_session/confirmation_screen.dart';
import '../ui/book_session/date_time_screen.dart';
import '../ui/book_session/payment_screen.dart';
import '../ui/book_session/session_type_screen.dart';
import '../ui/booking_history/booking_detail_screen.dart';
import '../ui/booking_history/booking_history_screen.dart';
import '../ui/dashboard/dashboard_bottom_navigation_screen.dart';
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
  static const selectSessionType = '/selectSessionType';
  static const selectDateAndTime = '/selectDateAndTime';
  static const performPayment = '/performPayment';
  static const bookingConfirmation = '/bookingConfirmation';
  static const String bookingHistory = '/booking-history';
  static const String bookingDetail = '/booking-detail';

  static final routes = [
    GetPage(
      name: AppPage.splashScreen,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),

    //Auth
    GetPage(
      name: AppPage.loginScreen,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppPage.signUpScreen,
      page: () => SignupScreen(),
      binding: SignUpBinding(),
    ),
    GetPage(
      name: AppPage.dashboardScreen,
      page: () => DashboardBottomNavigationScreen(currentIndex: 0),
      binding: DashboardBinding(),
    ),

    GetPage(
      name: AppPage.selectSessionType,
      page: () => SessionTypeScreen(),
      binding: BookingSessionBindings(),
    ),
    GetPage(
      name: AppPage.selectDateAndTime,
      page: () => DateTimeScreen(),
      binding: BookingSessionBindings(),
    ),
    GetPage(
      name: AppPage.performPayment,
      page: () => PaymentScreen(),
      binding: BookingSessionBindings(),
    ),
    GetPage(
      name: AppPage.bookingConfirmation,
      page: () => ConfirmationScreen(),
    ),
    GetPage(name: AppPage.bookingHistory, page: () => BookingHistoryScreen()),
    GetPage(name: AppPage.bookingDetail, page: () => BookingDetailScreen()),
  ];
}
