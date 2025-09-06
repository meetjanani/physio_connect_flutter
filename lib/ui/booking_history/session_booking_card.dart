import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:physio_connect/utils/enum.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:physio_connect/model/bookings_model.dart';
import 'package:physio_connect/ui/booking_history/show_html_editor_for_doctor_note.dart';
import 'package:physio_connect/ui/booking_history/booking_history_controller.dart';

import '../../route/route_module.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/units_extensions.dart';

class SessionBookingCard extends StatefulWidget {
  final BookingsModel appointment;

  const SessionBookingCard(this.appointment, {Key? key}) : super(key: key);

  @override
  State<SessionBookingCard> createState() => _SessionBookingCardState();
}

class _SessionBookingCardState extends State<SessionBookingCard> {
  late BookingHistoryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<BookingHistoryController>();
  }

  @override
  Widget build(BuildContext context) {
    final sessionType = widget.appointment.aSessionType();
    final patient = widget.appointment.aPatient();
    final doctor = widget.appointment.aDoctor();
    final timeslot = widget.appointment.aTimeslot();

    // Format the time to show start and end times
    final startTime = timeslot.time;

    // Calculate end time by adding duration
    final durationParts = sessionType.duration.split(' ');
    int durationMinutes = 30; // Default
    if (durationParts.length >= 2 && durationParts[1].contains('min')) {
      durationMinutes = int.tryParse(durationParts[0]) ?? 30;
    }

    // For future implementation
    // final startDateTime = DateTime(2022, 1, 1, 4, 0);
    // final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));
    // final endTime = "${4.toString().padLeft(2, '0')}:${45.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: AppColors.medicalBlueLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Appointment time header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.medicalBlueLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: AppColors.medicalBlueDark, size: 18),
                const SizedBox(width: 8),
                Text(
                  "${timeslot.time} - ${formatDateAndMonth(widget.appointment.bookingDate)} - ${formatDateToWeekday(widget.appointment.bookingDate)}",
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.medicalBlueDark,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.medicalBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sessionType.duration,
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Patient details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.medicalBlueLight,
                  child: Text(
                    (patient.name ?? "").isNotEmpty ? (patient.name ?? "").substring(0, 1).toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.medicalBlueDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name ?? "Unknown Patient",
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sessionType.name,
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.medicalBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            patient.mobileNumber ?? "No phone",
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Booking status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.appointment.bookingStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(widget.appointment.bookingStatus).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _formatStatus(widget.appointment.bookingStatus),
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(widget.appointment.bookingStatus),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                    label: "View Details",
                    icon: Icons.visibility,
                    color: AppColors.medicalBlue,
                    onTap: () {
                      BookingHistoryController bookingController = Get.find<BookingHistoryController>();
                      bookingController.selectedAppointment.value = widget.appointment;
                      Get.toNamed(
                          AppPage.bookingDetail,
                          arguments: widget.appointment
                      );
                    },
                    onLongPress: (){}
                ),
                if(patient.userType?.toLowerCase() == UserType.doctor.name)
                  _buildActionButton(
                    label: "Call Patient",
                    icon: Icons.call,
                    color: AppColors.wellnessGreen,
                    onTap: () async {
                      final phone = patient.mobileNumber ?? "";
                      final uri = Uri(scheme: 'tel', path: phone);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    onLongPress: () async {
                      final phone = patient.mobileNumber ?? "";
                      final whatsappUrl = Uri.parse("https://wa.me/$phone");
                      if (await canLaunchUrl(whatsappUrl)) {
                        await launchUrl(
                            whatsappUrl, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                // TODO: Add Doctor number & whatsapp.
                if(patient.userType?.toLowerCase() == UserType.patient.name)
                  _buildActionButton(
                    label: "Call Doctor",
                    icon: Icons.call,
                    color: AppColors.wellnessGreen,
                    onTap: () async {
                      final phone = doctor.name ?? "";
                      final uri = Uri(scheme: 'tel', path: phone);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    onLongPress: () async {
                      final phone = doctor.name ?? "";
                      final whatsappUrl = Uri.parse("https://wa.me/$phone");
                      if (await canLaunchUrl(whatsappUrl)) {
                        await launchUrl(
                            whatsappUrl, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                if(patient.userType?.toLowerCase() == UserType.doctor.name)
                  _buildActionButton(
                      label: "Add Notes",
                      icon: Icons.note_add,
                      color: AppColors.therapyPurple,
                      onTap: () {
                        showHtmlEditorForDoctorNote(
                          context: Get.context!,
                          initialHtml: widget.appointment.doctorNotes ?? "",
                          onSave: (String updatedHtml) async {
                            widget.appointment.doctorNotes = updatedHtml;
                            await controller.updateDoctorNote(widget
                                .appointment);
                            setState(() {});
                          },
                          title: "Edit Doctor's Note",
                        );
                      },
                      onLongPress: () {}
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
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
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return AppColors.wellnessGreen;
      case 'completed':
        return AppColors.medicalBlue;
      case 'cancelled':
        return AppColors.error;
      case 'no-show':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }
}
