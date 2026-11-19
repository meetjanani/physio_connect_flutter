import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/theme/app_colors.dart';

/// Outcome of [showWebUpiPaymentDialog].
enum WebUpiPaymentResult { paid, failed, cancelled }

/// Website-only payment sheet (Razorpay Payment Link + UPI QR).
///
/// Used while the website domain is not approved for embedded Razorpay
/// Checkout. The Android app keeps using the native Razorpay SDK.
///
/// * "Pay on this phone" opens the Payment Link (UPI apps, cards, …).
/// * "Scan QR" shows the UPI QR for paying from another phone.
/// * [checkStatus] is polled every few seconds and on "I have paid"; it must
///   return 'SUCCESS', 'FAILED' or anything else for pending.
Future<WebUpiPaymentResult> showWebUpiPaymentDialog({
  required int amountPaise,
  required String description,
  String? paymentLinkUrl,
  String? qrCodeUrl,
  required Future<String> Function() checkStatus,
}) {
  assert(paymentLinkUrl != null || qrCodeUrl != null);
  final completer = Completer<WebUpiPaymentResult>();
  Timer? pollTimer;
  var checking = false;

  void finish(WebUpiPaymentResult result) {
    pollTimer?.cancel();
    if (completer.isCompleted) return;
    if (Get.isDialogOpen == true) Get.back();
    completer.complete(result);
  }

  Future<void> checkNow({bool showPending = false}) async {
    if (checking || completer.isCompleted) return;
    checking = true;
    try {
      final status = await checkStatus();
      if (status == 'SUCCESS') {
        finish(WebUpiPaymentResult.paid);
      } else if (status == 'FAILED') {
        finish(WebUpiPaymentResult.failed);
      } else if (showPending) {
        Get.snackbar(
          'Awaiting confirmation',
          'We have not received the payment yet. If you have paid, '
              'please wait a few seconds.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      checking = false;
    }
  }

  pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => checkNow());

  final link = paymentLinkUrl;
  // Razorpay's own QR image when available; otherwise encode the link.
  final qrImage = qrCodeUrl ??
      'https://api.qrserver.com/v1/create-qr-code/?size=260x260&margin=10'
          '&data=${Uri.encodeComponent(link!)}';
  final amount = (amountPaise / 100)
      .toStringAsFixed(amountPaise % 100 == 0 ? 0 : 2);

  Future<void> openLink() async {
    if (link == null) return;
    await launchUrl(Uri.parse(link), webOnlyWindowName: '_blank');
  }

  Get.dialog<void>(
    PopScope(
      canPop: false,
      child: _WebUpiDialogBody(
        amountLabel: '₹$amount',
        description: description,
        hasLink: link != null,
        qrImage: qrImage,
        onOpenLink: openLink,
        onVerify: () => checkNow(showPending: true),
        onClose: () async {
          // One last check so a just-completed payment isn't reported as
          // cancelled.
          await checkNow();
          finish(WebUpiPaymentResult.cancelled);
        },
      ),
    ),
    barrierDismissible: false,
  );

  return completer.future;
}

class _WebUpiDialogBody extends StatefulWidget {
  const _WebUpiDialogBody({
    required this.amountLabel,
    required this.description,
    required this.hasLink,
    required this.qrImage,
    required this.onOpenLink,
    required this.onVerify,
    required this.onClose,
  });

  final String amountLabel;
  final String description;
  final bool hasLink;
  final String qrImage;
  final VoidCallback onOpenLink;
  final VoidCallback onVerify;
  final VoidCallback onClose;

  @override
  State<_WebUpiDialogBody> createState() => _WebUpiDialogBodyState();
}

class _WebUpiDialogBodyState extends State<_WebUpiDialogBody> {
  // Phones default to "pay on this phone", desktops to "scan QR".
  late int _tab =
      widget.hasLink && MediaQuery.sizeOf(Get.context!).width < 600 ? 0 : 1;

  @override
  Widget build(BuildContext context) {
    final text = GoogleFonts.inter();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.medicalBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.medicalBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pay ${widget.amountLabel}',
                          style: text.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.copyWith(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.hasLink) ...[
                _TabSwitcher(
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 16),
              ],
              if (_tab == 0 && widget.hasLink)
                _PayOnThisDevice(onOpenLink: widget.onOpenLink, text: text)
              else
                _ScanQr(
                  qrImage: widget.qrImage,
                  hasLink: widget.hasLink,
                  onOpenLink: widget.onOpenLink,
                  text: text,
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.medicalBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for payment confirmation…',
                    style: text.copyWith(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: widget.onVerify,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  'I have paid — verify now',
                  style: text.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(int index, IconData icon, String label) {
      final active = selected == index;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? AppColors.medicalBlue : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppColors.medicalBlue
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          tab(0, Icons.phone_iphone_rounded, 'Pay on this device'),
          tab(1, Icons.qr_code_2_rounded, 'Scan QR code'),
        ],
      ),
    );
  }
}

class _PayOnThisDevice extends StatelessWidget {
  const _PayOnThisDevice({required this.onOpenLink, required this.text});

  final VoidCallback onOpenLink;
  final TextStyle text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.medicalBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.medicalBlue.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Opens a secure Razorpay page in a new tab. Pay with any UPI '
                'app (GPay, PhonePe, Paytm, BHIM) or card.',
                textAlign: TextAlign.center,
                style: text.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicalBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onOpenLink,
                icon: const Icon(Icons.lock_outline_rounded, size: 20),
                label: Text(
                  'Pay now',
                  style: text.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'After paying, come back to this tab — your booking is confirmed '
          'automatically.',
          textAlign: TextAlign.center,
          style: text.copyWith(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ScanQr extends StatelessWidget {
  const _ScanQr({
    required this.qrImage,
    required this.hasLink,
    required this.onOpenLink,
    required this.text,
  });

  final String qrImage;
  final bool hasLink;
  final VoidCallback onOpenLink;
  final TextStyle text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Image.network(
            qrImage,
            width: 220,
            height: 220,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
            errorBuilder: (context, error, stack) => SizedBox(
              width: 220,
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'QR code could not load',
                    style: text.copyWith(fontSize: 12, color: Colors.grey),
                  ),
                  if (hasLink)
                    TextButton(
                      onPressed: onOpenLink,
                      child: const Text('Open payment page instead'),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Scan with GPay, PhonePe, Paytm or BHIM on your phone.',
          textAlign: TextAlign.center,
          style: text.copyWith(fontSize: 12, color: AppColors.textPrimary),
        ),
        if (hasLink)
          TextButton.icon(
            onPressed: onOpenLink,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Or pay by card / UPI ID on the payment page'),
          ),
      ],
    );
  }
}
