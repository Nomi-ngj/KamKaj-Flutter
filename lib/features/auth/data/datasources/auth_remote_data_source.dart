import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_reader.dart';
import '../models/auth_models.dart';

/// Raw API calls for authentication. Throws [AppException]s.
abstract interface class AuthRemoteDataSource {
  Future<UserModel> me();
  Future<AuthResponseModel> signIn({required String email, required String password});
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });
  Future<void> forgotPassword(String email);

  /// Returns tokens for sign-up, or a `resetToken` for password reset.
  Future<Map<String, Object?>> verifyCode({
    required String email,
    required String code,
    required String purpose,
  });
  Future<void> resendCode({required String email, required String purpose});
  Future<void> resetPassword({required String resetToken, required String newPassword});
  Future<void> changePassword({required String currentPassword, required String newPassword});
  Future<void> signOut();
}

final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<UserModel> me() async => UserModel.fromJson(await _client.get(ApiEndpoints.me));

  @override
  Future<AuthResponseModel> signIn({required String email, required String password}) async {
    final json = await _client.post(
      ApiEndpoints.signIn,
      body: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(json);
  }

  @override
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) =>
      _client.post(
        ApiEndpoints.signUp,
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        },
      );

  @override
  Future<void> forgotPassword(String email) =>
      _client.post(ApiEndpoints.forgotPassword, body: {'email': email});

  @override
  Future<Map<String, Object?>> verifyCode({
    required String email,
    required String code,
    required String purpose,
  }) =>
      _client.post(
        ApiEndpoints.verifyCode,
        body: {'email': email, 'code': code, 'purpose': purpose},
      );

  @override
  Future<void> resendCode({required String email, required String purpose}) =>
      _client.post(ApiEndpoints.resendCode, body: {'email': email, 'purpose': purpose});

  @override
  Future<void> resetPassword({required String resetToken, required String newPassword}) =>
      _client.post(
        ApiEndpoints.resetPassword,
        body: {'resetToken': resetToken, 'password': newPassword},
      );

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) =>
      _client.post(
        ApiEndpoints.changePassword,
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

  @override
  Future<void> signOut() => _client.post(ApiEndpoints.signOut);
}

/// Extracts the reset token from a verify-code response.
String? readResetToken(Map<String, Object?> json) => json.readStringOrNull('resetToken');
