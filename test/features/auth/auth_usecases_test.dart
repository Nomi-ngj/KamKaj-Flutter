import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/errors/failure.dart';
import 'package:kamkaj_pro/core/errors/result.dart';
import 'package:kamkaj_pro/features/auth/domain/entities/user.dart';
import 'package:kamkaj_pro/features/auth/domain/repositories/auth_repository.dart';
import 'package:kamkaj_pro/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  const user = User(id: 'u1', firstName: 'Nouman', lastName: 'Gul', email: 'hello@appname.com');

  setUp(() => repository = _MockAuthRepository());

  group('SignIn', () {
    test('validates before calling the repository', () async {
      final result = await SignIn(repository)(email: 'bad', password: 'x');
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(
        () => repository.signIn(email: any(named: 'email'), password: any(named: 'password')),
      );
    });

    test('trims the email and returns the user', () async {
      when(() => repository.signIn(email: 'hello@appname.com', password: 'Password1'))
          .thenAnswer((_) async => const Result.success(user));

      final result = await SignIn(repository)(email: ' hello@appname.com ', password: 'Password1');

      expect(result.valueOrNull, user);
    });
  });

  group('SignUp', () {
    test('rejects mismatched passwords', () async {
      final result = await SignUp(repository)(
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.co',
        password: 'Password1',
        confirmPassword: 'Password2',
      );
      expect(result.failureOrNull?.message, 'Passwords do not match');
    });
  });

  group('ChangePassword', () {
    test('new password must differ from the old one', () async {
      final result = await ChangePassword(repository)(
        currentPassword: 'Password1',
        newPassword: 'Password1',
        confirmPassword: 'Password1',
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('forwards valid input to the repository', () async {
      when(
        () => repository.changePassword(currentPassword: 'Password1', newPassword: 'Password2'),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await ChangePassword(repository)(
        currentPassword: 'Password1',
        newPassword: 'Password2',
        confirmPassword: 'Password2',
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
