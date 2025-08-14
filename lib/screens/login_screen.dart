import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home/home_screen.dart';
import 'package:oneiro/services/permission_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _transformAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _askNotificationPermission(); // 📌 İzin kontrolü 
    _checkLoginStatus();
  }

  Future<void> _askNotificationPermission() async {
  final permissionService = PermissionService();
  final hasPermission = await permissionService.requestNotificationPermission();
  
  if (!hasPermission && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildirim izni verilmedi, hatırlatmalar çalışmayabilir.'),
      ),
    );
  }
}

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _transformAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Zaten giriş yapılmış → HomeScreen'e yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }
  }

  Future<void> _createUserIfNotExists(User user) async {
  final userDoc = FirebaseFirestore.instance.collection('user_table').doc(user.uid);
  final docSnapshot = await userDoc.get();

  if (!docSnapshot.exists) {
    await userDoc.set({
      'uid': user.uid,
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'substatu': '', // İlk girişte boş olsun
      });
    }
  }


  Future<void> _signInWithGoogle() async {
  try {
    final googleSignIn = GoogleSignIn(
      signInOption: SignInOption.standard,
      scopes: ['email', 'profile'],
    );

    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      await _createUserIfNotExists(user); // 🔐 Firestore'a ekle
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Giriş başarısız: $e')),
    );
  }
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _transformAnimation.value),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  SizedBox(
                    width: 700,
                    height: 200,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Slogan
                  Text(
                    'Rüyanı keşfetmeye hazır mısın?',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontSize: 16,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Google ile devam et
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: const Icon(FontAwesomeIcons.google, color: Colors.red, size: 20),
                      label: const Text('Google ile devam et', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
