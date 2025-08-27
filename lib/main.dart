import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oneiro/routes.dart';
import 'package:google_fonts/google_fonts.dart'; // 🔹 Nunito font için eklendi
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oneiro/l10n/app_localizations.dart';
import 'package:oneiro/services/language_service.dart';
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
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
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
            Locale('en', ''), // English (default)
            Locale('tr', ''), // Turkish
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
