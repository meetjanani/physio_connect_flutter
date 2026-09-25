import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/model/area_model.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import 'booking_controller.dart';

class ServiceAreaScreen extends StatefulWidget {
  const ServiceAreaScreen({super.key});

  @override
  State<ServiceAreaScreen> createState() => _ServiceAreaScreenState();
}

class _ServiceAreaScreenState extends State<ServiceAreaScreen> {
  final BookingController controller = Get.find<BookingController>();

  @override
  void initState() {
    super.initState();
    // if (controller.selectedCity.value != null) {
    //   controller.loadServiceAreasForSelectedCity();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final city = controller.selectedCity.value;

      if (city == null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => Get.toNamed(AppPage.selectServiceCity),
        );
        return const SizedBox.shrink();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.serviceAreas.value.length == 1 &&
            controller.selectedArea.value == null) {
          controller.selectedArea.value = controller.serviceAreas.value.first;
          Get.toNamed(AppPage.selectDoctor);
        }
      });

      return Scaffold(
        appBar: commonAppBar('Select Area', isBackButtonVisible: true),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreadcrumb(city.cityStateName),
                      const SizedBox(height: 18),
                      Text(
                        'Choose a service area',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Only nearby service zones are visible for this city.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: controller.serviceAreas.value.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                itemCount: controller.serviceAreas.value.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final area =
                                      controller.serviceAreas.value[index];
                                  final isSelected =
                                      controller.selectedArea.value?.id ==
                                      area.id;
                                  return InkWell(
                                    onTap: () async {
                                      controller.selectedArea.value = area;
                                      // await controller.loadDoctorsForSelectedArea();
                                      controller.selectedDoctor.value =
                                          await controller.supabaseController
                                              .getDoctorById(
                                                area.doctorId ??
                                                    controller
                                                        .userModelSupabase!
                                                        .doctorId!,
                                              );
                                      await controller.getSessionTypesMaster();
                                      Get.back();
                                      Get.back();
                                      Get.toNamed(AppPage.selectSessionType);
                                    },
                                    borderRadius: BorderRadius.circular(18),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.medicalBlueLight
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(18),
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
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.wellnessGreenLight,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              Icons.map_outlined,
                                              color:
                                                  AppColors.wellnessGreenDark,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  area.areaName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  area.description,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w300,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                // const SizedBox(height: 4),
                                                // Text(
                                                //   area.radiusKm != null
                                                //       ? 'Coverage radius: ${area.radiusKm!.toStringAsFixed(0)} km'
                                                //       : 'Coverage area',
                                                //   style: GoogleFonts.inter(
                                                //     fontSize: 13,
                                                //     color:
                                                //         AppColors.textSecondary,
                                                //   ),
                                                // ),
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

  Widget _buildBreadcrumb(String cityName) {
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
              cityName,
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
          Icon(Icons.map_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 18),
          Text(
            'No active service area found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This city is not currently open for bookings.',
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
