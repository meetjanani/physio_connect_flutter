import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/constants.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:intl/intl.dart';

import '../../route/route_module.dart';
import '../../services/booking_payment_flow.dart';
import '../../utils/enum.dart';
import 'booking_controller.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final BookingController controller = Get.find<BookingController>();
  late final BookingPaymentFlow _payment;

  @override
  void initState() {
    super.initState();
    _payment = BookingPaymentFlow(
      bookingIds: () => controller.pendingBookingIds.toList(),
      userId: () => controller.userModelSupabase?.id ?? 0,
      fallbackOrderId: () =>
          controller.createRazorPayOrderModel.value?.orderId,
      onPaid: _onPaid,
      onCheckoutFailed: (failure) async {
        controller.pendingBookingIds.clear();
        controller.paymentFailureMessage.value = failure.message;
        BookingPaymentFlow.snackbar(failure.title, failure.message);
      },
      onCreateFailed: () async {
        try {
          await controller.supabaseController.deleteUnpaidDraftBookings(
            controller.pendingBookingIds.toList(),
          );
        } catch (_) {}
        controller.pendingBookingIds.clear();
      },
    );
  }

  @override
  void dispose() {
    _payment.dispose();
    super.dispose();
  }

  Future<void> _onPaid(PaidPaymentResult paid) async {
    controller.paymentFailureMessage.value = '';
    controller.pendingBookingIds.assignAll(paid.bookingIds);
    final booking = controller.bookingsModel.value;
    if (booking != null && paid.bookingIds.isNotEmpty) {
      booking
        ..id = paid.bookingIds.first
        ..bookingStatus = BookingStatus.confirmed.name
        ..paymentStatus = PaymentStatus.paid.name
        ..paymentId = paid.paymentId
        ..orderId = paid.orderId
        ..signature = paid.signature;
      controller.bookingsModel.refresh();
    }
    controller.pendingBookingIds.clear();
    if (mounted) {
      Get.toNamed(
        AppPage.bookingConfirmation,
        arguments: controller.bookingsModel.value,
      );
    }
  }

  Future<void> _startPayment() async {
    controller.paymentFailureMessage.value = '';
    await _payment.collectPayment(
      createOrder: controller.createPendingBookingBeforePayment,
      description:
          'Payment for ${controller.selectedSessionType.value?.name ?? 'Physiotherapy session'}',
      contact: controller.userModelSupabase?.mobileNumber ?? '',
      busyMessage: 'Preparing your booking…',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');

    return Obx(
      () => PopScope(
      canPop: !_payment.isBusy.value,
      child: Scaffold(
      appBar: commonAppBar('Payment', isBackButtonVisible: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Booking summary card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Summary',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Session info
                        Obx(
                          () => _buildSummaryItem(
                            icon: Icons.spa,
                            title: 'Session Type',
                            value:
                                controller.selectedSessionType.value?.name ??
                                'N/A',
                          ),
                        ),
                        SizedBox(height: 16),
                        Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appointments (${controller.appointmentDates.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...controller.appointmentDates.map(
                                (date) => Text(
                                  DateFormat('dd-MMM-yyyy').format(date),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Date info
                        Obx(
                          () => _buildSummaryItem(
                            icon: Icons.calendar_today,
                            title: 'Date',
                            value: dateFormatter.format(
                              controller.selectedDate.value,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Time info
                        Obx(
                          () => _buildSummaryItem(
                            icon: Icons.access_time,
                            title: 'Time',
                            value:
                                controller.selectedTimeSlot.value?.time ??
                                'N/A',
                          ),
                        ),
                        SizedBox(height: 16),

                        // Duration info
                        Obx(
                          () => _buildSummaryItem(
                            icon: Icons.timelapse,
                            title: 'Duration',
                            value:
                                '${controller.selectedSessionType.value?.duration ?? 0}',
                          ),
                        ),

                        SizedBox(height: 24),
                        Divider(),
                        SizedBox(height: 24),

                        // Price info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Obx(
                              () => Text(
                                '₹${((controller.selectedSessionType.value?.price ?? 0) * controller.appointmentDates.length).toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.medicalBlueDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Payment methods
                  Text(
                    'Payment Method',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Razorpay method
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.medicalBlue,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.medicalBlueLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.network(
                            'https://razorpay.com/assets/razorpay-logo.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.payment,
                              color: AppColors.medicalBlueDark,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Razorpay',
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pay via Credit/Debit Card, UPI, or Net Banking',
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle, color: AppColors.medicalBlue),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.medicalBlueLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.medicalBlueLight),
                    ),
                    child: Text(
                      'Cancellation policy: Free cancel if more than '
                      '$FREE_CANCEL_HOURS hours before the session. '
                      'If the doctor cancels, you get a full refund. '
                      'Support: $SUPPORT_EMAIL',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom button
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Obx(
                () => controller.isLoading.value == true
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.medicalBlue,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller
                              .paymentFailureMessage
                              .value
                              .isNotEmpty) ...[
                            Text(
                              controller.paymentFailureMessage.value,
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.error,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          ElevatedButton(
                            onPressed: _payment.isBusy.value ? null : _startPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.medicalBlue,
                              foregroundColor: AppColors.textOnDark,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Pay Now',
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 4),
          ],
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.medicalBlueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.medicalBlueDark, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
