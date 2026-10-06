import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/custom_widget/session_type_info.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

import '../../custom_widget/time_slot_chip_grid.dart';
import '../../model/time_slots_model.dart';
import '../../route/route_module.dart';
import '../../utils/field_validations.dart';
import '../../utils/view_extension.dart';
import 'booking_controller.dart';

class DateTimeScreen extends StatefulWidget {
  DateTimeScreen({Key? key}) : super(key: key);

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  final BookingController controller = Get.find<BookingController>();
  final _addressFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller.initializeEmailFromProfile();
    _fetchTimeSlotAfterDateSelection(DateTime.now());
    if (!controller.isSelectedOnline) {
      fetchAndSetCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar("Select Date & Time", isBackButtonVisible: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(12),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SessionTypeInfo(),
                  const SizedBox(height: 16),
                  Text(
                    'Select Date',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildAppointmentPlanner(),
                  const SizedBox(height: 16),
                  Text(
                    'Select Time',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Obx(() {
                    final multi = controller.bulkAppointmentCount.value > 1;
                    if (!multi) return const SizedBox(height: 10);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 10),
                      child: Text(
                        'Preferred time is applied to all dates. Conflict days need their own time.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }),
                  Obx(() => _buildTimeSlotSection()),
                  Obx(() {
                    if (!controller.isCheckingConflicts.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Checking availability across dates…',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Text(
                    'Add your email to receive appointment status updates, invoices, and online session invites (optional)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Form(
                    key: _emailFormKey,
                    child: TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty ||
                            RegExp(emailPattern).hasMatch(email)) {
                          return null;
                        }
                        return 'Enter a valid email, or leave this blank';
                      },
                      decoration: InputDecoration(
                        labelText: 'Email (optional)',
                        hintText: 'name@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (controller.isSelectedOnline)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.medicalBlueLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.medicalBlue.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Text(
                            'This is an online session. After payment we add a Google Meet link. You can optionally share an email so the calendar invite is sent to you.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.medicalBlueDark,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    const SizedBox(height: 10),
                    Text(
                      'Enter Address',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Form(
                      key: _addressFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller:
                                controller.houseNameBlockNumberController,
                            maxLines: 3,
                            minLines: 2,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Apartment/House name & block number is required';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText:
                                  'Apartment/House Name & Block number *',
                              hintText: 'Apartment Name & Block number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: controller.addressController,
                                  maxLines: 3,
                                  minLines: 2,
                                  textInputAction: TextInputAction.done,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Address is required';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Address *',
                                    hintText: 'Enter your address',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.my_location,
                                  color: AppColors.medicalBlue,
                                ),
                                tooltip: 'Use current location',
                                onPressed: () async {
                                  await fetchAndSetCurrentLocation();
                                  _addressFormKey.currentState?.validate();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Bottom button
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Obx(() {
                final canContinue = controller.canContinueToPayment;
                final conflictCount = controller.conflictDates.length;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (conflictCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Resolve $conflictCount conflict date${conflictCount == 1 ? '' : 's'} to continue',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.errorDark,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: !canContinue
                          ? null
                          : () {
                              if (controller.selectedSessionType.value ==
                                  null) {
                                controller.showErrorSnackbar(
                                  'Please select a session type before proceeding.',
                                );
                                return;
                              }
                              final emailValid =
                                  _emailFormKey.currentState?.validate() ??
                                  true;
                              if (!emailValid) {
                                controller.showErrorSnackbar(
                                  'Please enter a valid email, or leave it blank.',
                                );
                                return;
                              }
                              if (!controller.isSelectedOnline) {
                                final formValid =
                                    _addressFormKey.currentState?.validate() ??
                                    false;
                                if (!formValid) {
                                  controller.showErrorSnackbar(
                                    'Please fill in apartment/house details and address.',
                                  );
                                  return;
                                }
                              }
                              _confirmAppointments();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canContinue
                            ? AppColors.medicalBlue
                            : AppColors.textMuted,
                        foregroundColor: AppColors.textOnDark,
                        disabledBackgroundColor: AppColors.border,
                        disabledForegroundColor: AppColors.textMuted,
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continue to Payment',
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSection() {
    // Read observables here so Obx always tracks selection changes.
    // (GridView.builder's itemBuilder is lazy and can miss GetX updates.)
    final isLoading = controller.isLoading.value;
    final slots = controller.timeSlots.toList();
    final selectedId = controller.selectedTimeSlot.value?.id;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(color: AppColors.medicalBlue),
        ),
      );
    }

    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 36,
              color: AppColors.medicalBlue.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 8),
            Text(
              'No available slots for this date',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return TimeSlotChipGrid(
      slots: slots,
      selectedId: selectedId,
      onSelect: controller.selectPreferredTimeSlot,
    );
  }

  Widget _buildAppointmentPlanner() {
    return Obx(() {
      final count = controller.bulkAppointmentCount.value;
      final isMulti = count > 1;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSessionCountStepper(count),
            if (isMulti) ...[
              const SizedBox(height: 14),
              Text(
                'Repeat',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _recurrenceChip('Every day', 'every_day'),
                  _recurrenceChip('Alternate day', 'alternative_day'),
                  _recurrenceChip('Every 2 days', 'every_2_day'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Editing a date also updates all sessions after it. Conflict days: tap Choose to pick another time.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ...controller.appointmentDates.asMap().entries.map(
              (entry) => _buildAppointmentDateRow(entry.key, entry.value),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSessionCountStepper(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.medicalBlueLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.medicalBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number of sessions',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 1
                      ? 'Tap + to book multiple dates'
                      : 'Min 1 · Max 100',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _stepperButton(
            icon: Icons.remove_rounded,
            enabled: count > 1,
            onTap: () => controller.adjustBulkAppointmentCount(-1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.medicalBlueDark,
              ),
            ),
          ),
          _stepperButton(
            icon: Icons.add_rounded,
            enabled: count < 100,
            onTap: () => controller.adjustBulkAppointmentCount(1),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? AppColors.surface : AppColors.borderLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.medicalBlueDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentDateRow(int index, DateTime date) {
    // Read maps so Obx rebuilds when conflict status changes.
    controller.timeSlotByDate.length;
    controller.conflictDates.length;
    final isConflict = controller.isConflictDate(date);
    final assignedSlot = controller.timeSlotForDate(date);
    final hasPreferred = controller.selectedTimeSlot.value != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isConflict
            ? AppColors.errorLight.withValues(alpha: 0.55)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            if (isConflict) {
              await _showAlternateTimeSheet(date);
              return;
            }
            await _editAppointmentDate(index, date);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isConflict
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.medicalBlueLight,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isConflict
                          ? AppColors.errorDark
                          : AppColors.medicalBlueDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d-MMM-yyyy, EEEE').format(date),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (hasPreferred) ...[
                        const SizedBox(height: 4),
                        _buildDateStatusChip(
                          isConflict: isConflict,
                          slot: assignedSlot,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isConflict)
                  TextButton(
                    onPressed: () => _showAlternateTimeSheet(date),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Choose',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.errorDark,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.edit_calendar_rounded,
                    size: 18,
                    color: AppColors.medicalBlueDark,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateStatusChip({
    required bool isConflict,
    required TimeSlotModel? slot,
  }) {
    if (isConflict) {
      return Text(
        'Conflict · Tap to choose time',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.errorDark,
        ),
      );
    }
    if (slot == null) {
      return Text(
        'Waiting for time',
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
      );
    }
    return Text(
      slot.time,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.wellnessGreenDark,
      ),
    );
  }

  Future<void> _showAlternateTimeSheet(DateTime date) async {
    final formatted = DateFormat('d-MMM-yyyy, EEEE').format(date);
    final slotsFuture = controller.loadSlotsForDate(date);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: FutureBuilder<List<TimeSlotModel>>(
              future: slotsFuture,
              builder: (context, snapshot) {
                final loading =
                    snapshot.connectionState != ConnectionState.done;
                final daySlots = snapshot.data ?? const <TimeSlotModel>[];
                final available = daySlots
                    .where((s) => !(s.isBooked ?? false))
                    .toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Choose time for conflict day',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatted,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.medicalBlue,
                          ),
                        ),
                      )
                    else if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Could not load slots. Please try again.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.errorDark,
                          ),
                        ),
                      )
                    else if (available.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No available slots on this date. Try changing the date.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.35,
                          children: available.map((slot) {
                            return GestureDetector(
                              onTap: () {
                                controller.resolveConflictForDate(date, slot);
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  slot.time,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _recurrenceChip(String label, String value) {
    return Obx(
      () => ChoiceChip(
        label: Text(label),
        selected: controller.recurrence.value == value,
        onSelected: (_) => controller.setRecurrence(value),
      ),
    );
  }

  Future<void> _editAppointmentDate(int index, DateTime current) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime firstDate = today;
    if (index > 0) {
      final previous = controller.appointmentDates[index - 1];
      final minAfterPrevious = DateTime(
        previous.year,
        previous.month,
        previous.day,
      ).add(const Duration(days: 1));
      if (minAfterPrevious.isAfter(firstDate)) {
        firstDate = minAfterPrevious;
      }
    }

    final initialDate = current.isBefore(firstDate) ? firstDate : current;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final firstDateChanged = controller.updateAppointmentDate(index, date);
    if (firstDateChanged) {
      await _fetchTimeSlotAfterDateSelection(date, regenerateDates: false);
    } else if (controller.selectedTimeSlot.value != null) {
      await controller.checkConflictsAcrossDates();
    }
  }

  Future<void> _confirmAppointments() async {
    final dates = controller.appointmentDates;
    if (dates.length <= 1) {
      Get.toNamed(AppPage.performPayment);
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm appointments'),
        content: Text(
          '${dates.length} appointments will be created. '
          'You will make one payment for the total amount.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      Get.toNamed(AppPage.performPayment);
    }
  }

  Future<void> _fetchTimeSlotAfterDateSelection(
    DateTime selectedDate, {
    bool regenerateDates = true,
  }) async {
    controller.selectedDate.value = selectedDate;
    if (regenerateDates) {
      controller.configureAppointmentDates();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.getTimeSlotsMaster();
      }
    });
  }

  Future<void> fetchAndSetCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final addressParts = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.postalCode,
          placemark.administrativeArea,
          placemark.country,
        ].where((part) => part != null && part.isNotEmpty).toSet().toList();
        final address = addressParts.join(', ');
        controller.addressController.text = address;
        controller.latitudeOfAddress.value = position.latitude.toString();
        controller.longitudeOfAddress.value = position.longitude.toString();
      }
    } catch (e) {
      print(e);
    }
  }
}
