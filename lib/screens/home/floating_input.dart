import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneiro/l10n/app_localizations.dart';
import 'package:oneiro/widgets/ad_dialog.dart';

class FloatingInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String character) onSend;
  final FocusNode? focusNode;

  const FloatingInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
    this.focusNode,
  });

  @override
  State<FloatingInput> createState() => _FloatingInputState();
}

class _FloatingInputState extends State<FloatingInput> {

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
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
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                        onSubmitted: (value) {
                           if (!widget.isLoading && value.trim().length >= 4) {
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
                           horizontal: 4,
                         ),
                       ),
                     ),
                  ),
                  const SizedBox(width: 12),
                  _buildSendButton(context),
                ],
              ),
              // const SizedBox(height: 8),
              // Text(
              //   AppLocalizations.of(context)!.onboardingSubtitle2,
              //   style: GoogleFonts.nunito(
              //     color: Colors.white70,
              //     fontSize: 13,
              //     fontStyle: FontStyle.italic,
              //   ),
              // ),
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
                 _buildCharacterOption(context, 'onerioai', 'OneiroAI'),
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
         
         // Karakter seçimi sonrası reklam dialog'u göster
         print('Karakter seçimi: $name seçildi, reklam dialog\'u gösteriliyor...');
         _showAdDialog(context, name);
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

  // Reklam dialog'u göster
  void _showAdDialog(BuildContext context, String characterName) {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dialog'u kapatamaz
      builder: (BuildContext context) {
        return AdDialog(
          characterName: characterName,
          onContinue: (String character) {
            print('AdMob: Dialog\'dan karakter seçimi tamamlanıyor: $character');
            widget.onSend(character);
          },
          onCancel: () {
            print('AdMob: Kullanıcı vazgeçti, rüya tabiri gösterilmeyecek');
            // Vazgeç butonuna basıldığında hiçbir şey yapma
          },
        );
      },
    );
  }

         Widget _buildSendButton(BuildContext context) {
     final bool isEnabled = !widget.isLoading && widget.controller.text.trim().length >= 4;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isEnabled 
          ? const LinearGradient(
              colors: [Color(0xFF9D50BB), Color(0xFF6A3BED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
        color: isEnabled ? null : Colors.grey.withOpacity(0.3),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: IconButton(
                 icon: widget.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                Icons.send_rounded, 
                color: isEnabled ? Colors.white : Colors.white.withOpacity(0.3), 
                size: 28
              ),
        onPressed: isEnabled ? () => _showCharacterSelectionDialog(context) : null,
      ),
    );
  }
}