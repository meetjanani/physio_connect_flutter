// lib/ui/booking/confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import 'booking_controller.dart';

class ConfirmationScreen extends StatelessWidget {
  final BookingController controller = Get.find<BookingController>();

  ConfirmationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(AppPage.dashboardScreen);
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        // Success animation
                        Lottie.network(
                          'https://assets3.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                          repeat: true,
                        ),
                        SizedBox(height: 16),
                        // Success text
                        Text(
                          'Booking Confirmed!',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Your physiotherapy session has been successfully booked.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),

                        SizedBox(height: 36),

                        // Booking details
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
                            children: [
                              // Session type
                              Obx(() => _buildConfirmationItem(
                                title: 'Session Type',
                                value: controller.selectedSessionType.value?.name ?? 'N/A',
                                icon: Icons.spa,
                              )),

                              SizedBox(height: 16),
                              Divider(),
                              SizedBox(height: 16),

                              // Date
                              Obx(() => _buildConfirmationItem(
                                title: 'Date',
                                value: dateFormatter.format(controller.selectedDate.value),
                                icon: Icons.calendar_today,
                              )),

                              SizedBox(height: 16),
                              Divider(),
                              SizedBox(height: 16),

                              // Time
                              Obx(() => _buildConfirmationItem(
                                title: 'Time',
                                value: controller.selectedTimeSlot.value?.time ?? "",
                                icon: Icons.access_time,
                              )),

                              SizedBox(height: 16),
                              Divider(),
                              SizedBox(height: 16),

                              // Payment
                              _buildConfirmationItem(
                                title: 'Payment Status',
                                value: controller.bookingsModel.value?.paymentStatus ?? 'N/A',
                                valueColor: AppColors.wellnessGreen,
                                icon: Icons.payment,
                                iconBgColor: AppColors.wellnessGreenLight,
                                iconColor: AppColors.wellnessGreenDark,
                              ),

                              SizedBox(height: 16),
                              Divider(),
                              SizedBox(height: 16),
                              // Reference ID
                              Obx(() => _buildConfirmationItem(
                                title: 'Transaction ID',
                                value: controller.bookingsModel.value?.paymentId ?? 'N/A',
                                icon: Icons.receipt_long,
                              )),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // Note
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.wellnessGreenLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.wellnessGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.wellnessGreenDark,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Please get ready 10 minutes before your appointment time',
                                  style: GoogleFonts.inter(
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Back to home button
                ElevatedButton(
                  onPressed: () {
                    Get.offAndToNamed(AppPage.dashboardScreen);
                  },
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
                    'Back to Home',
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
      ),
    );
  }

  Widget _buildConfirmationItem({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
    Color? iconBgColor,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor ?? AppColors.medicalBlueLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.medicalBlueDark,
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
                    color: valueColor ?? AppColors.textPrimary,
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