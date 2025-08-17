import 'package:flutter/material.dart';

import '../utils/theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.filled,
    this.size = ButtonSize.medium,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.width,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;
    final effectiveWidth = width ?? double.infinity;
    
    return SizedBox(
      width: effectiveWidth,
      child: _buildButton(context, isDisabled),
    );
  }

  Widget _buildButton(BuildContext context, bool isDisabled) {
    if (gradient != null && type == ButtonType.filled) {
      return _buildGradientButton(context, isDisabled);
    }
    
    switch (type) {
      case ButtonType.filled:
        return _buildFilledButton(context, isDisabled);
      case ButtonType.outlined:
        return _buildOutlinedButton(context, isDisabled);
      case ButtonType.text:
        return _buildTextButton(context, isDisabled);
    }
  }

  Widget _buildGradientButton(BuildContext context, bool isDisabled) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDisabled ? null : gradient,
        color: isDisabled ? Colors.grey.shade300 : null,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: _getPadding(),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
        child: _buildButtonContent(context, isDisabled),
      ),
    );
  }

  Widget _buildFilledButton(BuildContext context, bool isDisabled) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.medicalBlue,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        elevation: isDisabled ? 0 : 2,
      ),
      child: _buildButtonContent(context, isDisabled),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, bool isDisabled) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? AppColors.medicalBlue,
        side: BorderSide(
          color: isDisabled 
              ? Colors.grey.shade300 
              : (backgroundColor ?? AppColors.medicalBlue),
          width: 2,
        ),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
      child: _buildButtonContent(context, isDisabled),
    );
  }

  Widget _buildTextButton(BuildContext context, bool isDisabled) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor ?? AppColors.medicalBlue,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
      child: _buildButtonContent(context, isDisabled),
    );
  }

  Widget _buildButtonContent(BuildContext context, bool isDisabled) {
    if (isLoading) {
      return SizedBox(
        height: _getContentHeight(),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final textStyle = _getTextStyle(context, isDisabled);
    
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: _getIconSize(),
            color: textStyle.color,
          ),
          const SizedBox(width: 8),
          Text(text, style: textStyle),
        ],
      );
    }

    return Text(text, style: textStyle);
  }

  EdgeInsetsGeometry _getPadding() {
    if (padding != null) return padding!;
    
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getContentHeight() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle(BuildContext context, bool isDisabled) {
    final baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ) ?? const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    Color textColor;
    if (isDisabled) {
      textColor = Colors.grey.shade500;
    } else if (type == ButtonType.filled && gradient == null) {
      textColor = foregroundColor ?? Colors.white;
    } else if (type == ButtonType.filled && gradient != null) {
      textColor = Colors.white;
    } else {
      textColor = foregroundColor ?? AppColors.medicalBlue;
    }

    switch (size) {
      case ButtonSize.small:
        return baseStyle.copyWith(fontSize: 14, color: textColor);
      case ButtonSize.medium:
        return baseStyle.copyWith(fontSize: 16, color: textColor);
      case ButtonSize.large:
        return baseStyle.copyWith(fontSize: 18, color: textColor);
    }
  }
}

enum ButtonType { filled, outlined, text }

enum ButtonSize { small, medium, large }

// Specialized button variants
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonSize size;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      icon: icon,
      gradient: const LinearGradient(
        colors: AppColors.primaryGradientColors,
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonSize size;
  final IconData? icon;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      icon: icon,
      type: ButtonType.outlined,
      backgroundColor: AppColors.medicalBlue,
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonSize size;
  final IconData? icon;

  const DangerButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      icon: icon,
      backgroundColor: AppColors.error,
    );
  }
}

class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonSize size;
  final IconData? icon;

  const SuccessButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      icon: icon,
      backgroundColor: AppColors.success,
    );
  }
}
