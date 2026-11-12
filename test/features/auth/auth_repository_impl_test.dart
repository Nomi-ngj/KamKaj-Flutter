import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/errors/failure.dart';
import 'package:kamkaj_pro/core/exceptions/app_exception.dart';
import 'package:kamkaj_pro/core/storage/storage_keys.dart';
import 'package:kamkaj_pro/core/storage/token_storage.dart';
import 'package:kamkaj_pro/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kamkaj_pro/features/auth/data/models/auth_models.dart';
import 'package:kamkaj_pro/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kamkaj_pro/features/auth/domain/entities/verification_purpose.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late InMemorySecureStorage secure;
  late AuthRepositoryImpl repository;

  const userModel = UserModel(
    id: 'u1',
    firstName: 'Nouman',
    lastName: 'Gul',
    email: 'hello@appname.com',
    isEmailVerified: true,
  );

  setUp(() {
    remote = _MockRemote();
    secure = InMemorySecureStorage();
    repository = AuthRepositoryImpl(remote: remote, tokenStorage: TokenStorage(secure));
  });

  test('signIn stores tokens securely and returns the user', () async {
    when(() => remote.signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer(
      (_) async => const AuthResponseModel(accessToken: 'a', refreshToken: 'r', user: userModel),
    );

    final result = await repository.signIn(email: 'hello@appname.com', password: 'Password1');

    expect(result.valueOrNull?.email, 'hello@appname.com');
    expect(secure.values[StorageKeys.accessToken], 'a');
    expect(secure.values[StorageKeys.refreshToken], 'r');
  });

  test('signIn maps network errors to a NetworkFailure', () async {
    when(() => remote.signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenThrow(const NetworkException());

    final result = await repository.signIn(email: 'a@b.co', password: 'x');

    expect(result.failureOrNull, isA<NetworkFailure>());
    expect(secure.values, isEmpty);
  });

  test('currentUser clears an expired session', () async {
    secure.values[StorageKeys.accessToken] = 'expired';
    when(() => remote.me()).thenThrow(const UnauthorizedException());

    final result = await repository.currentUser();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
    expect(secure.values, isEmpty);
  });

  test('reset flow keeps the reset token between verify and reset', () async {
    when(
      () => remote.verifyCode(email: 'a@b.co', code: '123456', purpose: 'resetPassword'),
    ).thenAnswer((_) async => {'resetToken': 'reset-1'});
    when(() => remote.resetPassword(resetToken: 'reset-1', newPassword: 'Password2'))
        .thenAnswer((_) async {});

    final verified = await repository.verifyCode(
      email: 'a@b.co',
      code: '123456',
      purpose: VerificationPurpose.resetPassword,
    );
    final reset = await repository.resetPassword(email: 'a@b.co', newPassword: 'Password2');

    expect(verified.isSuccess, isTrue);
    expect(reset.isSuccess, isTrue);
    verify(() => remote.resetPassword(resetToken: 'reset-1', newPassword: 'Password2')).called(1);
  });

  test('signOut clears tokens even if the server call fails', () async {
    secure.values[StorageKeys.accessToken] = 'a';
    when(() => remote.signOut()).thenThrow(const NetworkException());

    final result = await repository.signOut();

    expect(result.isSuccess, isTrue);
    expect(secure.values, isEmpty);
  });
}
