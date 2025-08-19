import 'package:flutter/material.dart';
import 'package:oneiro/screens/history_screen.dart';
import 'package:oneiro/screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/splash': (context) => const SplashScreen(),
  '/login': (context) => const LoginScreen(),
  '/home': (context) => const HomeScreen(),
  '/history' : (context) => const HistoryScreen(),
};
