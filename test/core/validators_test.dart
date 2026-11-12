import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts a valid address', () {
      expect(Validators.email('hello@appname.com'), isNull);
      expect(Validators.email('  first.last+tag@sub.domain.pk '), isNull);
    });

    test('rejects empty and malformed input', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('hello@'), 'Enter a valid email address');
      expect(Validators.email('no-at-sign.com'), 'Enter a valid email address');
    });
  });

  group('Validators.password', () {
    test('requires 8+ characters with letters and numbers', () {
      expect(Validators.password('Password1'), isNull);
      expect(Validators.password('short1'), contains('at least'));
      expect(Validators.password('onlyletters'), 'Use letters and numbers');
      expect(Validators.password('12345678'), 'Use letters and numbers');
    });
  });

  test('confirmPassword must match', () {
    expect(Validators.confirmPassword('Password1', 'Password1'), isNull);
    expect(Validators.confirmPassword('Password2', 'Password1'), 'Passwords do not match');
    expect(Validators.confirmPassword('', 'Password1'), 'Confirm your password');
  });

  test('otp requires exactly 6 digits', () {
    expect(Validators.otp('123456'), isNull);
    expect(Validators.otp('12345'), isNotNull);
    expect(Validators.otp('12a456'), isNotNull);
  });

  test('name rejects blank and over-long values', () {
    expect(Validators.name('Nouman'), isNull);
    expect(Validators.name('   '), 'Name is required');
    expect(Validators.name('a' * 51), 'Name is too long');
  });
}
