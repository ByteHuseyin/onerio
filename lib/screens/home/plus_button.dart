import 'package:flutter/material.dart';

class PlusButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PlusButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF6A3BED),
      onPressed: onPressed,
      child: const Icon(Icons.add, size: 28, color: Colors.white),
    );
  }
}