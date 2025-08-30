// lib/ui/booking/session_type_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../../model/session_type_model.dart';
import '../../route/route_module.dart';
import '../../utils/cached_network_image.dart';
import 'booking_controller.dart';

class SessionTypeScreen extends StatelessWidget {
  final BookingController controller = Get.put(BookingController());

  SessionTypeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar("Select Session Type", isBackButtonVisible: true),
      body: SafeArea(
        child: Obx(
          () => controller.isLoading.value
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.medicalBlue,
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    Text(
                      'Choose Your Therapy Type',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select the type of session that best fits your needs',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ...controller.sessionTypes
                        .map((sessionType) => _buildSessionCard(sessionType)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(SessionTypeModel session) {
    return GestureDetector(
      onTap: () {
        controller.selectedSessionType.value = session;
        Get.toNamed(AppPage.selectDateAndTime);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  CatchedImageWidget(
                    imageUrl: session.imageUrl,
                    height: 160,
                    width: double.infinity,
                    boxFit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.primaryGradientColors,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            session.name,
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.medicalBlueLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.medicalBlue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            session.duration,
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.medicalBlueDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (session.description != null)
                      Text(
                        session.description,
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on_outlined,
                              size: 20,
                              color: AppColors.medicalBlue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '₹${session.price.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.medicalBlueDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.medicalBlueLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.medicalBlueDark,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}