import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../model/bookings_model.dart';
import '../model/create_razorpay_order_model.dart';
import '../services/app_analytics.dart';
import '../services/appointment_reminder_service.dart';
import '../supabase/supabase_controller.dart';
import '../utils/theme/app_colors.dart';
import 'razorpay_checkout.dart';

class PaidPaymentResult {
  PaidPaymentResult({
    required this.bookingIds,
    this.paymentId,
    this.orderId,
    this.signature,
    this.alreadyPaid = false,
  });

  final List<int> bookingIds;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final bool alreadyPaid;
}

/// Checkout, verify, doctor notify, analytics, and reminders after a paid booking.
class BookingPaymentFlow {
  BookingPaymentFlow({
    required this.bookingIds,
    required this.userId,
    required this.onPaid,
    required this.onCheckoutFailed,
    this.fallbackOrderId,
    this.onVerifyFailed,
    this.onCreateFailed,
    this.deleteDraftsIfNoPaymentId = true,
  }) {
    _checkout = RazorpayCheckout(
      onSuccess: _onSuccess,
      onError: _onError,
      onExternalWallet: _onExternalWallet,
    );
  }

  final List<int> Function() bookingIds;
  final int Function() userId;
  final String? Function()? fallbackOrderId;
  final Future<void> Function(PaidPaymentResult paid) onPaid;
  final Future<void> Function(RazorpayFailureDetails failure) onCheckoutFailed;
  final Future<void> Function()? onVerifyFailed;
  final Future<void> Function()? onCreateFailed;
  final bool deleteDraftsIfNoPaymentId;

  final _supabase = SupabaseController.to;
  late final RazorpayCheckout _checkout;
  final isBusy = false.obs;
  bool _busyDialogOpen = false;
  bool _disposed = false;
  CreateRazorPayOrderModel? _lastOrder;

  void dispose() {
    _disposed = true;
    _checkout.dispose();
  }

  String? _orderId(String? fromRazorpay) {
    final id = fromRazorpay?.trim();
    if (id != null && id.isNotEmpty) return id;
    final saved = _lastOrder?.orderId.trim();
    if (saved != null && saved.isNotEmpty) return saved;
    return fallbackOrderId?.call()?.trim();
  }

  Future<void> collectPayment({
    required Future<CreateRazorPayOrderModel?> Function() createOrder,
    required String description,
    required String contact,
    String busyMessage = 'Preparing your payment…',
  }) async {
    if (isBusy.value || _disposed) return;
    showBusy(busyMessage);
    try {
      final order = await createOrder();
      if (_disposed) return;
      if (order == null || !order.hasOrder || order.keyId.trim().isEmpty) {
        hideBusy();
        snackbar('Payment failed', 'Unable to start payment. Please try again.');
        return;
      }
      _lastOrder = order;
      // Close the Flutter dialog first. Opening Razorpay while a Get.dialog
      // is still on the stack (or popping with Get.back) breaks checkout.
      hideBusy();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (_disposed) return;
      _checkout.open(
        order: order,
        description: description,
        contact: contact,
      );
    } catch (_) {
      hideBusy();
      await onCreateFailed?.call();
      snackbar('Payment failed', 'Unable to start payment process');
    }
  }

  void showBusy(String message) {
    if (isBusy.value) return;
    isBusy.value = true;
    _busyDialogOpen = true;
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.medicalBlue),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void hideBusy() {
    isBusy.value = false;
    if (!_busyDialogOpen) return;
    _busyDialogOpen = false;
    // Only pop the loading dialog — never the booking/payment page.
    if (Get.isDialogOpen == true && Get.overlayContext != null) {
      Navigator.of(Get.overlayContext!, rootNavigator: true).pop();
    }
  }

  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    showBusy('Confirming your payment…');
    try {
      final ids = bookingIds();
      final result = await _supabase.callVerifyRazorPayPaymentForBookings(
        bookingIds: ids,
        userId: userId(),
        razorpayOrderId: _orderId(response.orderId),
        razorpayPaymentId: response.paymentId,
        razorpaySignature: response.signature,
      );
      if (result?.success == true) {
        await _completePaid(
          PaidPaymentResult(
            bookingIds: ids,
            paymentId: response.paymentId,
            orderId: _orderId(response.orderId),
            signature: response.signature,
            alreadyPaid: result?.alreadyPaid == true,
          ),
        );
        return;
      }
      hideBusy();
      await onVerifyFailed?.call();
      snackbar(
        'Payment verification failed',
        result?.error ?? 'Payment could not be confirmed. Please try again.',
      );
    } catch (_) {
      hideBusy();
      snackbar(
        'Payment verification failed',
        'Something went wrong while confirming payment. Please try again.',
      );
    }
  }

  Future<void> _onError(RazorpayFailureDetails failure) async {
    showBusy('Updating payment status…');
    try {
      final ids = bookingIds();
      final orderId = _orderId(failure.orderId);
      final result = await _supabase.callVerifyRazorPayPaymentForBookings(
        bookingIds: ids,
        userId: userId(),
        razorpayOrderId: orderId,
        razorpayPaymentId: failure.paymentId,
        razorpaySignature: null,
        failureReason: failure.message,
        failureCode: failure.code,
        failureCause: failure.reason,
      );
      if (result?.success == true) {
        hideBusy();
        await _completePaid(
          PaidPaymentResult(
            bookingIds: ids,
            paymentId: failure.paymentId,
            orderId: orderId,
            alreadyPaid: result?.alreadyPaid == true,
          ),
        );
        return;
      }
      if (deleteDraftsIfNoPaymentId && (failure.paymentId ?? '').isEmpty) {
        await _deleteUnpaidDrafts(ids);
      }
      hideBusy();
      await onCheckoutFailed(failure);
    } catch (_) {
      hideBusy();
      await onCheckoutFailed(failure);
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      'External Wallet',
      'Payment with ${response.walletName}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.medicalBlueLight,
      colorText: AppColors.medicalBlueDark,
    );
  }

  Future<void> _completePaid(PaidPaymentResult paid) async {
    final bookings = <BookingsModel>[];
    for (final id in paid.bookingIds) {
      try {
        final booking = await _supabase.getBookingById(id.toString());
        if (booking != null) bookings.add(booking);
      } catch (_) {}
    }
    if (!paid.alreadyPaid) {
      await _notifyDoctor(bookings);
    }
    await _logPaymentAnalytics(bookings);
    await _scheduleReminders(bookings);
    hideBusy();
    await onPaid(paid);
  }

  Future<void> _notifyDoctor(List<BookingsModel> bookings) async {
    if (bookings.isEmpty) return;
    try {
      final booking = bookings.first;
      var doctorUserId = booking.doctorId;
      var patientName = 'A patient';
      var sessionName = 'a session';
      var whenLabel = booking.bookingDate;
      var slotTime = '';
      try {
        final doctorUser = booking.aDoctor().userId ?? 0;
        if (doctorUser > 0) doctorUserId = doctorUser;
        patientName = booking.aPatient().name ?? patientName;
        sessionName = booking.aSessionType().name;
        slotTime = booking.aTimeslot().time;
        final parsed = DateTime.tryParse(booking.bookingDate);
        if (parsed != null) {
          whenLabel = DateFormat('MMM d, yyyy').format(parsed);
        }
      } catch (_) {}
      if (doctorUserId <= 0) return;

      final extra = bookings.length > 1
          ? '${bookings.length} sessions starting $whenLabel'
          : whenLabel;
      final timePart = slotTime.isEmpty ? '' : ' at $slotTime';
      await _supabase.sentNotification(
        doctorUserId,
        'Booking confirmed',
        '$patientName booked $sessionName for $extra$timePart.',
      );
    } catch (_) {}
  }

  Future<void> _logPaymentAnalytics(List<BookingsModel> bookings) async {
    try {
      final amount = bookings.fold<int>(0, (sum, booking) => sum + booking.price);
      await AppAnalytics.instance.paymentSuccess(amount: amount);
    } catch (_) {}
  }

  Future<void> _scheduleReminders(List<BookingsModel> bookings) async {
    for (final booking in bookings) {
      try {
        final date = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
        var slotTime = '09:00';
        var sessionName = 'Physio session';
        try {
          slotTime = booking.aTimeslot().time;
          sessionName = booking.aSessionType().name;
        } catch (_) {}
        await AppointmentReminderService.instance.scheduleSessionReminders(
          bookingId: booking.id,
          sessionStart: _combineDateAndSlot(date, slotTime),
          sessionLabel: sessionName,
        );
      } catch (_) {}
    }
  }

  DateTime _combineDateAndSlot(DateTime date, String slotTime) {
    final cleaned = slotTime.trim().toUpperCase();
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?').firstMatch(cleaned);
    var hour = 9;
    var minute = 0;
    if (match != null) {
      hour = int.tryParse(match.group(1) ?? '9') ?? 9;
      minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final ampm = match.group(3);
      if (ampm == 'PM' && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _deleteUnpaidDrafts(List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      await _supabase.deleteUnpaidDraftBookings(ids);
    } catch (_) {}
  }

  static void snackbar(String title, String message, {bool success = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: success ? AppColors.wellnessGreen : AppColors.error,
      colorText: AppColors.textOnDark,
    );
  }
}
