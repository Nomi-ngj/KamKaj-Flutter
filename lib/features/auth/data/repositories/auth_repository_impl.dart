import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/verification_purpose.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_mock_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_models.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  /// Reset token held in memory only between Verify and Reset screens.
  String? _resetToken;

  @override
  Future<Result<User?>> currentUser() => ErrorMapper.guard(() async {
        final token = await _tokenStorage.accessToken;
        if (token == null) return null;
        final remote = _remote;
        if (remote is AuthMockDataSource) remote.restore(token);
        try {
          return (await _remote.me()).toEntity();
        } on UnauthorizedException {
          await _tokenStorage.clear();
          return null;
        }
      });

  @override
  Future<Result<User>> signIn({required String email, required String password}) =>
      ErrorMapper.guard(() async {
        final response = await _remote.signIn(email: email, password: password);
        await _saveSession(response);
        return response.user.toEntity();
      });

  @override
  Future<Result<void>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) =>
      ErrorMapper.guard(
        () => _remote.signUp(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
        ),
      );

  @override
  Future<Result<void>> requestPasswordReset(String email) =>
      ErrorMapper.guard(() => _remote.forgotPassword(email));

  @override
  Future<Result<User?>> verifyCode({
    required String email,
    required String code,
    required VerificationPurpose purpose,
  }) =>
      ErrorMapper.guard(() async {
        final json = await _remote.verifyCode(email: email, code: code, purpose: purpose.name);
        switch (purpose) {
          case VerificationPurpose.signUp:
            final response = AuthResponseModel.fromJson(json);
            await _saveSession(response);
            return response.user.toEntity();
          case VerificationPurpose.resetPassword:
            final token = readResetToken(json);
            if (token == null) throw const ParsingException('Missing reset token');
            _resetToken = token;
            return null;
        }
      });

  @override
  Future<Result<void>> resendCode({required String email, required VerificationPurpose purpose}) =>
      ErrorMapper.guard(() => _remote.resendCode(email: email, purpose: purpose.name));

  @override
  Future<Result<void>> resetPassword({required String email, required String newPassword}) =>
      ErrorMapper.guard(() async {
        final token = _resetToken;
        if (token == null) throw const UnauthorizedException('Reset token missing');
        await _remote.resetPassword(resetToken: token, newPassword: newPassword);
        _resetToken = null;
      });

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      ErrorMapper.guard(
        () => _remote.changePassword(currentPassword: currentPassword, newPassword: newPassword),
      );

  @override
  Future<Result<void>> signOut() => ErrorMapper.guard(() async {
        try {
          await _remote.signOut();
        } on AppException {
          // Sign out locally even if the server call fails.
        } finally {
          await _tokenStorage.clear();
        }
      });

  Future<void> _saveSession(AuthResponseModel response) => _tokenStorage.save(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
}
