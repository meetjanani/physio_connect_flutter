import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/model/doctor_model.dart';
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
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

      final query = searchController.text.trim().toLowerCase();
      final filteredAreas = controller.serviceAreas.where((area) {
        if (query.isEmpty) return true;
        final doctor = controller.areaDoctorByAreaId[area.id];
        return area.areaName.toLowerCase().contains(query) ||
            area.description.toLowerCase().contains(query) ||
            (doctor?.name?.toLowerCase().contains(query) ?? false) ||
            (doctor?.degree?.toLowerCase().contains(query) ?? false);
      }).toList();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.serviceAreas.length == 1 &&
            controller.selectedArea.value == null) {
          controller.selectedArea.value = controller.serviceAreas.first;
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search area or doctor',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.medicalBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        'Each area is served by one assigned physiotherapist.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: controller.serviceAreas.isEmpty
                            ? _buildEmptyState()
                            : filteredAreas.isEmpty
                            ? _buildNoSearchResults()
                            : ListView.separated(
                                itemCount: filteredAreas.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final area = filteredAreas[index];
                                  final doctor =
                                      controller.areaDoctorByAreaId[area.id];
                                  final isSelected =
                                      controller.selectedArea.value?.id ==
                                      area.id;
                                  final doctorName =
                                      doctor?.name?.trim().isNotEmpty == true
                                      ? doctor!.name!.trim()
                                      : 'Doctor to be assigned';
                                  final doctorDegree =
                                      doctor?.degree?.trim() ?? '';
                                  return InkWell(
                                    onTap: () async {
                                      controller.selectedArea.value = area;
                                      final assigned =
                                          doctor ??
                                          await controller.supabaseController
                                              .getDoctorById(
                                                area.doctorId ?? 0,
                                              );
                                      controller.selectedDoctor.value =
                                          assigned;
                                      await controller.getSessionTypesMaster();
                                      Get.back();
                                      Get.back();
                                      // Get.toNamed(AppPage.selectDoctor);
                                      Get.toNamed(AppPage.selectSessionType);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.medicalBlueLight
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.medicalBlue
                                              : AppColors.border,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: AppColors.shadowLight,
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                _DoctorAvatar(doctor: doctor),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        area.areaName,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppColors
                                                                  .textPrimary,
                                                            ),
                                                      ),
                                                      if (area.description
                                                          .trim()
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          area.description,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 13,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                      Text.rich(
                                                        TextSpan(
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 13,
                                                                color: AppColors
                                                                    .textPrimary,
                                                              ),
                                                          children: [
                                                            TextSpan(
                                                              text: doctorName,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            if (doctorDegree
                                                                .isNotEmpty)
                                                              TextSpan(
                                                                text:
                                                                    '  ·  $doctorDegree',
                                                                style: const TextStyle(
                                                                  color: AppColors
                                                                      .textSecondary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Icon(
                                                    Icons
                                                        .arrow_forward_ios_rounded,
                                                    size: 16,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
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
        border: Border.all(color: AppColors.medicalBlue.withValues(alpha: 0.2)),
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

  Widget _buildNoSearchResults() {
    return Center(
      child: Text(
        'No service areas match your search.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.doctor});

  final DoctorModel? doctor;

  @override
  Widget build(BuildContext context) {
    final photo = doctor?.profilePhotoUrl?.trim() ?? '';
    final nameParts = (doctor?.name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty && part.toLowerCase() != 'dr.')
        .toList();
    final initials = nameParts.isEmpty
        ? '?'
        : nameParts.map((part) => part[0].toUpperCase()).join();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 82,
        constraints: const BoxConstraints(minHeight: 56),
        color: AppColors.medicalBlueLight,
        child: photo.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photo,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => _initials(initials),
              )
            : _initials(initials),
      ),
    );
  }

  Widget _initials(String initial) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.medicalBlueDark,
        ),
      ),
    );
  }
}
