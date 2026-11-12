import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/verification_purpose.dart';
import '../viewmodels/auth_form_view_models.dart';
import '../widgets/auth_widgets.dart';
import 'support_footer.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final ok = await ref.read(forgotPasswordViewModelProvider.notifier).submit(email);
    if (!ok || !mounted) return;
    context.pushNamed(
      RouteNames.verifyEmail,
      queryParameters: {
        RouteParams.email: email,
        RouteParams.purpose: VerificationPurpose.resetPassword.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordViewModelProvider);
    return AuthScaffold(
      showBack: true,
      footer: const SupportFooter(),
      children: [
        const AuthHeader(
          title: 'Forgot your password?',
          subtitle: "Enter your email address and\nwe'll send you a code to reset your password.",
          topSpacing: AppSpacing.xxl,
        ),
        const SizedBox(height: AppSpacing.giant + AppSpacing.giant),
        Form(
          key: _formKey,
          child: AppTextField(
            controller: _email,
            hint: 'hello@appname.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
            onChanged: (_) => ref.read(forgotPasswordViewModelProvider.notifier).clearError(),
          ),
        ),
        AuthErrorText(state.errorMessage),
        const SizedBox(height: AppSpacing.huge),
        AppButton(label: 'Submit', isLoading: state.isSubmitting, onPressed: _submit),
      ],
    );
  }
}
