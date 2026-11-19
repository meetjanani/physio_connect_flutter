import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:physio_connect/model/bookings_model.dart';
import 'package:physio_connect/services/online_session.dart';
import 'package:physio_connect/supabase/supabase_controller.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

class OnlineSessionActions extends StatelessWidget {
  const OnlineSessionActions({
    super.key,
    required this.booking,
    required this.isDoctor,
    this.compact = false,
    this.onChanged,
  });

  final BookingsModel booking;
  final bool isDoctor;
  final bool compact;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    if (!booking.isOnlineSession || !OnlineSession.isPaidOnline(booking)) {
      return const SizedBox.shrink();
    }
    final url = OnlineSession.meetingUrl(booking);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (url != null)
          ElevatedButton.icon(
            onPressed: () async {
              final opened = await OnlineSession.launchMeeting(url);
              if (!opened) {
                Get.snackbar(
                  'Could not open Meet',
                  'Copy the link from appointment details and open it in Chrome.',
                );
              }
            },
            icon: const Icon(Icons.videocam),
            label: Text(
              compact ? 'Join' : 'Join Google Meet',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medicalBlueDark,
              foregroundColor: AppColors.textOnDark,
              minimumSize: Size(double.infinity, compact ? 40 : 48),
            ),
          )
        else if (OnlineSession.isPaidOnline(booking))
          Text(
            isDoctor
                ? 'No Meet link yet. Create one or paste a Google Meet URL.'
                : 'Your Meet link will appear here after it is created.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        if (!compact && isDoctor) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openWhatsApp(),
            icon: const Icon(Icons.chat),
            label: Text(
              isDoctor ? 'WhatsApp patient' : "Can't join? WhatsApp",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          if (OnlineSession.isPaidOnline(booking)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _createMeet(context),
                    child: const Text('Create Meet'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pasteMeet(context),
                    child: const Text('Paste link'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _openWhatsApp() async {
    String? phone;
    if (isDoctor) {
      phone = booking.aPatient().mobileNumber;
    } else {
      final doctorUserId = booking.aDoctor().userId ?? booking.doctorId;
      final user = await SupabaseController.to.getUserById(doctorUserId);
      phone = user?.mobileNumber;
    }
    final opened = await OnlineSession.launchWhatsApp(
      phone,
      message: isDoctor
          ? 'Hello, this is your PhysioConnect session. Please join Google Meet from the app if you can.'
          : 'Hi doctor, I cannot join the Google Meet for my PhysioConnect session.',
    );
    if (!opened) {
      Get.snackbar(
        'WhatsApp',
        'Could not open WhatsApp. Check that a mobile number is saved.',
      );
    }
  }

  Future<void> _createMeet(BuildContext context) async {
    final userId = booking.doctorId;
    final results = await SupabaseController.to.ensureGoogleMeetForBookings(
      bookingIds: [booking.id],
      userId: userId,
    );
    final url = results
        .map((row) => row['meetingUrl']?.toString() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (url.isEmpty) {
      Get.snackbar(
        'Meet not created',
        'Google Calendar is not connected yet. Paste a Meet link instead.',
      );
      return;
    }
    booking.meetingUrl = url;
    booking.meetingProvider = 'google_meet';
    onChanged?.call();
    Get.snackbar('Meet ready', 'Patients can Join from the app.');
  }

  Future<void> _pasteMeet(BuildContext context) async {
    final field = TextEditingController(text: booking.meetingUrl ?? '');
    final saved = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Paste Google Meet link'),
        content: TextField(
          controller: field,
          decoration: const InputDecoration(
            hintText: 'https://meet.google.com/...',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Save')),
        ],
      ),
    );
    final url = field.text.trim();
    field.dispose();
    if (saved != true || url.isEmpty) return;
    await SupabaseController.to.updateBookingMeetingUrl(
      bookingId: booking.id,
      meetingUrl: url,
      provider: 'pasted',
    );
    booking.meetingUrl = url;
    booking.meetingProvider = 'pasted';
    onChanged?.call();
  }
}
