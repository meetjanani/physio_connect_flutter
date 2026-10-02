import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/image.dart';
import '../utils/theme/app_colors.dart';
import '../utils/theme/app_spacing.dart';

/// Branded PhysioConnect loader. Use this widget anywhere you used a spinner.
///
/// Overlay a screen:
/// ```dart
/// PhysioProgressOverlay(
///   isLoading: controller.isLoading,
///   message: 'Loading your care…',
///   child: Scaffold(...),
/// )
/// ```
///
/// Full-page body:
/// ```dart
/// const PhysioProgressBar(message: 'Loading…')
/// ```
///
/// Modal dialog:
/// ```dart
/// PhysioProgressDialog.show(message: 'Saving…');
/// PhysioProgressDialog.hide();
/// ```
class PhysioProgressBar extends StatefulWidget {
  const PhysioProgressBar({
    super.key,
    this.message = 'A moment of care…',
    this.card = true,
  });

  final String message;
  final bool card;

  @override
  State<PhysioProgressBar> createState() => _PhysioProgressBarState();
}

class _PhysioProgressBarState extends State<PhysioProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: AnimatedBuilder(
            animation: Listenable.merge([_spin, _pulse]),
            builder: (context, child) {
              final scale = 0.94 + (_pulse.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: CustomPaint(
                  painter: _CareRingPainter(progress: _spin.value),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: child,
                  ),
                ),
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.medicalBlue.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: ColoredBox(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        AppImages.logo,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.primaryGradientColors,
          ).createShader(bounds),
          child: Text(
            'PhysioConnect',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _CareDots(),
      ],
    );

    if (!widget.card) {
      return Center(child: content);
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.medicalBlue.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}

class _CareRingPainter extends CustomPainter {
  _CareRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) / 2) - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = AppColors.medicalBlueLight;
    canvas.drawCircle(center, radius, track);

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          AppColors.medicalBlue,
          AppColors.wellnessGreen,
          AppColors.therapyPurple,
          AppColors.medicalBlue,
        ],
      ).createShader(rect);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.15, false, sweep);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CareRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CareDots extends StatefulWidget {
  const _CareDots();

  @override
  State<_CareDots> createState() => _CareDotsState();
}

class _CareDotsState extends State<_CareDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.medicalBlue,
      AppColors.wellnessGreen,
      AppColors.therapyPurple,
    ];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final t = (_controller.value + (index * 0.22)) % 1.0;
            final lift = math.sin(t * math.pi) * 4;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -lift),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Dims [child] and shows [PhysioProgressBar] when loading.
class PhysioProgressOverlay extends StatelessWidget {
  const PhysioProgressOverlay({
    super.key,
    required this.child,
    this.isLoading,
    this.visible,
    this.message = 'A moment of care…',
  });

  final Widget child;
  final RxBool? isLoading;
  final bool? visible;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (isLoading != null) {
      return Obx(() => _stack(isLoading!.value));
    }
    return _stack(visible ?? false);
  }

  Widget _stack(bool show) {
    return Stack(
      children: [
        child,
        if (show)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: AppColors.textPrimary.withValues(alpha: 0.28),
                child: PhysioProgressBar(message: message),
              ),
            ),
          ),
      ],
    );
  }
}

class PhysioProgressDialog {
  PhysioProgressDialog._();

  static bool _open = false;

  static void show({String message = 'A moment of care…'}) {
    if (_open || Get.isDialogOpen == true) return;
    _open = true;
    Get.dialog(
      PopScope(
        canPop: false,
        child: PhysioProgressBar(message: message),
      ),
      barrierDismissible: false,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.32),
    );
  }

  static void hide() {
    if (!_open) return;
    _open = false;
    if (Get.isDialogOpen == true && Get.overlayContext != null) {
      Navigator.of(Get.overlayContext!, rootNavigator: true).pop();
    }
  }
}
