import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
    await SharePlus.instance.share(ShareParams(text: APP_SHARE_MESSAGE));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar('Help & Support'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // About us section
          const SizedBox(height: AppSpacing.md),
          _card(
            context: context,
            title: 'About Us (Physio Connect)',
            icon: Icons.info_outline,
            body:
                '• Your trusted platform for physiotherapy services, connecting patients with expert physiotherapists for personalized care.',
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            context: context,
            title: 'Share PhysioConnect',
            icon: Icons.share_outlined,
            body: 'Invite friends and family to book home physiotherapy.',
            actions: [
              ListTile(
                leading: Icon(Icons.share, color: AppColors.therapyPurple),
                title: const Text('Share with friends'),
                subtitle: const Text(
                  'Choose WhatsApp, Instagram, or another app',
                ),
                onTap: _shareApp,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            context: context,
            title: 'Need help?',
            icon: Icons.support_agent,
            body: 'Reach us for booking, payment, or refund questions.',
            actions: [
              ListTile(
                leading: Icon(Icons.chat, color: AppColors.whatsapp),
                title: const Text('WhatsApp support'),
                onTap: _openWhatsApp,
              ),
              ListTile(
                leading: Icon(
                  Icons.email_outlined,
                  color: AppColors.medicalBlue,
                ),
                title: Text(SUPPORT_EMAIL),
                onTap: _openEmail,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            context: context,
            title: 'Cancellation & refund policy',
            icon: Icons.policy_outlined,
            body:
                '• Cancel free if more than $FREE_CANCEL_HOURS hours before your session.\n'
                '• Within $FREE_CANCEL_HOURS hours, cancel is allowed but refunds may be partial.\n'
                '• If the doctor cancels, you are entitled to a full refund.\n',
          ),
        ],
      ),
    );
  }

  Widget _card({
    required BuildContext context,
    required String title,
    required String body,
    IconData icon = Icons.info_outline,
    List<Widget>? actions,
  }) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
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
          _cardTitle(
            context: context,
            title: title,
            icon: icon,
            borderRadius: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                if (actions != null) ...actions,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTitle({
    required BuildContext context,
    required String title,
    required IconData icon,
    double borderRadius = 20,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.medicalBlue, AppColors.wellnessGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
