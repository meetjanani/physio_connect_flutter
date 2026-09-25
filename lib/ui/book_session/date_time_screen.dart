import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

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
  final appointmentCountController = TextEditingController(text: '2');

  @override
  void initState() {
    super.initState();
    controller.configureAppointmentDates();
    controller.getTimeSlotsMaster();
    fetchAndSetCurrentLocation();
  }

  @override
  void dispose() {
    appointmentCountController.dispose();
    super.dispose();
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
                padding: EdgeInsets.all(16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Session type info
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.medicalBlueLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.medicalBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coverage Details',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.medicalBlueDark,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${controller.selectedCity.value?.cityStateName ?? 'City'} › ${controller.selectedArea.value?.areaName ?? 'Area'} › ${controller.selectedDoctor.value?.name ?? 'Doctor'}',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.spa,
                                color: AppColors.medicalBlueDark,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller
                                              .selectedSessionType
                                              .value
                                              ?.name ??
                                          'Selected Session',
                                      style: GoogleFonts.inter(
                                        textStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${controller.selectedSessionType.value?.duration ?? 0} • ₹${controller.selectedSessionType.value?.price.toStringAsFixed(0) ?? 0}',
                                      style: GoogleFonts.inter(
                                        textStyle: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
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
                  Obx(
                    () => controller.isLoading.value
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(
                                color: AppColors.medicalBlue,
                              ),
                            ),
                          )
                        : controller.timeSlots.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 48,
                                    color: AppColors.medicalBlueLight,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No available slots for this date',
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            children: controller.timeSlots.map((slot) {
                              final bool isBooked = slot.isBooked ?? false;
                              final bool isSelected =
                                  controller.selectedTimeSlot.value == slot;

                              return GestureDetector(
                                onTap: isBooked
                                    ? null
                                    : () {
                                        controller.selectedTimeSlot.value =
                                            slot;
                                      },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isBooked
                                        ? AppColors.errorLight
                                        : isSelected
                                        ? AppColors.medicalBlue
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: AppColors.medicalBlue
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                    ],
                                    border: Border.all(
                                      color: isBooked
                                          ? AppColors.error
                                          : isSelected
                                          ? AppColors.medicalBlue
                                          : AppColors.border,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    slot.time,
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isBooked
                                            ? AppColors.error
                                            : isSelected
                                            ? AppColors.textOnDark
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  SizedBox(height: 12),
                  _buildAppointmentPlanner(),
                  SizedBox(height: 12),

                  // Time slots
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

  Widget _buildAppointmentPlanner() {
    return Obx(() {
      final bulk = controller.isBulkAppointment.value;
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
              title: const Text('Book multiple appointments'),
              subtitle: const Text('Create one payment for multiple dates'),
              value: bulk,
              onChanged: controller.setBulkAppointmentEnabled,
            ),
            if (bulk) ...[
              TextField(
                controller: appointmentCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of appointments (2–100)',
                ),
                onChanged: controller.setBulkAppointmentCount,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _recurrenceChip('Every day', 'every_day'),
                  _recurrenceChip('Alternate day', 'alternative_day'),
                  _recurrenceChip('Every 2 days', 'every_2_day'),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'You can change any appointment date before payment. Dates can also be changed individually after booking.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              ...controller.appointmentDates.asMap().entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text('${entry.key + 1}'),
                  ),
                  title: Text(
                    DateFormat('dd-MMM-yyyy').format(entry.value),
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => _editAppointmentDate(entry.key, entry.value),
                ),
              ),
            ],
          ],
        ),
      );
    });
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
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    controller.selectedDate.value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
    );
    controller.configureAppointmentDates();
    await controller.getTimeSlotsMaster();
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
