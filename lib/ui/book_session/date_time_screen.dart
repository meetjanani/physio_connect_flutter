// lib/ui/booking/date_time_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/ui/book_session/payment_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import 'booking_controller.dart';

class DateTimeScreen extends StatelessWidget {
  final BookingController controller = Get.find<BookingController>();

  DateTimeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Date & Time',
          style: GoogleFonts.inter(
            textStyle: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        backgroundColor: AppColors.therapyPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Session type info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.therapyPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Obx(() => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.spa,
                        color: AppColors.therapyPurple,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.selectedSessionType.value?.name ?? 'Selected Session',
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
                              '${controller.selectedSessionType.value?.durationMinutes ?? 0} min • ₹${controller.selectedSessionType.value?.price.toStringAsFixed(0) ?? 0}',
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
                ),
                SizedBox(height: 24),

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
                SizedBox(height: 12),
                Obx(() => TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(Duration(days: 60)),
                  focusedDay: controller.selectedDate.value,
                  selectedDayPredicate: (day) {
                    return isSameDay(controller.selectedDate.value, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    controller.selectedDate.value = selectedDay;
                    controller.loadAvailableTimeSlots();
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: AppColors.therapyPurple,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.therapyPurple.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),
                SizedBox(height: 24),

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
                SizedBox(height: 12),
                Obx(() => controller.isLoadingTimeSlots.value
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : controller.availableTimeSlots.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'No available slots for this date',
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            children: controller.availableTimeSlots.map((slot) {
                              final bool isBooked = controller.bookedTimeSlots.contains(slot);
                              final bool isSelected = controller.selectedTimeSlot.value == slot;

                              return GestureDetector(
                                onTap: isBooked
                                    ? null
                                    : () {
                                        controller.selectedTimeSlot.value = slot;
                                      },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isBooked
                                        ? Colors.red.withOpacity(0.1)
                                        : isSelected
                                            ? AppColors.therapyPurple
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isBooked
                                          ? Colors.red.withOpacity(0.5)
                                          : isSelected
                                              ? AppColors.therapyPurple
                                              : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    slot,
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isBooked
                                            ? Colors.red
                                            : isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )),
              ],
            ),
          ),

          // Bottom button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Obx(() => ElevatedButton(
              onPressed: controller.selectedTimeSlot.value.isEmpty
                  ? null
                  : () {
                      Get.to(() => PaymentScreen());
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.therapyPurple,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
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
            )),
          ),
        ],
      ),
    );
  }
}