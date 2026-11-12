/// Why a 6-digit code was sent.
enum VerificationPurpose {
  signUp,
  resetPassword;

  static VerificationPurpose fromName(String? name) =>
      values.firstWhere((p) => p.name == name, orElse: () => VerificationPurpose.signUp);
}
