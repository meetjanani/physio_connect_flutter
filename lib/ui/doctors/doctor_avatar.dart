import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({
    super.key,
    required this.doctor,
    this.size = 64,
    this.borderRadius = 18,
  });

  final DoctorModel? doctor;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final photo = doctor?.profilePhotoUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
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
                errorWidget: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        doctorInitials(doctor?.name),
        style: GoogleFonts.inter(
          fontSize: size * 0.28,
          fontWeight: FontWeight.w700,
          color: AppColors.medicalBlueDark,
        ),
      ),
    );
  }
}

String doctorInitials(String? name) {
  final nameParts = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty && part.toLowerCase() != 'dr.')
      .toList();
  if (nameParts.isEmpty) return '?';
  return nameParts.map((part) => part[0].toUpperCase()).take(2).join();
}
