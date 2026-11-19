import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:physio_connect/route/route_guards.dart';
import 'package:physio_connect/services/letter_head_service.dart';
import 'package:physio_connect/ui/dashboard/dashboard_binding.dart';
import 'package:physio_connect/ui/dashboard/doctor_dashboard_screen.dart';
import 'package:physio_connect/ui/signUp/signup_binding.dart';

import '../ui/book_session/booking_session_bindings.dart';
import '../ui/book_session/confirmation_screen.dart';
import '../ui/book_session/date_time_screen.dart';
import '../ui/book_session/payment_screen.dart';
import '../ui/book_session/select_doctor_screen.dart';
import '../ui/book_session/service_area_screen.dart';
import '../ui/book_session/service_city_screen.dart';
import '../ui/book_session/session_type_screen.dart';
import '../ui/booking_history/booking_detail_route.dart';
import '../ui/booking_history/booking_history_screen.dart';
import '../ui/dashboard/dashboard_bottom_navigation_screen.dart';
import '../ui/doctors/doctor_directory_bindings.dart';
import '../ui/doctors/doctor_list_screen.dart';
import '../ui/doctors/doctor_profile_screen.dart';
import '../ui/logIn/login_binding.dart';
import '../ui/logIn/login_screen.dart';
import '../ui/profile/profile_about_us_screen.dart';
import '../ui/signUp/signup_screen.dart';
import '../ui/splash_binding.dart';
import '../ui/splash_screen.dart';
import '../ui/generate_prescription/generate_prescription_screen.dart';
import '../ui/manage_time_slot/manage_time_slot_screen.dart';

class AppPage {
  AppPage._();

  static const splashScreen = '/splash';
  static const loginScreen = '/login';
  static const signUpScreen = '/register';
  static const dashboardScreen = '/dashboard';
  static const doctorDashboardScreen = '/doctorDashboard';
  static const selectServiceCity = '/selectServiceCity';
  static const selectServiceArea = '/selectServiceArea';
  static const selectDoctor = '/selectDoctor';
  static const selectSessionType = '/selectSessionType';
  static const selectDateAndTime = '/selectDateAndTime';
  static const performPayment = '/performPayment';
  static const bookingConfirmation = '/bookingConfirmation';
  static const String bookingHistory = '/booking-history';
  static const String bookingDetail = '/booking-detail';
  static const String userProfile = '/user-profile';
  static const String doctors = '/doctors';
  static const String doctorProfile = '/doctor-profile';
  static const String generatePrescription = '/generate-prescription';
  static const String manageTimeSlot = '/manage-time-slot';

  /// URL of one booking, e.g. `/booking-detail?id=42` (refresh-safe on web).
  static String bookingDetailFor(int bookingId) =>
      '$bookingDetail?id=$bookingId';

  /// URL of one doctor profile, e.g. `/doctor-profile?id=7`.
  static String doctorProfileFor(int doctorId) => '$doctorProfile?id=$doctorId';

  /// Shown for any URL that is not a known page; the splash screen then
  /// sends the visitor to the dashboard or the login page.
  static final unknownRoute = GetPage(
    name: '/not-found',
    page: () => const SplashScreen(),
    binding: SplashBinding(),
  );

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
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppPage.doctorDashboardScreen,
      page: () => DoctorDashboardScreen(),
      binding: DashboardBinding(),
      middlewares: [AuthGuard()],
    ),

    GetPage(
      name: AppPage.selectServiceCity,
      page: () => const ServiceCityScreen(),
      binding: BookingSessionBindings(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppPage.selectServiceArea,
      page: () => const ServiceAreaScreen(),
      binding: BookingSessionBindings(),
      middlewares: [AuthGuard(), BookingStepGuard((c) => c.selectedCity.value != null)],
    ),
    GetPage(
      name: AppPage.selectDoctor,
      page: () => const SelectDoctorScreen(),
      binding: BookingSessionBindings(),
      middlewares: [AuthGuard(), BookingStepGuard((c) => c.selectedArea.value != null)],
    ),
    GetPage(
      name: AppPage.selectSessionType,
      page: () => SessionTypeScreen(),
      binding: BookingSessionBindings(),
      middlewares: [AuthGuard(), BookingStepGuard((c) => c.selectedDoctor.value != null)],
    ),
    GetPage(
      name: AppPage.selectDateAndTime,
      page: () => DateTimeScreen(),
      binding: BookingSessionBindings(),
      middlewares: [AuthGuard(), BookingStepGuard((c) => c.selectedSessionType.value != null)],
    ),
    GetPage(
      name: AppPage.performPayment,
      page: () => PaymentScreen(),
      binding: BookingSessionBindings(),
      middlewares: [AuthGuard(), BookingStepGuard(
          (c) =>
              c.selectedSessionType.value != null &&
              c.appointmentDates.isNotEmpty,
        )],
    ),
    GetPage(
      name: AppPage.bookingConfirmation,
      page: () => ConfirmationScreen(),
      middlewares: [AuthGuard(), BookingStepGuard((c) => c.bookingsModel.value != null)],
    ),
    GetPage(
      name: AppPage.bookingHistory, page: () => BookingHistoryScreen(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppPage.bookingDetail,
      page: () => const BookingDetailRoute(),
      middlewares: [AuthGuard(), RequiresQueryGuard('id')],
    ),
    GetPage(
      name: AppPage.generatePrescription,
      page: () => const GeneratePrescriptionScreen(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppPage.manageTimeSlot,
      page: () => const ManageTimeSlotScreen(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppPage.userProfile, page: () => ProfileAboutUsScreen(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppPage.doctors,
      page: () => const DoctorListScreen(),
      binding: DoctorDirectoryBindings(),
    ),
    GetPage(
      name: AppPage.doctorProfile,
      page: () => const DoctorProfileScreen(),
      binding: DoctorDirectoryBindings(),
      middlewares: [RequiresQueryGuard('id', fallback: AppPage.doctors)],
    ),
  ];
}
// General Physiotherapy
