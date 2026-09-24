import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import 'booking_controller.dart';

class ServiceCityScreen extends StatefulWidget {
  const ServiceCityScreen({super.key});

  @override
  State<ServiceCityScreen> createState() => _ServiceCityScreenState();
}

class _ServiceCityScreenState extends State<ServiceCityScreen> {
  final BookingController controller = Get.find<BookingController>();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.clearCoverageSelection();
    controller.loadServiceCities();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.serviceCities.length == 1 &&
          controller.selectedCity.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.selectedCity.value = controller.serviceCities.first;
          controller.loadServiceAreasForSelectedCity();
          Get.toNamed(AppPage.selectServiceArea);
        });
      }

      final filteredCities = controller.serviceCities.where((city) {
        final query = searchController.text.trim().toLowerCase();
        if (query.isEmpty) return true;
        return city.cityStateName.toLowerCase().contains(query);
      }).toList();

      return Scaffold(
        appBar: commonAppBar('Select City', isBackButtonVisible: true),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.backgroundGradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: AppColors.medicalBlueDark,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'City / State',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search city',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.medicalBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Choose your preferred city',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredCities.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                itemCount: filteredCities.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final city = filteredCities[index];
                                  final isSelected =
                                      controller.selectedCity.value?.id ==
                                      city.id;
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        controller.selectedCity.value = city;
                                        controller.selectedArea.value = null;
                                        controller.selectedDoctor.value = null;
                                        await controller
                                            .loadServiceAreasForSelectedCity();
                                        if(controller.serviceAreas.value.isNotEmpty) {
                                          Get.toNamed(AppPage.selectServiceArea);
                                        } else {
                                          Get.snackbar(
                                            'No Service Areas',
                                            'No service areas available for the selected city.',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: AppColors.surface,
                                            colorText: AppColors.textPrimary,
                                          );
                                        }
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
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
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
                                                color: isSelected
                                                    ? AppColors.medicalBlue
                                                    : AppColors
                                                          .wellnessGreenLight,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                Icons.location_city_rounded,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors
                                                          .wellnessGreenDark,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                city.cityStateName,
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 18),
          Text(
            'No city available right now',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Don’t see your city? We currently serve selected areas and are expanding.',
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
