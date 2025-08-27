import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneiro/l10n/app_localizations.dart';

class FloatingInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String character) onSend;

  const FloatingInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2A),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.purpleAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                                         child: TextField(
                       controller: controller,
                       maxLines: 3,
                       minLines: 1,
                       textInputAction: TextInputAction.send,
                       style: GoogleFonts.nunito(
                         color: Colors.white,
                         fontSize: 17,
                       ),
                                               onSubmitted: (value) {
                          if (!isLoading && value.trim().isNotEmpty) {
                            _showCharacterSelectionDialog(context);
                          }
                        },
                       decoration: InputDecoration(
                         hintText: AppLocalizations.of(context)!.dreamDescription,
                         hintStyle: TextStyle(
                           color: Colors.white.withOpacity(0.6),
                         ),
                         border: InputBorder.none,
                         contentPadding: const EdgeInsets.symmetric(
                           horizontal: 16,
                         ),
                       ),
                     ),
                  ),
                  const SizedBox(width: 12),
                  _buildSendButton(context),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.onboardingSubtitle2,
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCharacterSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.dreamAnalysis,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                                 const SizedBox(height: 24),
                 _buildCharacterOption(context, 'onerioai', 'OnerioAI'),
                 const SizedBox(height: 16),
                 _buildCharacterOption(context, 'freud', 'Sigmund Freud'),
                 const SizedBox(height: 16),
                 _buildCharacterOption(context, 'jung', 'Carl Jung'),
                 const SizedBox(height: 16),
                 _buildCharacterOption(context, 'İbnSîrîn', 'İbn Sîrîn'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterOption(BuildContext context, String character, String name) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onSend(name);
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.purpleAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/characters/$character.jpg'),
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF9D50BB), Color(0xFF6A3BED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
             child: IconButton(
         icon: isLoading
             ? const SizedBox(
                 width: 24,
                 height: 24,
                 child: CircularProgressIndicator(
                   strokeWidth: 2,
                   color: Colors.white,
                 ),
               )
             : const Icon(Icons.send_rounded, color: Colors.white, size: 28),
         onPressed: isLoading ? null : () => _showCharacterSelectionDialog(context),
       ),
    );
  }
}