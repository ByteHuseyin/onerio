import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }
}
