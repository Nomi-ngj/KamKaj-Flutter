import '../../../../core/exceptions/app_exception.dart';
import '../models/auth_models.dart';
import 'auth_remote_data_source.dart';

/// In-memory backend used while the real API is pending
/// (`--dart-define=USE_MOCK_API=true`, the default).
///
/// Demo account: `hello@appname.com` / `Password1`. Any 6-digit code
/// except `000000` is accepted.
final class AuthMockDataSource implements AuthRemoteDataSource {
  AuthMockDataSource({Duration latency = const Duration(milliseconds: 600)})
      : _latency = latency;

  final Duration _latency;

  final Map<String, ({UserModel user, String password})> _accounts = {
    'hello@appname.com': (
      user: const UserModel(
        id: 'u_1',
        firstName: 'Nouman',
        lastName: 'Gul',
        email: 'hello@appname.com',
        isEmailVerified: true,
      ),
      password: 'Password1',
    ),
  };

  final Map<String, ({UserModel user, String password})> _pending = {};
  String? _signedInEmail;

  Future<void> _delay() => Future<void>.delayed(_latency);

  AuthResponseModel _session(UserModel user) {
    _signedInEmail = user.email;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return AuthResponseModel(
      accessToken: 'mock-access-$stamp',
      refreshToken: 'mock-refresh-$stamp',
      user: user,
    );
  }

  @override
  Future<UserModel> me() async {
    await _delay();
    final email = _signedInEmail;
    final account = email == null ? null : _accounts[email];
    if (account == null) throw const UnauthorizedException();
    return account.user;
  }

  /// Restores the mock session when a token already exists on device.
  void restore(String? accessToken) {
    if (accessToken != null && accessToken.startsWith('mock-')) {
      _signedInEmail ??= _accounts.keys.first;
    }
  }

  @override
  Future<AuthResponseModel> signIn({required String email, required String password}) async {
    await _delay();
    final account = _accounts[email.toLowerCase()];
    if (account == null || account.password != password) {
      throw const ServerException(
        'Invalid credentials',
        statusCode: 400,
        serverMessage: 'Incorrect email or password.',
      );
    }
    return _session(account.user);
  }

  @override
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await _delay();
    final key = email.toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const ServerException(
        'Duplicate email',
        statusCode: 409,
        serverMessage: 'An account with this email already exists.',
      );
    }
    _pending[key] = (
      user: UserModel(
        id: 'u_${_accounts.length + _pending.length + 1}',
        firstName: firstName,
        lastName: lastName,
        email: key,
        isEmailVerified: false,
      ),
      password: password,
    );
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _delay();
    // Always succeed so the API never reveals which emails are registered.
  }

  @override
  Future<Map<String, Object?>> verifyCode({
    required String email,
    required String code,
    required String purpose,
  }) async {
    await _delay();
    if (code == '000000') {
      throw const ServerException(
        'Invalid code',
        statusCode: 400,
        serverMessage: 'That code is incorrect or has expired.',
      );
    }
    final key = email.toLowerCase();
    if (purpose == 'signUp') {
      final pending = _pending.remove(key);
      if (pending == null) throw const NotFoundException();
      final verified = UserModel(
        id: pending.user.id,
        firstName: pending.user.firstName,
        lastName: pending.user.lastName,
        email: pending.user.email,
        isEmailVerified: true,
      );
      _accounts[key] = (user: verified, password: pending.password);
      final session = _session(verified);
      return {
        'accessToken': session.accessToken,
        'refreshToken': session.refreshToken,
        'user': verified.toJson(),
      };
    }
    return {'resetToken': 'mock-reset-$key'};
  }

  @override
  Future<void> resendCode({required String email, required String purpose}) => _delay();

  @override
  Future<void> resetPassword({required String resetToken, required String newPassword}) async {
    await _delay();
    final email = resetToken.replaceFirst('mock-reset-', '');
    final account = _accounts[email];
    if (account != null) {
      _accounts[email] = (user: account.user, password: newPassword);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _delay();
    final email = _signedInEmail;
    final account = email == null ? null : _accounts[email];
    if (account == null) throw const UnauthorizedException();
    if (account.password != currentPassword) {
      throw const ServerException(
        'Wrong password',
        statusCode: 400,
        serverMessage: 'Your old password is incorrect.',
      );
    }
    _accounts[email!] = (user: account.user, password: newPassword);
  }

  @override
  Future<void> signOut() async {
    await _delay();
    _signedInEmail = null;
  }
}
