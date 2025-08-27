import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('en', ''); // Varsayılan İngilizce

  Locale get currentLocale => _currentLocale;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageKey);
    
    if (savedLanguageCode != null) {
      // Kullanıcı daha önce dil seçimi yapmışsa onu kullan
      _currentLocale = Locale(savedLanguageCode, '');
    } else {
      // İlk kez açılıyorsa telefon dilini kontrol et
      final deviceLocale = PlatformDispatcher.instance.locale;
      final supportedLanguages = ['tr', 'en'];
      
      if (supportedLanguages.contains(deviceLocale.languageCode)) {
        _currentLocale = deviceLocale;
      } else {
        // Desteklenmeyen dil ise varsayılan İngilizce
        _currentLocale = const Locale('en', '');
      }
      
      // Telefon dilini kaydet
      await prefs.setString(_languageKey, _currentLocale.languageCode);
    }
    
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode, '');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    notifyListeners();
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      default:
        return 'Türkçe';
    }
  }

  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'tr', 'name': 'Türkçe'},
    ];
  }
}
