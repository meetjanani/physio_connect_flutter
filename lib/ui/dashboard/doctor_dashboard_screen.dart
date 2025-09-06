import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/ui/booking_history/session_booking_card.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../../model/bookings_model.dart';
import '../../route/route_module.dart';
import '../../utils/view_extension.dart';
import '../booking_history/booking_history_controller.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  // final DashboardController dashboardController = DashboardController.to;
  final BookingHistoryController bookingHistoryController = Get.put(BookingHistoryController());


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar("Doctor Dashboard"),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Date selection row
              _buildDateFilter(context),

              // Tabs for Today, Tomorrow, This Week
              // _buildTabSelector(),

              // Stats cards
              // _buildStatsCards(),

              // Appointment list
              _buildAppointmentsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: AppColors.medicalBlueLight,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Date',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Obx(() => buildDatePickerButton(
                    label: 'From',
                    date: bookingHistoryController.fromDate.value,
                    onTap: () => _selectDate(context, true),
                  )),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Obx(() => buildDatePickerButton(
                    label: 'To',
                    date: bookingHistoryController.toDate.value,
                    onTap: () => _selectDate(context, false),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Obx(() {
      final upcomingAppointments = bookingHistoryController.upComingBookings;

      // Count appointments for today
      final todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayAppointments = upcomingAppointments
          .where((a) => a.bookingDate == todayDateStr)
          .toList();

      // Count completed appointments (this would typically come from the controller)
      final completedAppointments = upcomingAppointments
          .where((a) => a.bookingStatus.toLowerCase() == 'completed')
          .toList();

      return Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _buildStatCard(
              title: "Today's\nPatients",
              value: todayAppointments.length.toString(),
              icon: Icons.people,
              color: AppColors.medicalBlue,
            ),
            SizedBox(width: 10),
            _buildStatCard(
              title: "Completed\nSessions",
              value: completedAppointments.length.toString(),
              icon: Icons.check_circle,
              color: AppColors.wellnessGreen,
            ),
            SizedBox(width: 10),
            _buildStatCard(
              title: "Total\nAppointments",
              value: upcomingAppointments.length.toString(),
              icon: Icons.calendar_today,
              color: AppColors.therapyPurple,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Spacer(),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return Obx(() {
      var upcomingAppointments = bookingHistoryController.upComingBookings;

      // Sort by time
      upcomingAppointments.sort((a, b) {
        // First by date
        final dateComparison = a.bookingDate.compareTo(b.bookingDate);
        if (dateComparison != 0) return dateComparison;

        // Then by time
        return a.aTimeslot().time.compareTo(b.aTimeslot().time);
      });

      return Expanded(
        child: upcomingAppointments.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                itemCount: upcomingAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = upcomingAppointments[index];
                  return SessionBookingCard(appointment);
                },
              ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: AppColors.medicalBlueLight,
          ),
          SizedBox(height: 16),
          Text(
            "No appointments scheduled",
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "You have no appointments for the selected period",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? bookingHistoryController.fromDate.value : bookingHistoryController.toDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.medicalBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isFromDate) {
        bookingHistoryController.fromDate.value = picked;
        if (picked.isAfter(bookingHistoryController.toDate.value)) {
          bookingHistoryController.toDate.value = picked;
        }
      } else {
        bookingHistoryController.toDate.value = picked;
        if (picked.isBefore(bookingHistoryController.fromDate.value)) {
          bookingHistoryController.fromDate.value = picked;
        }
      }
      bookingHistoryController.getFilteredBookings();
    }
  }
}

