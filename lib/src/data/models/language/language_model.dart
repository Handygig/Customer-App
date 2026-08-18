class LanguageModel {
  final String code;
  final String nativeName;
  final String englishName;

  const LanguageModel({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  static const List<LanguageModel> supportedLanguages = [
    LanguageModel(code: 'en', nativeName: 'English', englishName: 'English'),
    LanguageModel(code: 'si', nativeName: 'සිංහල', englishName: 'Sinhala'),
    LanguageModel(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
  ];
}
