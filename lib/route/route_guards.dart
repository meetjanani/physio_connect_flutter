import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../ui/book_session/booking_controller.dart';
import 'route_module.dart';

/// Sends signed-out visitors to the login page.
///
/// On the website any route can be opened directly (typed URL, bookmark,
/// refresh), so protected pages must not rely on the splash screen having
/// checked the session first. `main()` waits for Firebase to restore the
/// session on web before the first route is built, so `currentUser` is
/// reliable here.
class AuthGuard extends GetMiddleware {
  AuthGuard() : super(priority: 0);

  @override
  RouteSettings? redirect(String? route) {
    if (FirebaseAuth.instance.currentUser != null) return null;
    return const RouteSettings(name: AppPage.loginScreen);
  }
}

/// Booking steps keep their selections in memory ([BookingController]).
/// After a page refresh or a deep link that state is gone, so restart the
/// booking from the first step instead of showing a broken page.
class BookingStepGuard extends GetMiddleware {
  BookingStepGuard(this.hasRequiredState) : super(priority: 1);

  final bool Function(BookingController controller) hasRequiredState;

  @override
  RouteSettings? redirect(String? route) {
    if (Get.isRegistered<BookingController>() &&
        hasRequiredState(Get.find<BookingController>())) {
      return null;
    }
    return const RouteSettings(name: AppPage.selectServiceCity);
  }
}

/// Detail pages carry the record id in the URL (`?id=123`) so they survive a
/// refresh or a shared link. Without an id there is nothing to show, so go
/// to [fallback] instead.
class RequiresQueryGuard extends GetMiddleware {
  RequiresQueryGuard(this.queryKey, {this.fallback = AppPage.dashboardScreen})
    : super(priority: 1);

  final String queryKey;
  final String fallback;

  @override
  RouteSettings? redirect(String? route) {
    final value = Uri.tryParse(route ?? '')?.queryParameters[queryKey];
    if (value != null && value.trim().isNotEmpty) return null;
    return RouteSettings(name: fallback);
  }
}
