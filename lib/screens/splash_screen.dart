import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // firebase_options dosyanızı içe aktarmayı unutmayın

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

  // Asenkron işlemin tamamlanıp tamamlanmadığını takip etmek için bir Completer kullanın.
  final Completer<void> _startupCompleter = Completer<void>();

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

    // Animasyon tamamlandığında, asenkron işlemin de tamamlandığından emin olun.
    _fadeController.forward().whenComplete(() {
      _startupCompleter.complete();
    });

    // Uygulamanın başlangıçta yapması gereken asenkron işlemleri burada başlatın.
    _initializeApp();
  }

  // Bu fonksiyon, Firebase kimlik doğrulama kontrolünü ve yönlendirmeyi yönetir.
  Future<void> _initializeApp() async {
    // Firebase authStateChanges() akışını dinleyerek kullanıcının oturum durumunu bekleyin.
    // .first ifadesi, akışın ilk değerini alıp işlemi tamamlamasını sağlar.
    // Bu, uygulamanın kimlik doğrulama durumunu beklemesini garanti eder.
    final user = await FirebaseAuth.instance.authStateChanges().first;

    // _startupCompleter'ın tamamlanmasını bekleyin. Bu, hem animasyonun hem de Firebase
    // kontrolünün tamamlandığı anlamına gelir.
    await _startupCompleter.future;

    // Yönlendirme işlemini sadece widget ekrana bağlandığında (mounted) gerçekleştirin.
    if (mounted) {
      if (user != null) {
        // Kullanıcı oturum açmışsa ana sayfaya yönlendir.
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Oturum açmamışsa giriş sayfasına yönlendir.
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    // Slogan
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (_, __) => Opacity(
                        opacity: _fadeController.value > 0.5 ? 1.0 : 0.0,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24), // yanlardan boşluk
                          child: Text(
                            'Kendinize bir adım daha yaklaşın.',
                            textAlign: TextAlign.center, // ortalama
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20, // 📌 Font boyutu büyütüldü
                              letterSpacing: 1.2,
                            ),
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
