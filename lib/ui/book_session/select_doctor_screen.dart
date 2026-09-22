import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import 'booking_controller.dart';

class SelectDoctorScreen extends StatefulWidget {
  const SelectDoctorScreen({super.key});

  @override
  State<SelectDoctorScreen> createState() => _SelectDoctorScreenState();
}

class _SelectDoctorScreenState extends State<SelectDoctorScreen> {
  final BookingController controller = Get.find<BookingController>();

  @override
  void initState() {
    super.initState();
    if (controller.selectedArea.value != null) {
      controller.loadDoctorsForSelectedArea();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final area = controller.selectedArea.value;
      final city = controller.selectedCity.value;

      if (area == null || city == null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => Get.toNamed(AppPage.selectServiceCity),
        );
        return const SizedBox.shrink();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.areaDoctors.length == 1 &&
            controller.selectedDoctor.value == null) {
          controller.selectedDoctor.value = controller.areaDoctors.first;
          Get.toNamed(AppPage.selectSessionType);
        }
      });

      return Scaffold(
        appBar: commonAppBar('Select Doctor', isBackButtonVisible: true),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreadcrumb(city.cityStateName, area.areaName),
                      const SizedBox(height: 18),
                      Text(
                        'Choose your doctor',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Experienced clinicians serving $area in $city.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: controller.areaDoctors.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                itemCount: controller.areaDoctors.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final doctor = controller.areaDoctors[index];
                                  final isSelected =
                                      controller.selectedDoctor.value?.id ==
                                      doctor.id;
                                  return InkWell(
                                    onTap: () {
                                      controller.selectedDoctor.value = doctor;
                                      Get.toNamed(AppPage.selectSessionType);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.medicalBlueLight
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.medicalBlue
                                              : AppColors.border,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: AppColors.shadowLight,
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 62,
                                            height: 62,
                                            decoration: BoxDecoration(
                                              color: AppColors
                                                  .primaryGradientColors[0]
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            child: Icon(
                                              Icons.person_rounded,
                                              size: 30,
                                              color: AppColors.medicalBlueDark,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doctor.name ?? 'Doctor',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  doctor.degree ??
                                                      'Physiotherapist',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .workspace_premium_rounded,
                                                      size: 16,
                                                      color: AppColors
                                                          .wellnessGreenDark,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        doctor.experience ??
                                                            'Experienced care',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppColors
                                                                  .textPrimary,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 18,
                                            color: AppColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildBreadcrumb(String cityName, String areaName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.medicalBlueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.medicalBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.chevron_right_rounded, color: AppColors.medicalBlueDark),
          Expanded(
            child: Text(
              '$cityName › $areaName',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.medicalBlueDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 18),
          Text(
            'No doctors available in this area',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We will add doctors for this service area soon.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
