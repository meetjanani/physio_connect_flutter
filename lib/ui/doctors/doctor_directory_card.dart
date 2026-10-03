import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/ui/doctors/doctor_avatar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

class DoctorDirectoryCard extends StatelessWidget {
  const DoctorDirectoryCard({
    super.key,
    required this.doctor,
    this.coverageLabel = '',
    required this.onTap,
  });

  final DoctorModel doctor;
  final String coverageLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final experience = doctor.experience?.trim() ?? '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            DoctorAvatar(doctor: doctor, size: 64, borderRadius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name?.trim().isNotEmpty == true
                        ? doctor.name!.trim()
                        : 'Physiotherapist',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (doctor.degree?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      doctor.degree!.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (experience.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      experience,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (coverageLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      coverageLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
