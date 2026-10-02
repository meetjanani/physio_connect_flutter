import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/custom_widget/session_type_info.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

import '../../model/time_slots_model.dart';
import '../../route/route_module.dart';
import '../../utils/view_extension.dart';
import 'booking_controller.dart';

class DateTimeScreen extends StatefulWidget {
  DateTimeScreen({Key? key}) : super(key: key);

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  final BookingController controller = Get.find<BookingController>();

  @override
  void initState() {
    super.initState();
    _fetchTimeSlotAfterDateSelection(DateTime.now());
    fetchAndSetCurrentLocation();
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
                  SizedBox(height: 16),
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
                  Obx(
                    () => InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Appointment date',
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: AppColors.medicalBlue,
                          ),
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.medicalBlueDark,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          DateFormat(
                            'dd-MMM-yyyy',
                          ).format(controller.selectedDate.value),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Time slots
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
                  SizedBox(height: 10),
                  Obx(() => _buildTimeSlotSection()),
                  SizedBox(height: 12),
                  _buildAppointmentPlanner(),
                  SizedBox(height: 12),

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
                  SizedBox(height: 10),
                  // Address multiline text field with location icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.houseNameBlockNumberController,
                          maxLines: 3,
                          minLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Appartment/House Name &  Block number',
                            hintText: 'Appartment Name &  Block number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.addressController,
                          maxLines: 3,
                          minLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            hintText: 'Enter your address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.my_location,
                          color: AppColors.medicalBlue,
                        ),
                        tooltip: 'Use current location',
                        onPressed: () async {
                          fetchAndSetCurrentLocation();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
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
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.selectedTimeSlot.value == null
                      ? null
                      : () {
                          if (controller.selectedSessionType.value == null) {
                            controller.showErrorSnackbar(
                              'Please select a session type before proceeding.',
                            );
                            return;
                          }
                          _confirmAppointments();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.selectedTimeSlot.value == null
                        ? AppColors.textMuted
                        : AppColors.medicalBlue,
                    foregroundColor: AppColors.textOnDark,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textMuted,
                    minimumSize: Size(double.infinity, 50),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to Payment',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
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

    return GridView.count(
      key: ValueKey('slots_$selectedId'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.35,
      children: slots.map((slot) {
        final isBooked = slot.isBooked ?? false;
        final isSelected = selectedId != null && selectedId == slot.id;
        return _buildTimeSlotChip(
          slot: slot,
          isBooked: isBooked,
          isSelected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlotChip({
    required TimeSlotModel slot,
    required bool isBooked,
    required bool isSelected,
  }) {
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
      onTap: isBooked
          ? null
          : () => controller.selectedTimeSlot.value = slot,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: border,
            width: isSelected ? 1.5 : 1,
          ),
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

  Widget _buildAppointmentPlanner() {
    return Obx(() {
      final bulk = controller.isBulkAppointment.value;
      final count = controller.bulkAppointmentCount.value;
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Book multiple appointments',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                bulk
                    ? 'Create one payment for multiple dates'
                    : 'Book a single appointment',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              value: bulk,
              activeTrackColor: AppColors.medicalBlue,
              activeThumbColor: AppColors.surface,
              inactiveTrackColor: AppColors.borderDark,
              inactiveThumbColor: AppColors.surface,
              trackOutlineColor: WidgetStatePropertyAll(
                bulk ? AppColors.medicalBlue : AppColors.borderDark,
              ),
              onChanged: controller.setBulkAppointmentEnabled,
            ),
            if (bulk) ...[
              const SizedBox(height: 4),
              _buildSessionCountStepper(count),
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
                'Editing a date also updates all sessions after it.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              ...controller.appointmentDates.asMap().entries.map(
                (entry) => _buildAppointmentDateRow(entry.key, entry.value),
              ),
            ],
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
                  'Min 2 · Max 100',
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
            enabled: count > 2,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _editAppointmentDate(index, date),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.medicalBlueLight,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.medicalBlueDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('d-MMM-yyyy, EEEE').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
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

    final initialDate =
        current.isBefore(firstDate) ? firstDate : current;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date != null) {
      controller.updateAppointmentDate(index, date);
    }
  }

  Future<void> _confirmAppointments() async {
    final dates = controller.appointmentDates;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm appointments'),
        content: Text(
          '${dates.length} appointment${dates.length == 1 ? '' : 's'} will be created. '
          'You will make one payment for the total amount.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Review')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      Get.toNamed(AppPage.performPayment);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final current = controller.selectedDate.value;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current.isBefore(now) ? now : current,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (pickedDate == null) return;

    await _fetchTimeSlotAfterDateSelection(pickedDate);
  }

  Future<void> _fetchTimeSlotAfterDateSelection(DateTime selectedDate) async {
    controller.selectedDate.value = selectedDate;
    controller.configureAppointmentDates();
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
