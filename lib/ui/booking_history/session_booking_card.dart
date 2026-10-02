import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:physio_connect/model/bookings_model.dart';
import 'package:physio_connect/ui/booking_history/show_html_editor_for_doctor_note.dart';
import 'package:physio_connect/ui/booking_history/booking_history_controller.dart';

import '../../route/route_module.dart';
import '../../utils/constants.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/units_extensions.dart';

class SessionBookingCard extends StatefulWidget {
  final BookingsModel appointment;

  const SessionBookingCard(this.appointment, {super.key});

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
    final timeslot = widget.appointment.aTimeslot();

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
        border: Border.all(color: AppColors.medicalBlueLight, width: 1),
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
                const Icon(
                  Icons.access_time,
                  color: AppColors.medicalBlueDark,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${timeslot.time} · ${formatDateAndMonth(widget.appointment.bookingDate)} · ${formatDateToWeekday(widget.appointment.bookingDate)}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.medicalBlueDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.medicalBlueLight,
                  child: Text(
                    (patient.name ?? "").isNotEmpty
                        ? (patient.name ?? "").substring(0, 1).toUpperCase()
                        : "?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.medicalBlueDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              patient.name ?? "Unknown Patient",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                widget.appointment.bookingStatus,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(
                                  widget.appointment.bookingStatus,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _formatStatus(widget.appointment.bookingStatus),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusColor(
                                    widget.appointment.bookingStatus,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sessionType.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              patient.mobileNumber ?? "No phone",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: "View Details",
                    icon: Icons.visibility,
                    color: AppColors.medicalBlue,
                    onTap: () {
                      final bookingController =
                          Get.find<BookingHistoryController>();
                      bookingController.selectedAppointment.value =
                          widget.appointment;
                      Get.toNamed(
                        AppPage.bookingDetail,
                        arguments: widget.appointment,
                      )?.then((value) {
                        if (mounted) setState(() {});
                      });
                    },
                    onLongPress: () {},
                  ),
                ),
                if (isDoctorTypeUser(controller.userModelSupabase))
                  Expanded(
                    child: _buildActionButton(
                      label: "Call Patient",
                      icon: Icons.call,
                      color: AppColors.wellnessGreen,
                      onLongPress: () async {
                        final phone = patient.mobileNumber ?? "";
                        final uri = Uri(scheme: 'tel', path: phone);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      onTap: () async {
                        final phone = patient.mobileNumber ?? "";
                        final whatsappUrl = Uri.parse("https://wa.me/$phone");
                        if (await canLaunchUrl(whatsappUrl)) {
                          await launchUrl(
                            whatsappUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ),
                if (isDoctorTypeUser(controller.userModelSupabase) == false)
                  Expanded(
                    child: _buildActionButton(
                      label: "Call Doctor",
                      icon: Icons.call,
                      color: AppColors.wellnessGreen,
                      onTap: () async {
                        controller.selectedAppointment.value = widget.appointment;
                        controller.sendReminderNotification();
                      },
                      onLongPress: () async {
                        controller.selectedAppointment.value = widget.appointment;
                        controller.sendReminderNotification();
                      },
                    ),
                  ),
                /*if (isDoctorTypeUser(controller.userModelSupabase))
                  Expanded(
                    child: _buildActionButton(
                      label: "Add Notes",
                      icon: Icons.note_add,
                      color: AppColors.therapyPurple,
                      onTap: () {
                        showHtmlEditorForDoctorNote(
                          context: Get.context!,
                          initialHtml: widget.appointment.doctorNotes ?? "",
                          onSave: (String updatedHtml) async {
                            widget.appointment.doctorNotes = updatedHtml;
                            await controller.updateDoctorNote(widget.appointment);
                            setState(() {});
                          },
                          title: "Edit Doctor's Note",
                        );
                      },
                      onLongPress: () {},
                    ),
                  ),*/
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 84),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
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
