import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/time_slots_model.dart';
import '../utils/theme/app_colors.dart';

/// Shared timeslot grid: occupied slots are red and unselectable.
class TimeSlotChipGrid extends StatelessWidget {
  const TimeSlotChipGrid({
    super.key,
    required this.slots,
    required this.onSelect,
    this.selectedId,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  final List<TimeSlotModel> slots;
  final int? selectedId;
  final ValueChanged<TimeSlotModel> onSelect;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      key: ValueKey('slots_$selectedId'),
      shrinkWrap: shrinkWrap,
      physics: physics,
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.35,
      children: slots.map((slot) {
        final isBooked = slot.isBooked ?? false;
        final isSelected = selectedId != null && selectedId == slot.id;
        return _TimeSlotChip(
          slot: slot,
          isBooked: isBooked,
          isSelected: isSelected,
          onTap: isBooked ? null : () => onSelect(slot),
        );
      }).toList(),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.slot,
    required this.isBooked,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlotModel slot;
  final bool isBooked;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color text;

    if (isBooked) {
      bg = AppColors.errorLight;
      border = AppColors.error.withValues(alpha: 0.45);
      text = AppColors.errorDark;
    } else if (isSelected) {
      bg = AppColors.medicalBlue;
      border = AppColors.medicalBlueDark;
      text = AppColors.textOnDark;
    } else {
      bg = AppColors.surface;
      border = AppColors.border;
      text = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: isSelected ? 1.5 : 1),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.medicalBlue.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          slot.time,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            height: 1.2,
            color: text,
            decoration: isBooked ? TextDecoration.lineThrough : null,
            decorationColor: text,
          ),
        ),
      ),
    );
  }
}
