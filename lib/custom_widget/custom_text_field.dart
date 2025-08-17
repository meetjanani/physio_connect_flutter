import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final BorderRadius? borderRadius;

  const CustomTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.fillColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _isFocused 
                  ? AppColors.medicalBlue 
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: widget.enabled 
                ? AppColors.textPrimary 
                : AppColors.textMuted,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused 
                        ? AppColors.medicalBlue 
                        : AppColors.textMuted,
                  )
                : null,
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: widget.fillColor ?? 
                (widget.enabled 
                    ? (_isFocused 
                        ? AppColors.medicalBlueLight.withOpacity(0.1)
                        : Colors.grey.shade50)
                    : Colors.grey.shade100),
            contentPadding: widget.contentPadding ?? 
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: _buildBorder(AppColors.border),
            enabledBorder: _buildBorder(AppColors.border),
            focusedBorder: _buildBorder(AppColors.medicalBlue, width: 2),
            errorBorder: _buildBorder(AppColors.error, width: 2),
            focusedErrorBorder: _buildBorder(AppColors.error, width: 2),
            disabledBorder: _buildBorder(Colors.grey.shade300),
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textMuted,
            ),
            helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
            counterStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

// Specialized text field variants
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const EmailTextField({
    Key? key,
    this.controller,
    this.labelText = 'Email Address',
    this.hintText = 'Enter your email',
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.email_outlined,
      validator: validator ?? _defaultEmailValidator,
      onChanged: onChanged,
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
}

class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool showStrengthIndicator;

  const PasswordTextField({
    Key? key,
    this.controller,
    this.labelText = 'Password',
    this.hintText = 'Enter your password',
    this.validator,
    this.onChanged,
    this.showStrengthIndicator = false,
  }) : super(key: key);

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;
  PasswordStrength _strength = PasswordStrength.weak;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: widget.controller,
          labelText: widget.labelText,
          hintText: widget.hintText,
          obscureText: _obscureText,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: AppColors.textMuted,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
          validator: widget.validator ?? _defaultPasswordValidator,
          onChanged: (value) {
            if (widget.showStrengthIndicator) {
              setState(() {
                _strength = _calculatePasswordStrength(value);
              });
            }
            widget.onChanged?.call(value);
          },
        ),
        if (widget.showStrengthIndicator) ...[
          const SizedBox(height: 8),
          _buildPasswordStrengthIndicator(),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _getStrengthValue(),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getStrengthText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getStrengthColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getStrengthValue() {
    switch (_strength) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  Color _getStrengthColor() {
    switch (_strength) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.fair:
        return AppColors.warning;
      case PasswordStrength.good:
        return AppColors.medicalBlue;
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }

  String _getStrengthText() {
    switch (_strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.length < 8) return PasswordStrength.weak;
    
    int score = 0;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score < 2) return PasswordStrength.weak;
    if (score < 3) return PasswordStrength.fair;
    if (score < 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  String? _defaultPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }
}

class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const PhoneTextField({
    Key? key,
    this.controller,
    this.labelText = 'Phone Number',
    this.hintText = 'Enter your phone number',
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.phone_outlined,
      validator: validator ?? _defaultPhoneValidator,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
      ],
    );
  }

  String? _defaultPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}

enum PasswordStrength { weak, fair, good, strong }
