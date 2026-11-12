import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/base/submit_state.dart';
import '../../../../core/errors/result.dart';
import '../../../../design_system/tokens/app_durations.dart';
import '../../domain/entities/verification_purpose.dart';
import 'session_view_model.dart';

/// Shared submit plumbing for the auth forms.
abstract base class _SubmitViewModel extends Notifier<SubmitState> {
  @override
  SubmitState build() => const SubmitState.idle();

  Future<bool> run<T>(Future<Result<T>> Function() action, {void Function(T value)? onSuccess}) async {
    if (state.isSubmitting) return false;
    state = const SubmitState.submitting();
    final result = await action();
    if (!ref.mounted) return false;
    return result.when(
      success: (value) {
        onSuccess?.call(value);
        state = const SubmitState.success();
        return true;
      },
      failure: (failure) {
        state = SubmitState.failed(failure);
        return false;
      },
    );
  }

  void clearError() {
    if (state.failure != null) state = const SubmitState.idle();
  }
}

// ── Sign in ─────────────────────────────────────────────────────────────────

final class SignInViewModel extends _SubmitViewModel {
  Future<bool> submit({required String email, required String password}) => run(
        () => ref.read(signInProvider).call(email: email, password: password),
        onSuccess: (user) => ref.read(sessionProvider.notifier).signedIn(user),
      );
}

final signInViewModelProvider =
    NotifierProvider.autoDispose<SignInViewModel, SubmitState>(SignInViewModel.new);

// ── Sign up ─────────────────────────────────────────────────────────────────

final class SignUpViewModel extends _SubmitViewModel {
  Future<bool> submit({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) =>
      run(
        () => ref.read(signUpProvider).call(
              firstName: firstName,
              lastName: lastName,
              email: email,
              password: password,
              confirmPassword: confirmPassword,
            ),
      );
}

final signUpViewModelProvider =
    NotifierProvider.autoDispose<SignUpViewModel, SubmitState>(SignUpViewModel.new);

// ── Forgot password ─────────────────────────────────────────────────────────

final class ForgotPasswordViewModel extends _SubmitViewModel {
  Future<bool> submit(String email) => run(() => ref.read(requestPasswordResetProvider).call(email));
}

final forgotPasswordViewModelProvider =
    NotifierProvider.autoDispose<ForgotPasswordViewModel, SubmitState>(ForgotPasswordViewModel.new);

// ── Reset password ──────────────────────────────────────────────────────────

final class ResetPasswordViewModel extends _SubmitViewModel {
  Future<bool> submit({
    required String email,
    required String password,
    required String confirmPassword,
  }) =>
      run(
        () => ref.read(resetPasswordProvider).call(
              email: email,
              password: password,
              confirmPassword: confirmPassword,
            ),
      );
}

final resetPasswordViewModelProvider =
    NotifierProvider.autoDispose<ResetPasswordViewModel, SubmitState>(ResetPasswordViewModel.new);

// ── Change password ─────────────────────────────────────────────────────────

final class ChangePasswordViewModel extends _SubmitViewModel {
  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      run(
        () => ref.read(changePasswordProvider).call(
              currentPassword: currentPassword,
              newPassword: newPassword,
              confirmPassword: confirmPassword,
            ),
      );
}

final changePasswordViewModelProvider =
    NotifierProvider.autoDispose<ChangePasswordViewModel, SubmitState>(ChangePasswordViewModel.new);

// ── Verify email (OTP) ──────────────────────────────────────────────────────

final class VerifyCodeState extends Equatable {
  const VerifyCodeState({
    this.submit = const SubmitState.idle(),
    this.resendSecondsLeft = 0,
    this.isResending = false,
  });

  final SubmitState submit;
  final int resendSecondsLeft;
  final bool isResending;

  bool get canResend => resendSecondsLeft == 0 && !isResending;

  VerifyCodeState copyWith({SubmitState? submit, int? resendSecondsLeft, bool? isResending}) =>
      VerifyCodeState(
        submit: submit ?? this.submit,
        resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
        isResending: isResending ?? this.isResending,
      );

  @override
  List<Object?> get props => [submit, resendSecondsLeft, isResending];
}

final class VerifyCodeViewModel extends Notifier<VerifyCodeState> {
  Timer? _timer;

  @override
  VerifyCodeState build() {
    ref.onDispose(() => _timer?.cancel());
    _startCountdown();
    return VerifyCodeState(resendSecondsLeft: AppDurations.otpResend.inSeconds);
  }

  /// Returns `true` when the code is accepted.
  Future<bool> verify({
    required String email,
    required String code,
    required VerificationPurpose purpose,
  }) async {
    if (state.submit.isSubmitting) return false;
    state = state.copyWith(submit: const SubmitState.submitting());
    final result =
        await ref.read(verifyCodeProvider).call(email: email, code: code, purpose: purpose);
    if (!ref.mounted) return false;
    return result.when(
      success: (user) {
        if (user != null) ref.read(sessionProvider.notifier).signedIn(user);
        state = state.copyWith(submit: const SubmitState.success());
        return true;
      },
      failure: (failure) {
        state = state.copyWith(submit: SubmitState.failed(failure));
        return false;
      },
    );
  }

  Future<void> resend({required String email, required VerificationPurpose purpose}) async {
    if (!state.canResend) return;
    state = state.copyWith(isResending: true);
    final result = await ref.read(resendCodeProvider).call(email: email, purpose: purpose);
    if (!ref.mounted) return;
    state = state.copyWith(
      isResending: false,
      submit: result.failureOrNull == null
          ? const SubmitState.idle()
          : SubmitState.failed(result.failureOrNull!),
      resendSecondsLeft: result.isSuccess ? AppDurations.otpResend.inSeconds : 0,
    );
    if (result.isSuccess) _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.resendSecondsLeft - 1;
      if (left <= 0) {
        timer.cancel();
        state = state.copyWith(resendSecondsLeft: 0);
      } else {
        state = state.copyWith(resendSecondsLeft: left);
      }
    });
  }
}

final verifyCodeViewModelProvider =
    NotifierProvider.autoDispose<VerifyCodeViewModel, VerifyCodeState>(VerifyCodeViewModel.new);
