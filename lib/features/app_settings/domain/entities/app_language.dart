/// Languages offered on the "Choose your language" screen.
enum AppLanguage {
  english('en', 'English', isRtl: false),
  arabic('ar', 'عربي', isRtl: true),
  urdu('ur', 'اردو', isRtl: true),
  french('fr', 'français', isRtl: false),
  spanish('es', 'español', isRtl: false);

  const AppLanguage(this.code, this.nativeName, {required this.isRtl});

  final String code;
  final String nativeName;
  final bool isRtl;

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.english);
}
