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
      final supportedLanguages = [
        'en', 'tr', 'fr', 'it', 'hi', 'es', 'de', 'pt', 'el', 'ru', 'ja', 'ko', 'zh'
      ];
      
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
      case 'fr':
        return 'Français';
      case 'it':
        return 'Italiano';
      case 'hi':
        return 'हिन्दी';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'pt':
        return 'Português';
      case 'el':
        return 'Ελληνικά';
      case 'ru':
        return 'Русский';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'zh':
        return '中文';
      default:
        return 'English';
    }
  }

  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'tr', 'name': 'Türkçe'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'it', 'name': 'Italiano'},
      {'code': 'hi', 'name': 'हिन्दी'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'pt', 'name': 'Português'},
      {'code': 'el', 'name': 'Ελληνικά'},
      {'code': 'ru', 'name': 'Русский'},
      {'code': 'ja', 'name': '日本語'},
      {'code': 'ko', 'name': '한국어'},
      {'code': 'zh', 'name': '中文'},
    ];
  }
}
