import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/tokens.dart';

enum AppTextFieldStyle {
  /// Peach filled field with soft shadow (auth screens).
  warm,

  /// White field with outlined label (address form, notes).
  outlined,
}

/// Text input used by every form. Password fields get a visibility toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.errorText,
    this.trailingIcon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofillHints,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.style = AppTextFieldStyle.warm,
    this.fieldKey,
  });

  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final String? errorText;
  final IconData? trailingIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? minLines;
  final bool enabled;
  final AppTextFieldStyle style;

  /// Key applied to the inner [TextFormField] (useful in tests).
  final Key? fieldKey;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.isPassword;

  void _toggleObscured() => setState(() => _obscured = !_obscured);

  @override
  Widget build(BuildContext context) {
    final isWarm = widget.style == AppTextFieldStyle.warm;
    final trailing = widget.isPassword
        ? IconButton(
            tooltip: _obscured ? 'Show password' : 'Hide password',
            onPressed: _toggleObscured,
            icon: Icon(
              _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.secondary,
              size: AppDimensions.iconMd,
            ),
          )
        : widget.trailingIcon == null
            ? null
            : Icon(widget.trailingIcon, color: AppColors.secondary, size: AppDimensions.iconMd);

    final border = OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: isWarm ? BorderSide.none : const BorderSide(color: AppColors.border),
    );

    final field = TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      obscureText: _obscured,
      obscuringCharacter: '•',
      enableSuggestions: !widget.isPassword,
      autocorrect: !widget.isPassword,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      enabled: widget.enabled,
      style: AppTypography.caption1.copyWith(color: AppColors.textPrimary),
      cursorColor: AppColors.primary,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        hintText: widget.hint,
        labelText: isWarm ? null : widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: AppTypography.label.copyWith(color: AppColors.textSecondary),
        hintStyle: AppTypography.caption1.copyWith(color: AppColors.textTertiary),
        errorText: widget.errorText,
        errorStyle: AppTypography.caption2.copyWith(color: AppColors.error),
        filled: true,
        fillColor: isWarm ? AppColors.inputFillWarm : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        suffixIcon: trailing,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );

    if (!isWarm) return field;

    // Warm fields carry the Figma drop shadow; it sits behind the input only.
    return Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: AppDimensions.inputHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.brSm,
              boxShadow: AppShadows.field,
            ),
          ),
        ),
        field,
      ],
    );
  }
}
