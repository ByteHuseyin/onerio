import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InterpretationCard extends StatelessWidget {
  final String content;

  const InterpretationCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1B4D), Color(0xFF3D2A6F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/icon.png',
                  height: 24,
                  width: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Onerio Yorumu',
                style: GoogleFonts.nunito(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 17,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}