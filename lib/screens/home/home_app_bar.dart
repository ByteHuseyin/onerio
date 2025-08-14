import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSettingsPressed;

  const HomeAppBar({super.key, required this.onSettingsPressed});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Image.asset(
          'assets/images/icon.png',
          height: 36,
          fit: BoxFit.contain,
        ),
      ),
      centerTitle: true,
      title: Text(
        'Onerio',
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: onSettingsPressed,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage:
                  FirebaseAuth.instance.currentUser?.photoURL != null
                  ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                  : null,
              child: FirebaseAuth.instance.currentUser?.photoURL == null
                  ? const Icon(Icons.person, size: 18, color: Colors.white70)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}