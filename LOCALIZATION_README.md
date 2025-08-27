# Oneiro Localization (L10n) Kılavuzu

Bu dokümantasyon, Oneiro uygulamasında çoklu dil desteğinin nasıl kullanılacağını açıklar.

## Desteklenen Diller

- 🇹🇷 Türkçe (tr) - Varsayılan dil
- 🇺🇸 İngilizce (en)

## Dosya Yapısı

```
lib/
├── l10n/
│   ├── app_en.arb          # İngilizce çeviriler
│   ├── app_tr.arb          # Türkçe çeviriler
│   ├── app_localizations.dart      # Otomatik oluşturulan localization sınıfı
│   ├── app_localizations_en.dart   # İngilizce localization
│   └── app_localizations_tr.dart   # Türkçe localization
├── services/
│   └── language_service.dart       # Dil değiştirme servisi
└── main.dart                       # Ana uygulama dosyası
```

## Kullanım

### 1. Widget'larda Çeviri Kullanma

```dart
import 'package:oneiro/l10n/app_localizations.dart';

// Basit metin çevirisi
Text(AppLocalizations.of(context)!.welcome)

// Parametreli çeviri (gelecekte eklenebilir)
Text(AppLocalizations.of(context)!.helloWorld('John'))
```

### 2. Dil Değiştirme

```dart
import 'package:oneiro/services/language_service.dart';
import 'package:provider/provider.dart';

// Dil servisini al
final languageService = Provider.of<LanguageService>(context, listen: false);

// Dili değiştir
await languageService.changeLanguage('en'); // İngilizce
await languageService.changeLanguage('tr'); // Türkçe
```

### 3. Desteklenen Dilleri Listeleme

```dart
final languages = languageService.getSupportedLanguages();
// [
//   {'code': 'tr', 'name': 'Türkçe'},
//   {'code': 'en', 'name': 'English'}
// ]
```

## Yeni Çeviri Ekleme

### 1. ARB Dosyalarını Güncelle

**lib/l10n/app_en.arb** (İngilizce):
```json
{
  "newKey": "New English Text",
  "@newKey": {
    "description": "Description for the new key"
  }
}
```

**lib/l10n/app_tr.arb** (Türkçe):
```json
{
  "newKey": "Yeni Türkçe Metin"
}
```

### 2. Localization Dosyalarını Yeniden Oluştur

```bash
flutter gen-l10n
```

### 3. Kullan

```dart
Text(AppLocalizations.of(context)!.newKey)
```

## Parametreli Çeviriler

Gelecekte parametreli çeviriler eklemek için:

**app_en.arb**:
```json
{
  "greeting": "Hello {name}!",
  "@greeting": {
    "description": "A greeting message",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "John"
      }
    }
  }
}
```

**app_tr.arb**:
```json
{
  "greeting": "Merhaba {name}!"
}
```

Kullanım:
```dart
Text(AppLocalizations.of(context)!.greeting('John'))
```

## Ayarlar Ekranında Dil Seçimi

Kullanıcılar ayarlar ekranından dil değiştirebilir:

1. **Ayarlar** ekranına git
2. **Dil** bölümünü bul
3. İstediğin dili seç (Türkçe/İngilizce)
4. Değişiklik anında uygulanır

## Teknik Detaylar

### Provider Entegrasyonu

Uygulama, dil değişikliklerini dinlemek için Provider kullanır:

```dart
ChangeNotifierProvider(
  create: (_) => LanguageService(),
  child: OneiroApp(),
)
```

### SharedPreferences

Seçilen dil, cihazda kalıcı olarak saklanır:

```dart
// Kaydet
await prefs.setString('selected_language', 'en');

// Yükle
final languageCode = prefs.getString('selected_language');
```

### Otomatik Kod Üretimi

Flutter'ın `flutter gen-l10n` komutu, ARB dosyalarından Dart kodları oluşturur:

```bash
flutter gen-l10n
```

## Best Practices

1. **Tutarlılık**: Tüm metinler için çeviri anahtarları kullan
2. **Açıklayıcı İsimler**: Anahtar isimleri anlamlı olsun
3. **Kategoriler**: İlgili çevirileri grupla (örn: `login_`, `settings_`, `dream_`)
4. **Test**: Her iki dilde de uygulamayı test et
5. **Güncelleme**: Yeni özellikler eklerken çevirileri de ekle

## Sorun Giderme

### Çeviri Bulunamadı Hatası

```
NoSuchMethodError: The getter 'someKey' was called on null.
```

**Çözüm**: ARB dosyalarında anahtarın var olduğundan emin ol ve `flutter gen-l10n` çalıştır.

### Dil Değişmiyor

**Çözüm**: 
1. `LanguageService`'in Provider ile sarıldığından emin ol
2. `MaterialApp`'te `locale` parametresinin doğru ayarlandığından emin ol

### Import Hatası

```
Target of URI doesn't exist: 'package:oneiro/l10n/app_localizations.dart'
```

**Çözüm**: `flutter gen-l10n` komutunu çalıştır.

## Gelecek Geliştirmeler

- [ ] Daha fazla dil desteği (Almanca, Fransızca, İspanyolca)
- [ ] Parametreli çeviriler
- [ ] Çeviri yönetim paneli
- [ ] Otomatik çeviri önerileri
- [ ] Çeviri kalite kontrolü
