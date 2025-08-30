// lib/ui/booking/history/booking_history_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/utils/enum.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../../route/route_module.dart';
import '../../utils/common_appbar.dart';
import '../../utils/units_extensions.dart';
import 'booking_history_controller.dart';

class BookingHistoryScreen extends StatelessWidget {
  final BookingHistoryController controller = Get.put(BookingHistoryController());

  BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar("Booking Details"),
      body: Column(
        children: [
          _buildDateFilter(context),
          Expanded(
            child: Obx(() => controller.isLoading.value
              ? Center(child: CircularProgressIndicator())
              : controller.upComingBookings.isEmpty
                ? _buildEmptyState()
                : _buildAppointmentsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildDatePickerButton(
                  label: 'From',
                  date: controller.fromDate.value,
                  onTap: () => _selectDate(context, true),
                )),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Obx(() => _buildDatePickerButton(
                  label: 'To',
                  date: controller.toDate.value,
                  onTap: () => _selectDate(context, false),
                )),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildQuickFilterChip('Last 7 days', () => controller.applyQuickFilter(7)),
              SizedBox(width: 8),
              _buildQuickFilterChip('Last 30 days', () => controller.applyQuickFilter(30)),
              SizedBox(width: 8),
              _buildQuickFilterChip('This month', () => controller.filterCurrentMonth()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Spacer(),
            Icon(Icons.calendar_today, size: 16, color: AppColors.therapyPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.therapyPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.therapyPurple)
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.therapyPurple,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? controller.fromDate.value : controller.toDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.therapyPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isFromDate) {
        controller.fromDate.value = picked;
        if (picked.isAfter(controller.toDate.value)) {
          controller.toDate.value = picked;
        }
      } else {
        controller.toDate.value = picked;
        if (picked.isBefore(controller.fromDate.value)) {
          controller.fromDate.value = picked;
        }
      }
      controller.getUpComingBookings();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No appointments found',
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
            'Try adjusting your filter or book a new appointment',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppPage.selectSessionType),
            icon: Icon(Icons.add),
            label: Text('Book New Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.therapyPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: controller.upComingBookings.length,
      itemBuilder: (context, index) {
        final appointment = controller.upComingBookings[index];
        final isUpcoming = appointment.paymentStatus == BookingStatus.booked.name;

        return GestureDetector(
          onTap: (){
            controller.selectedAppointment.value = appointment;
            Get.toNamed(
                AppPage.bookingDetail,
                arguments: appointment
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isUpcoming
                  ? AppColors.wellnessGreen.withOpacity(0.3)
                  : Colors.transparent,
                width: isUpcoming ? 2 : 0,
              ),
            ),
            child: Column(
              children: [
                // Status banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.bookingStatus),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    _getStatusText(appointment.bookingStatus),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Appointment details
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session type and date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.therapyPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.healing,
                              color: AppColors.therapyPurple,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.aSessionType().name,
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
                                  '${formatDateToReadable(appointment.bookingDate)} • ${appointment.aTimeslot().time}',
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
                      ),

                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 16),

                      // Doctor info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(controller.therapistsImage),
                            backgroundColor: AppColors.therapyPurple.withOpacity(0.1),
                            child: controller.therapistsImage.isEmpty
                                ? Icon(Icons.person, color: AppColors.therapyPurple)
                                : null,
                          ),
                          SizedBox(width: 10,),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.aDoctor().name ?? '',
                                  style: GoogleFonts.inter(
                                    textStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  appointment.aDoctor().degree ?? '',
                                  style: GoogleFonts.inter(
                                    textStyle: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildPaymentBadge(appointment.paymentStatus),
                        ],
                      ),
                    ],
                  ),
                ),

                // View details button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.therapyPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'paid':
        bgColor = AppColors.wellnessGreen.withOpacity(0.15);
        textColor = AppColors.wellnessGreen;
        break;
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange.shade800;
        break;
      case 'failed':
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          textStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return AppColors.wellnessGreen;
      case 'completed':
        return AppColors.therapyPurple;
      case 'cancelled':
        return Colors.red.shade400;
      case 'no-show':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no-show':
        return 'No Show';
      default:
        return status.capitalize!;
    }
  }
}