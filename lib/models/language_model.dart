class LanguageModel {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageModel({required this.code, required this.name, required this.nativeName, required this.flag});

  static const List<LanguageModel> supportedLanguages = [
    LanguageModel(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    LanguageModel(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    LanguageModel(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
  ];
}
