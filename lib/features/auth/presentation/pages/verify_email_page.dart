import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/verification_purpose.dart';
import '../viewmodels/auth_form_view_models.dart';
import '../widgets/auth_widgets.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.email, required this.purpose});

  final String email;
  final VerificationPurpose purpose;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  String _code = '';

  Future<void> _verify() async {
    final ok = await ref
        .read(verifyCodeViewModelProvider.notifier)
        .verify(email: widget.email, code: _code, purpose: widget.purpose);
    if (!ok || !mounted) return;
    if (widget.purpose == VerificationPurpose.resetPassword) {
      context.pushReplacementNamed(
        RouteNames.resetPassword,
        queryParameters: {RouteParams.email: widget.email},
      );
    }
    // Sign-up verification signs the user in; the router redirects to Home.
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyCodeViewModelProvider);
    final resendLabel = state.canResend
        ? 'Resend Code'
        : 'Resend Code(${state.resendSecondsLeft}s)';

    return AuthScaffold(
      showBack: true,
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text("Didn't receive the code?", style: AppTypography.caption1),
          TextButton(
            onPressed: state.canResend
                ? () => ref
                    .read(verifyCodeViewModelProvider.notifier)
                    .resend(email: widget.email, purpose: widget.purpose)
                : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
              disabledForegroundColor: AppColors.secondary,
            ),
            child: Text(
              resendLabel,
              style: AppTypography.caption1.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
      children: [
        const AuthHeader(
          title: 'Verify Your Email',
          subtitle: "We've sent a 6-digit code to your\nemail address.",
          topSpacing: AppSpacing.xxl,
        ),
        const SizedBox(height: AppSpacing.giant * 2),
        AppOtpField(
          hasError: state.submit.failure != null,
          onChanged: (code) => setState(() => _code = code),
        ),
        AuthErrorText(state.submit.errorMessage),
        const SizedBox(height: AppSpacing.xxxl),
        AppButton(
          label: 'Verify Code',
          isLoading: state.submit.isSubmitting,
          onPressed: _code.length == 6 ? _verify : null,
        ),
      ],
    );
  }
}
