// lib/ui/booking/history/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

import '../../model/appointment_model.dart';
import 'booking_history_controller.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingHistoryController controller = Get.find<BookingHistoryController>();
  final String appointmentId = Get.arguments as String;

  BookingDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.loadAppointmentDetails(appointmentId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointment Details',
          style: GoogleFonts.inter(
            textStyle: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        backgroundColor: AppColors.therapyPurple,
        foregroundColor: Colors.white,
      ),
      body: Obx(() => controller.isLoadingDetails.value
        ? Center(child: CircularProgressIndicator())
        : controller.selectedAppointment.value == null
          ? _buildErrorState()
          : _buildDetailsContent(context),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'Appointment not found',
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
            "The appointment you're looking for does not exist",
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.therapyPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContent(BuildContext context) {
    final appointment = controller.selectedAppointment.value!;
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final dateObj = DateFormat('yyyy-MM-dd').parse(appointment.date);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(appointment.status),
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(appointment.status),
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getStatusDescription(appointment.status),
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Appointment info
          Text(
            'Appointment Details',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildInfoCard([
            _buildInfoRow(
              'Session Type',
              appointment.sessionTypeName,
              Icons.healing,
            ),
            _buildInfoRow(
              'Date',
              dateFormatter.format(dateObj),
              Icons.calendar_today,
            ),
            _buildInfoRow(
              'Time',
              '${appointment.startTime} - ${appointment.endTime}',
              Icons.access_time,
            ),
            _buildInfoRow(
              'Duration',
              '${appointment.durationMinutes} minutes',
              Icons.timelapse,
            ),
          ]),

          SizedBox(height: 24),

          // Therapist info
          Text(
            'Therapist',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildTherapistCard(appointment),

          SizedBox(height: 24),

          // Payment info
          Text(
            'Payment Information',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildInfoCard([
            _buildInfoRow(
              'Amount',
              '₹${appointment.amount.toStringAsFixed(0)}',
              Icons.payments,
              valueColor: AppColors.therapyPurple,
              valueBold: true,
            ),
            _buildInfoRow(
              'Status',
              appointment.paymentStatus,
              Icons.check_circle,
              valueColor: _getPaymentStatusColor(appointment.paymentStatus),
            ),
            if (appointment.razorpayPaymentId.isNotEmpty)
              _buildInfoRow(
                'Transaction ID',
                appointment.razorpayPaymentId,
                Icons.receipt_long,
                valueStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
          ]),

          SizedBox(height: 24),

          // Notes
          if (appointment.doctorNotes.isNotEmpty) ...[
            Text(
              'Doctor\'s Notes',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildNotesCard(appointment.doctorNotes),
            SizedBox(height: 24),
          ],

          // Actions
          if (appointment.status == 'booked') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Show reschedule dialog/screen
                    },
                    icon: Icon(Icons.edit_calendar),
                    label: Text('Reschedule'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.therapyPurple),
                      foregroundColor: AppColors.therapyPurple,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showCancellationDialog(context);
                    },
                    icon: Icon(Icons.cancel_outlined),
                    label: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.red.shade400),
                      foregroundColor: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (index) {
          if (index.isEven) {
            return children[index ~/ 2];
          } else {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            );
          }
        }),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool valueBold = false,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.therapyPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.therapyPurple,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
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
                value,
                style: valueStyle ?? GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTherapistCard(AppointmentDetails appointment) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(appointment.therapistImage),
            backgroundColor: AppColors.therapyPurple.withOpacity(0.1),
            child: appointment.therapistImage.isEmpty
                ? Icon(Icons.person, color: AppColors.therapyPurple)
                : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.therapistName,
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
                  'Physiotherapist • ${appointment.therapistSpecialization}',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${appointment.therapistRating} • ${appointment.therapistExperience} years experience',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Call therapist action
            },
            icon: Icon(Icons.call, size: 16),
            label: Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wellnessGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(80, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.therapyPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                color: AppColors.therapyPurple,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recommendations & Precautions',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.therapyPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            notes,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancellationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Appointment',
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this appointment?',
              style: GoogleFonts.inter(),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cancellations within 24 hours may be subject to a fee.',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Appointment',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.cancelAppointment(appointmentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Cancel Appointment',
              style: GoogleFonts.inter(),
            ),
          ),
        ],
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return Icons.event_available;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'no-show':
        return Icons.event_busy;
      default:
        return Icons.event_note;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return 'Upcoming Appointment';
      case 'completed':
        return 'Completed Session';
      case 'cancelled':
        return 'Cancelled Appointment';
      case 'no-show':
        return 'Missed Appointment';
      default:
        return status.capitalize!;
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return 'Your session is scheduled and confirmed';
      case 'completed':
        return 'Your session has been successfully completed';
      case 'cancelled':
        return 'This appointment was cancelled';
      case 'no-show':
        return 'You did not attend this appointment';
      default:
        return '';
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.wellnessGreen;
      case 'pending':
        return Colors.orange.shade700;
      case 'failed':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }
}