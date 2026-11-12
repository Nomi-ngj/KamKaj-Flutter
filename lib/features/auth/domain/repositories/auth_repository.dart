import '../../../../core/errors/result.dart';
import '../entities/user.dart';
import '../entities/verification_purpose.dart';

abstract interface class AuthRepository {
  /// Returns the signed-in user, or `null` when there is no valid session.
  Future<Result<User?>> currentUser();

  Future<Result<User>> signIn({required String email, required String password});

  /// Creates an account. A verification code is sent to [email].
  Future<Result<void>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<Result<void>> requestPasswordReset(String email);

  /// Verifies the code. For [VerificationPurpose.signUp] the user is signed in
  /// and returned; for reset it returns `null` and stores a reset token.
  Future<Result<User?>> verifyCode({
    required String email,
    required String code,
    required VerificationPurpose purpose,
  });

  Future<Result<void>> resendCode({required String email, required VerificationPurpose purpose});

  Future<Result<void>> resetPassword({required String email, required String newPassword});

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Result<void>> signOut();
}
