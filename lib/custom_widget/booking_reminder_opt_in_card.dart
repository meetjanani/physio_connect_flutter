import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/appointment_reminder_service.dart';
import '../utils/theme/app_colors.dart';
import '../utils/theme/app_spacing.dart';

/// Optional prompt for session reminder alarms / notifications.
///
/// Does not request permission until the user taps Enable.
class BookingReminderOptInCard extends StatefulWidget {
  const BookingReminderOptInCard({
    super.key,
    this.onEnabled,
  });

  /// Called once after the user grants reminder access (e.g. schedule this booking).
  final Future<void> Function()? onEnabled;

  @override
  State<BookingReminderOptInCard> createState() =>
      _BookingReminderOptInCardState();
}

class _BookingReminderOptInCardState extends State<BookingReminderOptInCard>
    with WidgetsBindingObserver {
  bool _enabled = false;
  bool _busy = false;
  bool _didNotifyEnabled = false;
  bool _enabledOnFirstCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh(isFirstCheck: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh({bool isFirstCheck = false}) async {
    final ok = await AppointmentReminderService.instance.hasPermissions();
    if (!mounted) return;
    setState(() {
      _enabled = ok;
      if (isFirstCheck) _enabledOnFirstCheck = ok;
    });
    if (ok && !isFirstCheck && !_enabledOnFirstCheck) {
      await _notifyEnabledOnce();
    }
  }

  Future<void> _notifyEnabledOnce() async {
    if (_didNotifyEnabled) return;
    _didNotifyEnabled = true;
    await widget.onEnabled?.call();
  }

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await AppointmentReminderService.instance.requestPermissions();
      if (!mounted) return;
      setState(() => _enabled = ok);
      if (ok) {
        await _notifyEnabledOnce();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.wellnessGreenLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.wellnessGreen.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.wellnessGreenDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reminders are on. You will get an alarm or notification before upcoming bookings.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.medicalBlueLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.medicalBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.alarm_outlined,
                color: AppColors.medicalBlueDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get reminder alarms',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optional. Turn on notifications and reminder alarms for your upcoming bookings.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _enable,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Enable reminders',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.medicalBlueDark,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
