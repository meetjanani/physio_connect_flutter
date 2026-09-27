import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:physio_connect/services/appointment_reminder_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/common_appbar.dart';
import '../../utils/constants.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_spacing.dart';

/// Patient Help / Support tab — cancel policy, contact, and share referral.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$SUPPORT_WHATSAPP');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: SUPPORT_EMAIL,
      query: 'subject=PhysioConnect Support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareApp() async {
    await Clipboard.setData(const ClipboardData(text: APP_SHARE_MESSAGE));
    Get.snackbar(
      'Link copied',
      'Share message copied. Paste it in WhatsApp or SMS.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar('Help & Support'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _card(
            title: 'Cancellation & refund policy',
            body:
                '• Cancel free if more than $FREE_CANCEL_HOURS hours before your session.\n'
                '• Within $FREE_CANCEL_HOURS hours, cancel is allowed but refunds may be partial.\n'
                '• If the doctor cancels, you are entitled to a full refund.\n',
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            title: 'Need help?',
            body: 'Reach us for booking, payment, or refund questions.',
            actions: [
              ListTile(
                leading: Icon(Icons.chat, color: AppColors.whatsapp),
                title: const Text('WhatsApp support'),
                onTap: _openWhatsApp,
              ),
              ListTile(
                leading:
                    Icon(Icons.email_outlined, color: AppColors.medicalBlue),
                title: Text(SUPPORT_EMAIL),
                onTap: _openEmail,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            title: 'Share PhysioConnect',
            body: 'Invite friends and family to book home physiotherapy.',
            actions: [
              ListTile(
                leading: Icon(Icons.share, color: AppColors.therapyPurple),
                title: const Text('Copy share message'),
                onTap: _shareApp,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            title: 'Care packages',
            body:
                'Book multiple sessions from Date & Time (every day / alternate / every 2 days) '
                'for recovery plans. Package pricing and care-plan SKUs will expand soon.',
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String body,
    List<Widget>? actions,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          if (actions != null) ...actions,
        ],
      ),
    );
  }
}
