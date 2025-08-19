// lib/ui/booking/session_type_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../../model/session_type_model.dart';
import 'booking_controller.dart';
import 'date_time_screen.dart';

class SessionTypeScreen extends StatelessWidget {
  final BookingController controller = Get.put(BookingController());

  SessionTypeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Session Type',
          style: GoogleFonts.inter(
            textStyle: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        backgroundColor: AppColors.therapyPurple,
        foregroundColor: Colors.white,
      ),
      body: Obx(() => controller.isLoading.value
          ? Center(child: CircularProgressIndicator())
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
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ...controller.sessionTypes.map((session) => _buildSessionCard(session)),
              ],
            )),
    );
  }

  Widget _buildSessionCard(SessionTypeModel session) {
    return GestureDetector(
      onTap: () {
        controller.selectedSessionType.value = session;
        Get.to(() => DateTimeScreen());
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              session.image != null
                  ? Image.network(
                      session.image!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 160,
                        color: AppColors.therapyPurple.withOpacity(0.3),
                        child: Icon(
                          Icons.healing,
                          size: 60,
                          color: AppColors.therapyPurple,
                        ),
                      ),
                    )
                  : Container(
                      height: 160,
                      color: AppColors.therapyPurple.withOpacity(0.3),
                      child: Icon(
                        Icons.healing,
                        size: 60,
                        color: AppColors.therapyPurple,
                      ),
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
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.wellnessGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${session.durationMinutes} min',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.wellnessGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (session.description != null)
                      Text(
                        session.description!,
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${session.price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.therapyPurple,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.therapyPurple,
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