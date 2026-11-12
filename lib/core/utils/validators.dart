/// Pure input validators. Return `null` when valid, otherwise a user message.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required';
    if (!_email.hasMatch(input)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password is required';
    if (input.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    if (!RegExp('[A-Za-z]').hasMatch(input) || !RegExp(r'\d').hasMatch(input)) {
      return 'Use letters and numbers';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? name(String? value, {String field = 'Name'}) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return '$field is required';
    if (input.length > maxNameLength) return '$field is too long';
    return null;
  }

  static String? otp(String? value, {int length = 6}) {
    final input = value ?? '';
    if (input.length != length || int.tryParse(input) == null) {
      return 'Enter the $length-digit code';
    }
    return null;
  }
}
