import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/assets/app_images.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../viewmodels/auth_form_view_models.dart';
import '../widgets/auth_widgets.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // On success the session changes and the router redirects to Home.
    await ref
        .read(signInViewModelProvider.notifier)
        .submit(email: _email.text, password: _password.text);
  }

  void _socialUnavailable() =>
      AppToast.show(context, 'Social sign-in will be available soon.');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInViewModelProvider);
    final viewModel = ref.read(signInViewModelProvider.notifier);

    return AuthScaffold(
      footer: AuthFooterLink(
        prompt: "Don't have an account?",
        action: 'Sign Up',
        onTap: () => context.pushNamed(RouteNames.signUp),
      ),
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        const Center(
          child: AppAssetImage(
            path: AppImages.appLogo,
            width: AppDimensions.logoSize,
            height: AppDimensions.logoSize,
            semanticLabel: 'App logo',
            placeholderIcon: Icons.local_shipping_rounded,
          ),
        ),
        const AuthHeader(
          title: 'Welcome to\nAppName',
          subtitle: 'Fresh delivery from your favorite local spots.',
          topSpacing: AppSpacing.xxl,
        ),
        const SizedBox(height: AppSpacing.massive),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                AppTextField(
                  fieldKey: const Key('signIn_email'),
                  controller: _email,
                  hint: 'hello@appname.com',
                  trailingIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  onChanged: (_) => viewModel.clearError(),
                ),
                kAuthFieldGap,
                AppTextField(
                  fieldKey: const Key('signIn_password'),
                  controller: _password,
                  hint: '••••••••',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => Validators.required(v, field: 'Password'),
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => viewModel.clearError(),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => context.pushNamed(RouteNames.forgotPassword),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            child: Text(
              'Forgot Password?',
              style: AppTypography.titleMedium.copyWith(color: AppColors.secondary),
            ),
          ),
        ),
        AuthErrorText(state.errorMessage),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          key: const Key('signIn_submit'),
          label: 'Sign In',
          isLoading: state.isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        const _OrDivider(),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppCircleIconButton(
              icon: Icons.apple_rounded,
              tooltip: 'Continue with Apple',
              onPressed: _socialUnavailable,
            ),
            const SizedBox(width: AppSpacing.lg),
            AppCircleIconButton(
              icon: Icons.g_mobiledata_rounded,
              tooltip: 'Continue with Google',
              color: AppColors.primary,
              onPressed: _socialUnavailable,
            ),
          ],
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.secondary)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OR CONTINUE WITH',
            style: AppTypography.caption4Medium.copyWith(color: AppColors.secondary),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.secondary)),
      ],
    );
  }
}
