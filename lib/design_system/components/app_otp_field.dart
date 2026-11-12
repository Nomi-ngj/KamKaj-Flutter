import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/tokens.dart';

/// Six-box verification code input with auto-advance and backspace handling.
class AppOtpField extends StatefulWidget {
  const AppOtpField({
    super.key,
    required this.onChanged,
    this.length = 6,
    this.hasError = false,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes = List.generate(widget.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length == 2) {
      // Typed over an existing digit: keep the newest one.
      _controllers[index].text = value.substring(1);
      value = value.substring(1);
    } else if (value.length > 2) {
      _distributePaste(value);
      return;
    }
    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    widget.onChanged(_code);
  }

  void _distributePaste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '').split('');
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final next = digits.length.clamp(0, widget.length - 1);
    _nodes[next].requestFocus();
    widget.onChanged(_code);
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    final isBackspace = event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace;
    if (isBackspace && _controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
      widget.onChanged(_code);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Verification code, ${widget.length} digits',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < widget.length; i++)
            SizedBox.square(
              dimension: AppDimensions.otpBoxSize,
              child: Focus(
                onKeyEvent: (_, event) => _onKey(i, event),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: AppRadius.brSm,
                    boxShadow: AppShadows.field,
                  ),
                  child: TextField(
                    key: ValueKey('otp_$i'),
                    controller: _controllers[i],
                    focusNode: _nodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    textInputAction:
                        i == widget.length - 1 ? TextInputAction.done : TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTypography.subhead,
                    cursorColor: AppColors.primary,
                    onChanged: (value) => _onChanged(i, value),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.inputFillWarm,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.brSm,
                        borderSide: widget.hasError
                            ? const BorderSide(color: AppColors.error)
                            : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.brSm,
                        borderSide: widget.hasError
                            ? const BorderSide(color: AppColors.error)
                            : BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppRadius.brSm,
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
