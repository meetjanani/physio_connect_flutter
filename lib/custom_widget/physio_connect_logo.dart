import 'package:flutter/material.dart';
import '../utils/theme/app_colors.dart';

enum LogoSize { small, medium, large, extraLarge }

enum LogoVariant { colored, white, dark }

class PhysioConnectLogo extends StatelessWidget {
  final LogoSize size;
  final LogoVariant variant;
  final bool showText;
  final EdgeInsets? padding;

  const PhysioConnectLogo({
    Key? key,
    this.size = LogoSize.medium,
    this.variant = LogoVariant.colored,
    this.showText = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(context),
          if (showText) ...[
            const SizedBox(width: 8),
            _buildText(context),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final iconSize = _getIconSize();
    final colors = _getColors(context);
    
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.gradientColors,
        ),
      ),
      child: CustomPaint(
        painter: HeartPulsePainter(
          color: colors.iconColor,
          strokeWidth: _getStrokeWidth(),
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    final textStyle = _getTextStyle(context);
    
    if (variant == LogoVariant.white) {
      return Text(
        'PhysioConnect',
        style: textStyle.copyWith(color: Colors.white),
      );
    }
    
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: AppColors.primaryGradientColors,
      ).createShader(bounds),
      child: Text(
        'PhysioConnect',
        style: textStyle.copyWith(color: Colors.white),
      ),
    );
  }

  double _getIconSize() {
    switch (size) {
      case LogoSize.small:
        return 24;
      case LogoSize.medium:
        return 32;
      case LogoSize.large:
        return 40;
      case LogoSize.extraLarge:
        return 48;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LogoSize.small:
        return 1.5;
      case LogoSize.medium:
        return 2.0;
      case LogoSize.large:
        return 2.5;
      case LogoSize.extraLarge:
        return 3.0;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
    ) ?? const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
    );

    switch (size) {
      case LogoSize.small:
        return baseStyle.copyWith(fontSize: 14);
      case LogoSize.medium:
        return baseStyle.copyWith(fontSize: 18);
      case LogoSize.large:
        return baseStyle.copyWith(fontSize: 22);
      case LogoSize.extraLarge:
        return baseStyle.copyWith(fontSize: 26);
    }
  }

  _LogoColors _getColors(BuildContext context) {
    switch (variant) {
      case LogoVariant.colored:
        return _LogoColors(
          gradientColors: AppColors.primaryGradientColors,
          iconColor: Colors.white,
        );
      case LogoVariant.white:
        return _LogoColors(
          gradientColors: [Colors.white, Colors.grey.shade100],
          iconColor: Colors.grey.shade800,
        );
      case LogoVariant.dark:
        return _LogoColors(
          gradientColors: [Colors.grey.shade800, Colors.grey.shade900],
          iconColor: Colors.white,
        );
    }
  }
}

class HeartPulsePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  HeartPulsePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 24;

    // Heart path
    final heartPath = Path();
    heartPath.moveTo(center.dx, center.dy + 2 * scale);
    
    // Left curve of heart
    heartPath.cubicTo(
      center.dx - 6 * scale, center.dy - 3 * scale,
      center.dx - 12 * scale, center.dy - 8 * scale,
      center.dx - 6 * scale, center.dy - 12 * scale,
    );
    heartPath.cubicTo(
      center.dx - 3 * scale, center.dy - 15 * scale,
      center.dx + 3 * scale, center.dy - 15 * scale,
      center.dx, center.dy - 12 * scale,
    );
    
    // Right curve of heart
    heartPath.cubicTo(
      center.dx + 3 * scale, center.dy - 15 * scale,
      center.dx + 9 * scale, center.dy - 15 * scale,
      center.dx + 6 * scale, center.dy - 12 * scale,
    );
    heartPath.cubicTo(
      center.dx + 12 * scale, center.dy - 8 * scale,
      center.dx + 6 * scale, center.dy - 3 * scale,
      center.dx, center.dy + 2 * scale,
    );

    canvas.drawPath(heartPath, paint);

    // Pulse line
    final pulsePaint = paint..strokeWidth = strokeWidth * 0.8;
    final pulseY = center.dy + 3 * scale;
    
    final pulsePath = Path();
    pulsePath.moveTo(center.dx - 8 * scale, pulseY);
    pulsePath.lineTo(center.dx - 4 * scale, pulseY);
    pulsePath.lineTo(center.dx - 2 * scale, pulseY - 4 * scale);
    pulsePath.lineTo(center.dx, pulseY + 4 * scale);
    pulsePath.lineTo(center.dx + 2 * scale, pulseY - 4 * scale);
    pulsePath.lineTo(center.dx + 4 * scale, pulseY);
    pulsePath.lineTo(center.dx + 8 * scale, pulseY);

    canvas.drawPath(pulsePath, pulsePaint);

    // Small dot for person indicator
    canvas.drawCircle(
      Offset(center.dx, center.dy + 1 * scale),
      1 * scale,
      Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoColors {
  final List<Color> gradientColors;
  final Color iconColor;

  _LogoColors({
    required this.gradientColors,
    required this.iconColor,
  });
}

// Helper widgets for common use cases
class PhysioConnectIconOnly extends StatelessWidget {
  final LogoSize size;
  final LogoVariant variant;

  const PhysioConnectIconOnly({
    Key? key,
    this.size = LogoSize.medium,
    this.variant = LogoVariant.colored,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PhysioConnectLogo(
      size: size,
      variant: variant,
      showText: false,
    );
  }
}

class PhysioConnectSplashLogo extends StatelessWidget {
  const PhysioConnectSplashLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PhysioConnectLogo(
          size: LogoSize.extraLarge,
          variant: LogoVariant.colored,
        ),
        const SizedBox(height: 12),
        Text(
          'Professional Physiotherapy Platform',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
