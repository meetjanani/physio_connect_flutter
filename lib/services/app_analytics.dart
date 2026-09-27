import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper so product funnels stay in one place.
class AppAnalytics {
  AppAnalytics._();
  static final AppAnalytics instance = AppAnalytics._();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  Future<void> init() async {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    await _analytics.logEvent(name: name, parameters: params);
  }

  Future<void> bookingStarted() => logEvent('booking_started');
  Future<void> paymentSuccess({required int amount}) =>
      logEvent('payment_success', {'amount': amount});
  Future<void> bookingCompleted() => logEvent('booking_completed');
}
