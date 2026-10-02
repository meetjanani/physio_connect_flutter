import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/book_session/booking_controller.dart';
import '../utils/theme/app_colors.dart';
import '../utils/theme/app_spacing.dart';

/// Shared session + coverage summary used across the booking flow.
class SessionTypeInfo extends StatelessWidget {
  const SessionTypeInfo({
    super.key,
    this.showCoverage = true,
    this.margin,
  });

  final bool showCoverage;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();

    return Obx(() {
      final session = controller.selectedSessionType.value;
      final city = controller.selectedCity.value?.cityStateName ?? 'City';
      final area = controller.selectedArea.value?.areaName ?? 'Area';
      final doctor = controller.selectedDoctor.value?.name ?? 'Doctor';
      final sessionName = session?.name ?? 'Selected Session';
      final duration = session?.duration ?? '—';
      final price = session?.price ?? 0;

      return Container(
        margin: margin,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCoverage) ...[
              Text(
                'Coverage',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: AppColors.medicalBlueDark,
                ),
              ),
              const SizedBox(height: 6),
              _CoverageTrail(city: city, area: area, doctor: doctor),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.medicalBlueLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: AppColors.medicalBlueDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session type',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        sessionName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            label: duration,
                          ),
                          _MetaChip(
                            icon: Icons.currency_rupee_rounded,
                            label: price.toStringAsFixed(0),
                            emphasize: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _CoverageTrail extends StatelessWidget {
  const _CoverageTrail({
    required this.city,
    required this.area,
    required this.doctor,
  });

  final String city;
  final String area;
  final String doctor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        _TrailChip(label: city, icon: Icons.location_city_rounded),
        const _TrailSeparator(),
        _TrailChip(label: area, icon: Icons.map_outlined),
        const _TrailSeparator(),
        _TrailChip(label: doctor, icon: Icons.person_outline_rounded),
      ],
    );
  }
}

class _TrailChip extends StatelessWidget {
  const _TrailChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final maxChipWidth = MediaQuery.sizeOf(context).width - 56;

    return Container(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.medicalBlueLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 12, color: AppColors.medicalBlueDark),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.medicalBlueDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailSeparator extends StatelessWidget {
  const _TrailSeparator();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 14,
      color: AppColors.medicalBlue.withValues(alpha: 0.7),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final bg =
        emphasize ? AppColors.wellnessGreenLight : AppColors.backgroundLight;
    final fg =
        emphasize ? AppColors.wellnessGreenDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: emphasize
              ? AppColors.wellnessGreen.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
