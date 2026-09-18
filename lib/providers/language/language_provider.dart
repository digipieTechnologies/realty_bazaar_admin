// File: lib/providers/language/language_provider.dart
// Purpose: Language selection state notifier with persistent preference support.

import 'package:flutter/material.dart';

import '../../main.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  Locale _locale = const Locale('en', '');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    final savedCode = sharedPrefs.getString(_languageKey);
    if (savedCode != null && savedCode.isNotEmpty) {
      _locale = Locale(savedCode, '');
    }
  }

  Future<void> changeLanguage(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    await sharedPrefs.setString(_languageKey, newLocale.languageCode);
    notifyListeners();
  }
}
