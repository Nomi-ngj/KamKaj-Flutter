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

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final ok = await ref.read(signUpViewModelProvider.notifier).submit(
          firstName: _firstName.text,
          lastName: _lastName.text,
          email: email,
          password: _password.text,
          confirmPassword: _confirm.text,
        );
    if (!ok || !mounted) return;
    context.pushNamed(
      RouteNames.verifyEmail,
      queryParameters: {
        RouteParams.email: email,
        RouteParams.purpose: VerificationPurpose.signUp.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpViewModelProvider);
    final viewModel = ref.read(signUpViewModelProvider.notifier);
    void clear(String _) => viewModel.clearError();

    return AuthScaffold(
      footer: AuthFooterLink(
        prompt: 'Already have an account?',
        action: 'Sign In',
        onTap: () => context.canPop() ? context.pop() : context.goNamed(RouteNames.signIn),
      ),
      children: [
        const AuthHeader(
          title: 'Create your account',
          subtitle: 'Join the community and get fresh deliveries from your local favorites.',
        ),
        const SizedBox(height: AppSpacing.massive),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                AppTextField(
                  controller: _firstName,
                  hint: 'First Name',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  validator: (v) => Validators.name(v, field: 'First name'),
                  onChanged: clear,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _lastName,
                  hint: 'Last Name',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  validator: (v) => Validators.name(v, field: 'Last name'),
                  onChanged: clear,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _email,
                  hint: 'hello@appname.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  onChanged: clear,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _password,
                  hint: 'Password',
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onChanged: clear,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _confirm,
                  hint: 'Confirm Password',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.confirmPassword(v, _password.text),
                  onSubmitted: (_) => _submit(),
                  onChanged: clear,
                ),
              ],
            ),
          ),
        ),
        AuthErrorText(state.errorMessage),
        const SizedBox(height: AppSpacing.xxxl),
        AppButton(label: 'Sign Up', isLoading: state.isSubmitting, onPressed: _submit),
      ],
    );
  }
}
