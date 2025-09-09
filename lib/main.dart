import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oneiro/routes.dart';
import 'package:google_fonts/google_fonts.dart'; // 🔹 Nunito font için eklendi
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oneiro/l10n/app_localizations.dart';
import 'package:oneiro/services/language_service.dart';
import 'package:oneiro/services/admob_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() {
  runApp(const AppInitializer());
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Color(0xFF0F0F1A),
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }
        return ChangeNotifierProvider(
          create: (_) => LanguageService(),
          child: const OneiroApp(),
        );
      },
    );
  }

  Future<void> _initializeApp() async {
    print('Uygulama: Firebase başlatılıyor...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Uygulama: Firebase başarıyla başlatıldı');
    
    print('Uygulama: AdMob başlatılıyor...');
    await AdMobService.initialize();
    print('Uygulama: AdMob başarıyla başlatıldı');
  }
}

class OneiroApp extends StatelessWidget {
  const OneiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return MaterialApp(
          title: 'Oneiro',
          debugShowCheckedModeBanner: false,
         
          // Localization support
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English (default)
            Locale('tr'), // Turkish
            Locale('fr'), // French
            Locale('it'), // Italian
            Locale('hi'), // Hindi
            Locale('es'), // Spanish
            Locale('de'), // German
            Locale('pt'), // Portuguese
            Locale('el'), // greek
            Locale('ru'), // Russian
            Locale('ja'), // Japanese
            Locale('ko'), // korean
            Locale('zh'), // Chinese
            ],
          locale: languageService.currentLocale,
         
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0F0F1A),
            textTheme: GoogleFonts.nunitoTextTheme().apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          initialRoute: '/',
          routes: appRoutes,
        );
      },
    );
  }
}