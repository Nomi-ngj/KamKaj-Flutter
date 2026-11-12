import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user.dart';
import '../entities/verification_purpose.dart';
import '../repositories/auth_repository.dart';

/// Use cases validate input before touching the repository, so invalid data
/// never reaches the network.

final class GetCurrentUser {
  const GetCurrentUser(this._repository);
  final AuthRepository _repository;

  Future<Result<User?>> call() => _repository.currentUser();
}

final class SignIn {
  const SignIn(this._repository);
  final AuthRepository _repository;

  Future<Result<User>> call({required String email, required String password}) async {
    final error = Validators.email(email) ?? Validators.required(password, field: 'Password');
    if (error != null) return Result.failure(ValidationFailure(error));
    return _repository.signIn(email: email.trim(), password: password);
  }
}

final class SignUp {
  const SignUp(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final error = Validators.name(firstName, field: 'First name') ??
        Validators.name(lastName, field: 'Last name') ??
        Validators.email(email) ??
        Validators.password(password) ??
        Validators.confirmPassword(confirmPassword, password);
    if (error != null) return Result.failure(ValidationFailure(error));
    return _repository.signUp(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      password: password,
    );
  }
}

final class RequestPasswordReset {
  const RequestPasswordReset(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call(String email) async {
    final error = Validators.email(email);
    if (error != null) return Result.failure(ValidationFailure(error));
    return _repository.requestPasswordReset(email.trim());
  }
}

final class VerifyCode {
  const VerifyCode(this._repository);
  final AuthRepository _repository;

  Future<Result<User?>> call({
    required String email,
    required String code,
    required VerificationPurpose purpose,
  }) async {
    final error = Validators.otp(code);
    if (error != null) return Result.failure(ValidationFailure(error));
    return _repository.verifyCode(email: email, code: code, purpose: purpose);
  }
}

final class ResendCode {
  const ResendCode(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({required String email, required VerificationPurpose purpose}) =>
      _repository.resendCode(email: email, purpose: purpose);
}

final class ResetPassword {
  const ResetPassword(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final error =
        Validators.password(password) ?? Validators.confirmPassword(confirmPassword, password);
    if (error != null) return Result.failure(ValidationFailure(error));
    return _repository.resetPassword(email: email, newPassword: password);
  }
}

final class ChangePassword {
  const ChangePassword(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final error = Validators.required(currentPassword, field: 'Old password') ??
        Validators.password(newPassword) ??
        Validators.confirmPassword(confirmPassword, newPassword);
    if (error != null) return Result.failure(ValidationFailure(error));
    if (currentPassword == newPassword) {
      return const Result.failure(
        ValidationFailure('New password must be different from the old one'),
      );
    }
    return _repository.changePassword(currentPassword: currentPassword, newPassword: newPassword);
  }
}

final class SignOut {
  const SignOut(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
