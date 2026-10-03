import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/custom_widget/custom_button.dart';
import 'package:physio_connect/custom_widget/physio_progress_bar.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/model/session_type_model.dart';
import 'package:physio_connect/route/route_module.dart';
import 'package:physio_connect/ui/book_session/booking_controller.dart';
import 'package:physio_connect/ui/doctors/doctor_avatar.dart';
import 'package:physio_connect/ui/doctors/doctor_directory_controller.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorDirectoryController controller = DoctorDirectoryController.to;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    var doctorId = 0;
    DoctorModel? preview;
    int? areaId;
    int? cityId;
    if (args is Map) {
      doctorId = (args['doctorId'] as num?)?.toInt() ?? 0;
      final rawPreview = args['preview'];
      if (rawPreview is DoctorModel) preview = rawPreview;
      areaId = (args['areaId'] as num?)?.toInt();
      cityId = (args['cityId'] as num?)?.toInt();
    } else if (args is int) {
      doctorId = args;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.openProfile(
        doctorId: doctorId,
        preview: preview,
        areaId: areaId,
        cityId: cityId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final doctor = controller.profileDoctor.value;
      final title = doctor?.name?.trim().isNotEmpty == true
          ? doctor!.name!.trim()
          : 'Doctor profile';
      return Scaffold(
        appBar: commonAppBar(title, isBackButtonVisible: true),
        body: SafeArea(
          child: controller.isLoadingProfile.value && doctor == null
              ? const Center(
                  child: PhysioProgressBar(
                    card: false,
                    message: 'Loading profile…',
                  ),
                )
              : controller.profileError.value.isNotEmpty && doctor == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      controller.profileError.value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : doctor == null
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                        children: [
                          _header(doctor),
                          const SizedBox(height: 16),
                          _registration(doctor),
                          _about(doctor),
                          _serves(),
                          _treatments(),
                        ],
                      ),
                    ),
                    _bookBar(doctor),
                  ],
                ),
        ),
      );
    });
  }

  Widget _header(DoctorModel doctor) {
    final experience = doctor.experience?.trim() ?? '';
    final degree = doctor.degree?.trim() ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorAvatar(doctor: doctor, size: 96, borderRadius: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name?.trim().isNotEmpty == true
                    ? doctor.name!.trim()
                    : 'Physiotherapist',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (degree.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  degree,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (experience.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.medicalBlueLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    experience,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.medicalBlueDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _registration(DoctorModel doctor) {
    final reg = doctor.drRegNumber?.trim() ?? '';
    if (reg.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 18,
            color: AppColors.wellnessGreenDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reg. no. $reg',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _about(DoctorModel doctor) {
    final bio = doctor.biodata?.trim() ?? '';
    final coverage = controller.profileCoverage;
    final fallback = coverage.isEmpty
        ? 'Home-visit physiotherapist on PhysioConnect.'
        : 'Physiotherapist serving ${coverage.map((c) => c.label).join(', ')}.';
    return _section(
      title: 'About',
      child: Text(
        bio.isNotEmpty ? bio : fallback,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _serves() {
    final coverage = controller.profileCoverage;
    if (coverage.isEmpty) return const SizedBox.shrink();
    return _section(
      title: 'Serves',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: coverage
            .map(
              (item) => Chip(
                label: Text(item.label),
                backgroundColor: AppColors.medicalBlueLight,
                side: BorderSide.none,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.medicalBlueDark,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _treatments() {
    final types = controller.profileSessionTypes;
    if (types.isEmpty) return const SizedBox.shrink();
    return _section(
      title: 'Treatments offered',
      child: Column(
        children: types.map(_treatmentTile).toList(),
      ),
    );
  }

  Widget _treatmentTile(SessionTypeModel type) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (type.duration.trim().isNotEmpty)
                  Text(
                    type.duration,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '₹${type.price}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.medicalBlueDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _bookBar(DoctorModel doctor) {
    final canBook = controller.profileCoverage.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canBook)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Not currently taking visits in published areas.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          CustomButton(
            text: 'Book a visit',
            isLoading: _booking,
            onPressed: canBook && !_booking ? () => _bookVisit(doctor) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _bookVisit(DoctorModel doctor) async {
    final coverage = controller.profileCoverage.toList();
    if (coverage.isEmpty) return;

    DoctorCoverage? selected;
    final preferredAreaId = controller.preferredAreaId.value;
    if (preferredAreaId != null) {
      selected = coverage
          .where((item) => item.area.id == preferredAreaId)
          .firstOrNull;
    }
    selected ??= coverage.length == 1 ? coverage.first : null;
    selected ??= await _pickCoverage(coverage);
    if (selected == null) return;
    final city = selected.city;
    if (city == null) {
      Get.snackbar(
        'There was a problem',
        'This area is not open for booking yet.',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _booking = true);
    try {
      if (!Get.isRegistered<BookingController>()) {
        Get.put(BookingController(), permanent: true);
      }
      await BookingController.to.startSessionBookingForDoctor(
        doctor: doctor,
        area: selected.area,
        city: city,
      );
      Get.toNamed(AppPage.selectSessionType);
    } catch (_) {
      Get.snackbar(
        'There was a problem',
        'Unable to start booking. Please try again.',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  Future<DoctorCoverage?> _pickCoverage(List<DoctorCoverage> coverage) {
    return Get.bottomSheet<DoctorCoverage>(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose an area',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This physiotherapist visits more than one area.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: coverage.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = coverage[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.border),
                    ),
                    title: Text(
                      item.area.areaName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: item.city == null
                        ? null
                        : Text(item.city!.cityStateName),
                    onTap: () => Get.back(result: item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
