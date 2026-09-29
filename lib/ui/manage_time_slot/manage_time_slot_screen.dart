import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/model/time_slots_model.dart';
import 'package:physio_connect/model/user_model_supabase.dart';
import 'package:physio_connect/supabase/supabase_controller.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:physio_connect/utils/theme/app_spacing.dart';
import 'package:physio_connect/utils/view_extension.dart';

class ManageTimeSlotScreen extends StatefulWidget {
  const ManageTimeSlotScreen({super.key});

  @override
  State<ManageTimeSlotScreen> createState() => _ManageTimeSlotScreenState();
}

class _ManageTimeSlotScreenState extends State<ManageTimeSlotScreen> {
  static const int _minEnabled = 2;

  final _supabase = SupabaseController.to;

  bool _loading = true;
  bool _saving = false;
  DoctorModel? _doctor;
  List<TimeSlotModel> _slots = [];
  final Set<int> _enabledIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await UserModelSupabase.getFromSecureStorage();
      final doctor = await _supabase.getDoctorByUserId(user?.id ?? 0);
      if (doctor?.id == null) {
        Get.showErrorSnackbar(
          'Doctor profile not linked. Ask admin to set doctor.userId.',
        );
        setState(() {
          _doctor = null;
          _slots = [];
          _enabledIds.clear();
          _loading = false;
        });
        return;
      }

      final slots = await _supabase.getActiveTimeSlots();
      setState(() {
        _doctor = doctor;
        _slots = slots;
        _enabledIds
          ..clear()
          ..addAll(_parseIds(doctor!.timeSlotId));
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
      Get.showErrorSnackbar('Could not load time slots. Please try again.');
    }
  }

  Set<int> _parseIds(String? csv) {
    if (csv == null || csv.trim().isEmpty || csv.trim() == '0') return {};
    return csv
        .split(',')
        .map((v) => int.tryParse(v.trim()))
        .whereType<int>()
        .where((id) => id > 0)
        .toSet();
  }

  Future<void> _onToggle(int slotId, bool enable) async {
    if (_doctor?.id == null || _saving) return;

    if (!enable && _enabledIds.length <= _minEnabled) {
      Get.showErrorSnackbar('Keep at least $_minEnabled time slots enabled.');
      return;
    }

    // Update UI immediately.
    setState(() {
      if (enable) {
        _enabledIds.add(slotId);
      } else {
        _enabledIds.remove(slotId);
      }
      _saving = true;
    });

    final csv = (_enabledIds.toList()..sort()).join(',');
    try {
      await _supabase.updateDoctorTimeSlotIds(_doctor!.id!, csv);
      _doctor!.timeSlotId = csv.isEmpty ? '0' : csv;
      await _doctor!.saveToSecureStorage();
    } catch (_) {
      // Revert UI if save failed.
      setState(() {
        if (enable) {
          _enabledIds.remove(slotId);
        } else {
          _enabledIds.add(slotId);
        }
      });
      Get.showErrorSnackbar('Failed to update time slot. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: commonAppBar('Manage Time Slot', isBackButtonVisible: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _slots.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No active time slots found. Contact admin to add slots.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    _hintBanner(),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        itemCount: _slots.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, index) {
                          final slot = _slots[index];
                          final enabled = _enabledIds.contains(slot.id);
                          return _slotTile(slot.time, enabled, slot.id);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _hintBanner() {
    final belowMin = _enabledIds.length < _minEnabled;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.medicalBlueLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.medicalBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        belowMin
            ? 'Enable at least $_minEnabled slots (currently ${_enabledIds.length}).'
            : 'At least $_minEnabled slots must stay on. Currently enabled: ${_enabledIds.length}',
        style: GoogleFonts.inter(
          textStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: belowMin ? AppColors.warningDark : AppColors.medicalBlueDark,
          ),
        ),
      ),
    );
  }

  Widget _slotTile(String time, bool enabled, int slotId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: enabled
              ? AppColors.wellnessGreen.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          time,
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        subtitle: Text(
          enabled ? 'Available for booking' : 'Hidden from patients',
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 12,
              color: enabled
                  ? AppColors.wellnessGreenDark
                  : AppColors.textMuted,
            ),
          ),
        ),
        value: enabled,
        activeTrackColor: AppColors.medicalBlue,
        activeThumbColor: AppColors.surface,
        inactiveTrackColor: AppColors.borderDark,
        inactiveThumbColor: AppColors.surface,
        onChanged: _saving ? null : (value) => _onToggle(slotId, value),
      ),
    );
  }
}
