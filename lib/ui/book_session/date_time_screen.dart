import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../route/route_module.dart';
import 'booking_controller.dart';

class DateTimeScreen extends StatelessWidget {
  final BookingController controller = Get.find<BookingController>();

  DateTimeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar("Select Date & Time", isBackButtonVisible: true),
      body: SafeArea(child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
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
                    () => Row(
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
                                controller.selectedSessionType.value?.name ??
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
                  ),
                ),
                SizedBox(height: 12),
                // Calendar
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
                Obx(
                  () => TableCalendar(
                    rowHeight: 40,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(Duration(days: 60)),
                    focusedDay: controller.selectedDate.value,
                    selectedDayPredicate: (day) {
                      return isSameDay(controller.selectedDate.value, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      controller.selectedDate.value = selectedDay;
                      controller.getTimeSlotsMaster();
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: AppColors.medicalBlue,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.medicalBlueLight,
                        border: Border.all(
                          color: AppColors.medicalBlue,
                          width: 1.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: AppColors.medicalBlueDark,
                        fontWeight: FontWeight.bold,
                      ),
                      defaultTextStyle: TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      weekendTextStyle: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      outsideTextStyle: TextStyle(
                        color: AppColors.textMuted,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: AppColors.medicalBlue,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: AppColors.medicalBlue,
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
                                      controller.selectedTimeSlot.value = slot;
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
                                        color: AppColors.medicalBlue.withOpacity(0.3),
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
                   /* SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.my_location, color: AppColors.medicalBlue),
                      tooltip: 'Use current location',
                      onPressed: () async {
                        // TODO: Implement GPS logic to fetch and set address
                        // Example:
                        // String address = await controller.getCurrentLocationAddress();
                        // addressController.text = address;
                      },
                    ),*/
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
                        Get.toNamed(AppPage.performPayment);
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
      )),
    );
  }
}
