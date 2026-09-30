import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/model/time_slots_model.dart';
import 'package:physio_connect/model/user_model_supabase.dart';
import 'package:physio_connect/supabase/supabase_controller.dart';
import 'package:physio_connect/custom_widget/physio_progress_bar.dart';
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
  final _searchController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  DoctorModel? _doctor;
  List<TimeSlotModel> _slots = [];
  final Set<int> _enabledIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  /// Normalize "7:20 pm", "07:20PM", "7:20  PM" for matching.
  String _normalizeTimeQuery(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<TimeSlotModel> get _visibleSlots {
    final query = _normalizeTimeQuery(_searchQuery);
    final filtered = query.isEmpty
        ? List<TimeSlotModel>.from(_slots)
        : _slots
            .where((slot) {
              final time = _normalizeTimeQuery(slot.time);
              return time.contains(query);
            })
            .toList();

    // Active (enabled) first, then keep chronological / orderBy order.
    filtered.sort((a, b) {
      final aOn = _enabledIds.contains(a.id);
      final bOn = _enabledIds.contains(b.id);
      if (aOn != bOn) return aOn ? -1 : 1;
      return a.id.compareTo(b.id);
    });
    return filtered;
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
    final visible = _visibleSlots;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: commonAppBar('Manage Time Slot', isBackButtonVisible: true),
      body: _loading
          ? const PhysioProgressBar(
              card: false,
              message: 'Preparing your available hours…',
            )
          : PhysioProgressOverlay(
              visible: _saving,
              message: 'Saving your time slots…',
              child: _slots.isEmpty
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
                        _searchBar(),
                        Expanded(
                          child: visible.isEmpty
                              ? Center(
                                  child: Text(
                                    'No slots match "$_searchQuery"',
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    AppSpacing.sm,
                                    AppSpacing.md,
                                    AppSpacing.lg,
                                  ),
                                  itemCount: visible.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (_, index) {
                                    final slot = visible[index];
                                    final enabled =
                                        _enabledIds.contains(slot.id);
                                    return _slotTile(
                                      slot.time,
                                      enabled,
                                      slot.id,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: GoogleFonts.inter(
          textStyle: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        decoration: InputDecoration(
          hintText: 'Search time (e.g. 7:20 PM)',
          hintStyle: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear, color: AppColors.textMuted),
                ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: const BorderSide(color: AppColors.medicalBlue),
          ),
        ),
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
