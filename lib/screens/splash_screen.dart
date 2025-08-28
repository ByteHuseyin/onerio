import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart'; // firebase_options dosyanızı içe aktarmayı unutmayın
import 'package:oneiro/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCirc,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _fadeController.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Stack(
        children: [
          // Arka planda sabit bir bölümde animasyon
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Lottie.asset(
                'assets/animations/stars.json',
                fit: BoxFit.cover,
                repeat: true,
              ),
            ),
          ),

          // Ana içerik
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Uygulama adı
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFB8F3FF),
                          Color(0xFFD9ACFF),
                          Color(0xFFFFC7F3),
                        ],
                        stops: [0.0, 0.5, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Onerio',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'SpaceGrotesk',
                          color: Colors.white,
                          letterSpacing: 1.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Slogan
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (_, __) => Opacity(
                        opacity: _fadeController.value > 0.5 ? 1.0 : 0.0,
                        child: Text(
                          textAlign: TextAlign.center,
                          AppLocalizations.of(context)!.onboardingSubtitle1,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // İlerleme çubuğu
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (_, __) => Opacity(
                        opacity: _fadeController.value > 0.7 ? 1.0 : 0.0,
                        child: SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.black.withOpacity(0.3),
                            color: Colors.purpleAccent,
                            borderRadius: BorderRadius.circular(10),
                            minHeight: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}