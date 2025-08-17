import 'package:flutter/material.dart';

/// PhysioConnect Color Palette
/// 
/// Healthcare-focused color scheme that matches the web application
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  static const Color uploadImageDottedBorderColor = Color(0xFFE0E0E0);

  // Primary Healthcare Colors
  static const Color medicalBlue = Color(0xFF0EA5E9);
  static const Color medicalBlueLight = Color(0xFFE0F2FE);
  static const Color medicalBlueDark = Color(0xFF0369A1);
  
  static const Color wellnessGreen = Color(0xFF22C55E);
  static const Color wellnessGreenLight = Color(0xFFDCFCE7);
  static const Color wellnessGreenDark = Color(0xFF15803D);
  
  static const Color therapyPurple = Color(0xFFA855F7);
  static const Color therapyPurpleLight = Color(0xFFFAE8FF);
  static const Color therapyPurpleDark = Color(0xFF7C3AED);

  // Neutral Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = wellnessGreen;
  static const Color successLight = wellnessGreenLight;
  static const Color successDark = wellnessGreenDark;
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);
  
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);
  
  static const Color info = medicalBlue;
  static const Color infoLight = medicalBlueLight;
  static const Color infoDark = medicalBlueDark;

  // Border & Divider Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);

  // Shadow Colors
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowDark = Color(0x26000000);

  // Overlay Colors
  static const Color overlayLight = Color(0x0D000000);
  static const Color overlayMedium = Color(0x1A000000);
  static const Color overlayDark = Color(0x33000000);

  // Specialty Colors (for different physiotherapy specialties)
  static const Color orthopedic = Color(0xFF8B5CF6);
  static const Color neurological = Color(0xFF06B6D4);
  static const Color pediatric = Color(0xFFF97316);
  static const Color geriatric = Color(0xFF84CC16);
  static const Color sports = Color(0xFFEC4899);
  static const Color cardiopulmonary = Color(0xFF3B82F6);

  // Rating Colors
  static const Color ratingGold = Color(0xFFFBBF24);
  static const Color ratingSilver = Color(0xFF9CA3AF);
  static const Color ratingBronze = Color(0xFFD97706);

  // Availability Status Colors
  static const Color available = wellnessGreen;
  static const Color busy = warning;
  static const Color unavailable = error;
  static const Color pending = medicalBlue;

  // Booking Status Colors
  static const Color confirmed = wellnessGreen;
  static const Color cancelled = error;
  static const Color completed = therapyPurple;
  static const Color inProgress = medicalBlue;
  static const Color rescheduled = warning;

  // Payment Status Colors
  static const Color paid = wellnessGreen;
  static const Color unpaid = error;
  static const Color refunded = warning;
  static const Color processing = medicalBlue;

  // Priority Colors
  static const Color priorityHigh = error;
  static const Color priorityMedium = warning;
  static const Color priorityLow = wellnessGreen;

  // Social Media Brand Colors
  static const Color facebook = Color(0xFF1877F2);
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color google = Color(0xFF4285F4);
  static const Color apple = Color(0xFF000000);
  static const Color linkedin = Color(0xFF0077B5);
  static const Color whatsapp = Color(0xFF25D366);

  // Gradient Stops
  static const List<Color> primaryGradientColors = [medicalBlue, wellnessGreen];
  static const List<Color> secondaryGradientColors = [wellnessGreen, therapyPurple];
  static const List<Color> accentGradientColors = [therapyPurple, medicalBlue];
  static const List<Color> backgroundGradientColors = [
    medicalBlueLight,
    Color(0xFFFFFFFF),
    wellnessGreenLight,
  ];

  // Chart Colors (for analytics and reporting)
  static const List<Color> chartColors = [
    medicalBlue,
    wellnessGreen,
    therapyPurple,
    warning,
    error,
    orthopedic,
    neurological,
    pediatric,
    geriatric,
    sports,
  ];

  // Shimmer Colors (for loading states)
  static const Color shimmerBase = Color(0xFFF3F4F6);
  static const Color shimmerHighlight = Color(0xFFFFFFFF);

  // Helper methods for color variations
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  // Color schemes for different contexts
  static const Map<String, Color> statusColors = {
    'success': success,
    'warning': warning,
    'error': error,
    'info': info,
  };

  static const Map<String, Color> specialtyColors = {
    'orthopedic': orthopedic,
    'neurological': neurological,
    'pediatric': pediatric,
    'geriatric': geriatric,
    'sports': sports,
    'cardiopulmonary': cardiopulmonary,
  };

  static const Map<String, Color> bookingStatusColors = {
    'confirmed': confirmed,
    'cancelled': cancelled,
    'completed': completed,
    'in_progress': inProgress,
    'rescheduled': rescheduled,
  };

  static const Map<String, Color> paymentStatusColors = {
    'paid': paid,
    'unpaid': unpaid,
    'refunded': refunded,
    'processing': processing,
  };

  // Material Color Swatches
  static const MaterialColor medicalBlueSwatch = MaterialColor(
    0xFF0EA5E9,
    <int, Color>{
      50: Color(0xFFE0F2FE),
      100: Color(0xFFB3E5FC),
      200: Color(0xFF81D4FA),
      300: Color(0xFF4FC3F7),
      400: Color(0xFF29B6F6),
      500: Color(0xFF0EA5E9),
      600: Color(0xFF039BE5),
      700: Color(0xFF0288D1),
      800: Color(0xFF0277BD),
      900: Color(0xFF01579B),
    },
  );

  static const MaterialColor wellnessGreenSwatch = MaterialColor(
    0xFF22C55E,
    <int, Color>{
      50: Color(0xFFDCFCE7),
      100: Color(0xFFBBF7D0),
      200: Color(0xFF86EFAC),
      300: Color(0xFF4ADE80),
      400: Color(0xFF22C55E),
      500: Color(0xFF16A34A),
      600: Color(0xFF15803D),
      700: Color(0xFF166534),
      800: Color(0xFF14532D),
      900: Color(0xFF052E16),
    },
  );

  static const MaterialColor therapyPurpleSwatch = MaterialColor(
    0xFFA855F7,
    <int, Color>{
      50: Color(0xFFFAF5FF),
      100: Color(0xFFF3E8FF),
      200: Color(0xFFE9D5FF),
      300: Color(0xFFD8B4FE),
      400: Color(0xFFC084FC),
      500: Color(0xFFA855F7),
      600: Color(0xFF9333EA),
      700: Color(0xFF7C3AED),
      800: Color(0xFF6B21A8),
      900: Color(0xFF581C87),
    },
  );
}

/// Extension methods for Color class
extension ColorExtensions on Color {
  /// Convert color to hex string
  String toHex() {
    return '#${value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Get contrasting text color (black or white)
  Color get contrastingTextColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Create a lighter version of the color
  Color lighter([double amount = 0.1]) {
    return AppColors.lighten(this, amount);
  }

  /// Create a darker version of the color
  Color darker([double amount = 0.1]) {
    return AppColors.darken(this, amount);
  }
}
