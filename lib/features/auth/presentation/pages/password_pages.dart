import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../viewmodels/auth_form_view_models.dart';
import '../widgets/auth_widgets.dart';
import 'support_footer.dart';

/// Reset Password (after email verification).
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(resetPasswordViewModelProvider.notifier).submit(
          email: widget.email,
          password: _password.text,
          confirmPassword: _confirm.text,
        );
    if (!ok || !mounted) return;
    AppToast.show(context, 'Password updated. Sign in with your new password.');
    context.goNamed(RouteNames.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordViewModelProvider);
    return AuthScaffold(
      showBack: true,
      footer: const SupportFooter(),
      children: [
        const AuthHeader(
          title: 'Reset Password',
          subtitle: 'Set a new, secure password\nfor your account.',
          topSpacing: AppSpacing.xxl,
        ),
        const SizedBox(height: AppSpacing.giant),
        _PasswordForm(
          formKey: _formKey,
          fields: [
            _PasswordFieldSpec(_password, 'Password', Validators.password),
            _PasswordFieldSpec(
              _confirm,
              'Confirm Password',
              (v) => Validators.confirmPassword(v, _password.text),
            ),
          ],
          onSubmit: _submit,
          onChanged: () => ref.read(resetPasswordViewModelProvider.notifier).clearError(),
        ),
        AuthErrorText(state.errorMessage),
        const SizedBox(height: AppSpacing.xxxl),
        AppButton(label: 'Update Password', isLoading: state.isSubmitting, onPressed: _submit),
      ],
    );
  }
}

/// Change Password (signed in, from Profile).
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _old.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(changePasswordViewModelProvider.notifier).submit(
          currentPassword: _old.text,
          newPassword: _password.text,
          confirmPassword: _confirm.text,
        );
    if (!ok || !mounted) return;
    AppToast.show(context, 'Your password has been changed.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordViewModelProvider);
    return AuthScaffold(
      showBack: true,
      footer: const SupportFooter(),
      children: [
        const AuthHeader(
          title: 'Change Password',
          subtitle: 'Set a new, secure password\nfor your account.',
          topSpacing: AppSpacing.xxl,
        ),
        const SizedBox(height: AppSpacing.giant),
        _PasswordForm(
          formKey: _formKey,
          fields: [
            _PasswordFieldSpec(
              _old,
              'Old Password',
              (v) => Validators.required(v, field: 'Old password'),
            ),
            _PasswordFieldSpec(_password, 'Password', Validators.password),
            _PasswordFieldSpec(
              _confirm,
              'Confirm Password',
              (v) => Validators.confirmPassword(v, _password.text),
            ),
          ],
          onSubmit: _submit,
          onChanged: () => ref.read(changePasswordViewModelProvider.notifier).clearError(),
        ),
        AuthErrorText(state.errorMessage),
        const SizedBox(height: AppSpacing.xxxl),
        AppButton(label: 'Update Password', isLoading: state.isSubmitting, onPressed: _submit),
      ],
    );
  }
}

class _PasswordFieldSpec {
  const _PasswordFieldSpec(this.controller, this.hint, this.validator);

  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String> validator;
}

class _PasswordForm extends StatelessWidget {
  const _PasswordForm({
    required this.formKey,
    required this.fields,
    required this.onSubmit,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final List<_PasswordFieldSpec> fields;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AutofillGroup(
        child: Column(
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) kAuthFieldGap,
              AppTextField(
                controller: fields[i].controller,
                hint: fields[i].hint,
                isPassword: true,
                validator: fields[i].validator,
                textInputAction:
                    i == fields.length - 1 ? TextInputAction.done : TextInputAction.next,
                onSubmitted: i == fields.length - 1 ? (_) => onSubmit() : null,
                onChanged: (_) => onChanged(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
