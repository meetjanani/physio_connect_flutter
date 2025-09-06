// lib/ui/booking/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../../utils/enum.dart';
import 'booking_controller.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final BookingController controller = Get.find<BookingController>();
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Store payment data and navigate to confirmation
    controller.razorpayPaymentId.value = response.paymentId!;
    controller.createAppointment(response, PaymentStatus.paid);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar(
      'Payment Failed',
      'Error: ${response.message}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: AppColors.textOnDark,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      'External Wallet',
      'Payment with ${response.walletName}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.medicalBlueLight,
      colorText: AppColors.medicalBlueDark,
    );
  }

  void _openRazorpayCheckout() {
    // For testing purposes, directly call success handler
    // In production, uncomment the Razorpay integration code below
    // controller.razorpayPaymentId.value = "razor_pay_test_payment_id"!;
    // controller.createAppointment(PaymentSuccessResponse("razor_pay_test_payment_id", "order_id", "signature", {}), PaymentStatus.paid);
    // return;

    // rzp_live_RAnbKgZCZa6RZZ
    // rzp_test_R9Cb4IgtUNcVsB
    var options = {
      'key': 'rzp_live_RAnbKgZCZa6RZZ',
      'amount': controller.selectedSessionType.value!.price * 100, // In paise
      'name': 'PhysioConnect',
      'description': 'Payment for ${controller.selectedSessionType.value!.name}',
      'prefill': {
        'contact': controller.userModelSupabase?.mobileNumber ?? '',
        // 'email': controller.userModelSupabase?.email ?? '',  // Recommended to include email
      },
      /*'external': {
        'wallets': ['googlePay']  // Enable Google Pay
      },*/
      'method': {
        'netbanking': false,
        'wallet': true,
        'upi': true,
        'paylater': false,
        'emi': false,
        'card': true  // Only enable card payments
      },
      'config': {
        'display': {
          'hide': [
            {'method': 'netbanking'},
            // {'method': 'wallet', 'except': ['googlePay']},  // Hide all wallets except Google Pay
            // {'method': 'upi', 'flows': ['collect']},  // Hide UPI collect
            {'method': 'paylater'},
            {'method': 'emi'}
          ]
        }
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print(e.toString());
      Get.snackbar(
        'Error',
        'Unable to start payment process',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnDark,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: commonAppBar('Payment', isBackButtonVisible: true),
      body: SafeArea(child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
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
                      Obx(() => _buildSummaryItem(
                        icon: Icons.spa,
                        title: 'Session Type',
                        value: controller.selectedSessionType.value?.name ?? 'N/A',
                      )),
                      SizedBox(height: 16),

                      // Date info
                      Obx(() => _buildSummaryItem(
                        icon: Icons.calendar_today,
                        title: 'Date',
                        value: dateFormatter.format(controller.selectedDate.value),
                      )),
                      SizedBox(height: 16),

                      // Time info
                      Obx(() => _buildSummaryItem(
                        icon: Icons.access_time,
                        title: 'Time',
                        value: controller.selectedTimeSlot.value?.time ?? 'N/A',
                      )),
                      SizedBox(height: 16),

                      // Duration info
                      Obx(() => _buildSummaryItem(
                        icon: Icons.timelapse,
                        title: 'Duration',
                        value: '${controller.selectedSessionType.value?.duration ?? 0}',
                      )),

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
                          Obx(() => Text(
                            '₹${controller.selectedSessionType.value?.price.toStringAsFixed(0) ?? 0}',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.medicalBlueDark,
                              ),
                            ),
                          )),
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
                      Icon(
                        Icons.check_circle,
                        color: AppColors.medicalBlue,
                      ),
                    ],
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
            child: Obx(() =>
            controller.isLoading.value == true ? Center(
              child: CircularProgressIndicator(
                color: AppColors.medicalBlue,
              ),
            ) : ElevatedButton(
              onPressed: _openRazorpayCheckout,
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
            )),
          ),
          SizedBox(height: 4,)
        ],
      )),
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
          child: Icon(
            icon,
            color: AppColors.medicalBlueDark,
            size: 20,
          ),
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