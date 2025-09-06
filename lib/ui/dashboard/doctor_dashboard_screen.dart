import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/ui/booking_history/session_booking_card.dart';
import 'package:physio_connect/ui/dashboard/dashboard_controller.dart';
import 'package:physio_connect/utils/common_appbar.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';
import 'package:physio_connect/utils/units_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/bookings_model.dart';
import '../../route/route_module.dart';
import '../../utils/view_extension.dart';
import '../booking_history/booking_history_controller.dart';
import '../booking_history/show_html_editor_for_doctor_note.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final DashboardController dashboardController = DashboardController.to;
  final BookingHistoryController bookingHistoryController = Get.put(BookingHistoryController());

  final RxInt selectedTabIndex = 0.obs;

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
              _buildStatsCards(),

              // Appointment list
              _buildAppointmentsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.medicalBlueLight.withOpacity(0.5),
      ),
      child: Row(
        children: [
          _buildTab("Today", 0),
          SizedBox(width: 12),
          _buildTab("Tomorrow", 1),
          SizedBox(width: 12),
          _buildTab("Next 10 Days", 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    return Obx(() {
      final isSelected = selectedTabIndex.value == index;
      return Expanded(
        child: InkWell(
          onTap: () {
            selectedTabIndex.value = index;
            // Logic to update date based on tab
            if (index == 0) {
              bookingHistoryController.fromDate.value = DateTime.now();
              bookingHistoryController.toDate.value = DateTime.now();
            } else if (index == 1) {
              bookingHistoryController.fromDate.value = DateTime.now();
              bookingHistoryController.toDate.value = DateTime.now().add(Duration(days: 1));
            }
            else {
              // For "This Week" tab, we keep the selected date but show the whole week
              bookingHistoryController.fromDate.value = DateTime.now();
              bookingHistoryController.toDate.value = DateTime.now().add(Duration(days: 10));
            }
            bookingHistoryController.getFilteredBookings();
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.medicalBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? AppColors.medicalBlue : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStatsCards() {
    return Obx(() {
      final upcomingAppointments = dashboardController.upComingBookings;

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
      final upcomingAppointments = dashboardController.upComingBookings;

      // Filter based on selected tab
      List<BookingsModel> filteredAppointments = [];

      if (selectedTabIndex.value == 0) {
        // Today
        final todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        filteredAppointments = upcomingAppointments
            .where((a) => a.bookingDate == todayDateStr)
            .toList();
      } else if (selectedTabIndex.value == 1) {
        // Tomorrow
        final tomorrowDateStr = DateFormat('yyyy-MM-dd')
            .format(DateTime.now().add(Duration(days: 1)));
        filteredAppointments = upcomingAppointments
            .where((a) => a.bookingDate == tomorrowDateStr)
            .toList();
      } else {
        // This Week
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));

        filteredAppointments = upcomingAppointments.where((a) {
          final appointmentDate = DateFormat('yyyy-MM-dd').parse(a.bookingDate);
          return appointmentDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
                 appointmentDate.isBefore(endOfWeek.add(Duration(days: 1)));
        }).toList();
      }

      // Sort by time
      filteredAppointments.sort((a, b) {
        // First by date
        final dateComparison = a.bookingDate.compareTo(b.bookingDate);
        if (dateComparison != 0) return dateComparison;

        // Then by time
        return a.aTimeslot().time.compareTo(b.aTimeslot().time);
      });

      return Expanded(
        child: filteredAppointments.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                itemCount: filteredAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = filteredAppointments[index];
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

