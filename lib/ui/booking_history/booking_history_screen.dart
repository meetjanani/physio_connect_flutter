// lib/ui/booking/history/booking_history_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/ui/booking_history/session_booking_card.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../../route/route_module.dart';
import '../../utils/common_appbar.dart';
import '../../utils/view_extension.dart';
import 'booking_history_controller.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final BookingHistoryController controller = Get.put(
    BookingHistoryController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(
        controller.isDoctor.value ? "Doctor Dashboard" : "My Bookings",
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                _buildDateFilter(context),
                Expanded(
                  child: Obx(
                    () => controller.isLoading.value
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.medicalBlue,
                            ),
                          )
                        : (controller.upComingBookings.isEmpty
                              ? _buildEmptyState()
                              : _buildAppointmentsList()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final fromDate = Obx(
                () => buildDatePickerButton(
                  label: 'From',
                  date: controller.fromDate.value,
                  onTap: () => _selectDate(context, true),
                ),
              );
              final toDate = Obx(
                () => buildDatePickerButton(
                  label: 'To',
                  date: controller.toDate.value,
                  onTap: () => _selectDate(context, false),
                ),
              );
              if (constraints.maxWidth < 340) {
                return Column(
                  children: [fromDate, const SizedBox(height: 8), toDate],
                );
              }
              return Row(
                children: [
                  Expanded(child: fromDate),
                  const SizedBox(width: 12),
                  Expanded(child: toDate),
                ],
              );
            },
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilterChip(
                'Last 7 days',
                () => controller.applyQuickFilter(7),
              ),
              _buildQuickFilterChip(
                'Last 30 days',
                () => controller.applyQuickFilter(30),
              ),
              _buildQuickFilterChip(
                'This month',
                () => controller.filterCurrentMonth(),
              ),
            ],
          ),
        ],
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
          color: AppColors.medicalBlueLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.medicalBlue),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.medicalBlueDark,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? controller.fromDate.value
          : controller.toDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.medicalBlue),
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
      controller.getFilteredBookings();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: AppColors.medicalBlueLight),
          const SizedBox(height: 16),
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
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filter or book a new appointment',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              textStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppPage.selectServiceCity),
            icon: Icon(Icons.add),
            label: Text('Book New Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medicalBlue,
              foregroundColor: AppColors.textOnDark,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: controller.upComingBookings.length,
      itemBuilder: (context, index) {
        final appointment = controller.upComingBookings[index];
        return SessionBookingCard(appointment);
      },
    );
  }
}
