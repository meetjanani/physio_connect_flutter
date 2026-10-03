import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/custom_widget/physio_progress_bar.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/ui/doctors/doctor_directory_card.dart';
import 'package:physio_connect/ui/doctors/doctor_directory_controller.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final DoctorDirectoryController controller = DoctorDirectoryController.to;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(
        'Our physiotherapists',
        isBackButtonVisible: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Obx(() {
            if (controller.isLoadingCatalog.value && controller.doctors.isEmpty) {
              return const Center(
                child: PhysioProgressBar(
                  card: false,
                  message: 'Loading physiotherapists…',
                ),
              );
            }
            if (controller.catalogError.value.isNotEmpty &&
                controller.doctors.isEmpty) {
              return _message(controller.catalogError.value);
            }
            final doctors = controller.filteredDoctors;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (value) => controller.searchQuery.value = value,
                  decoration: InputDecoration(
                    hintText: 'Search by name, degree, or experience',
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
                  'Meet the clinicians who visit your area',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: doctors.isEmpty
                      ? _message('No physiotherapists match your search.')
                      : RefreshIndicator(
                          onRefresh: controller.loadCatalog,
                          child: ListView.separated(
                            itemCount: doctors.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final doctor = doctors[index];
                              return DoctorDirectoryCard(
                                doctor: doctor,
                                coverageLabel:
                                    controller.firstCoverageLabel(doctor),
                                onTap: () => _openProfile(doctor),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _openProfile(DoctorModel doctor) {
    Get.toNamed(
      AppPage.doctorProfile,
      arguments: {
        'doctorId': doctor.id ?? 0,
        'preview': doctor,
      },
    );
  }

  Widget _message(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
