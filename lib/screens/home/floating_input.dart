import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneiro/l10n/app_localizations.dart';
import 'package:oneiro/widgets/ad_dialog.dart';

class FloatingInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  // DÜZELTME: Burası sadece saf ID'yi (örn: 'freud') taşıyacak.
  // Hazır prompt'u değil.
  final Function(String characterId) onSend;
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
  // Interpreter Listesi (Sadece veriler)
  static const List<Map<String, String>> _interpreters = [
    {'id': 'oneiroai', 'name': 'OneiroAI'},
    {'id': 'freud', 'name': 'Freud'},
    {'id': 'jung', 'name': 'Jung'},
    {'id': 'ibnsirin', 'name': 'İbn Sîrîn'},
  ];



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
              TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 17),
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.dreamDescription,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              const SizedBox(height: 16),
              _buildInterpreterAvatars(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterpreterAvatars(BuildContext context) {
    final bool isEnabled =
        !widget.isLoading && widget.controller.text.trim().length >= 4;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _interpreters.map((interpreter) {
        return _buildInterpreterAvatar(
          context,
          interpreter['id']!,
          interpreter['name']!,
          isEnabled,
        );
      }).toList(),
    );
  }

  Widget _buildInterpreterAvatar(
    BuildContext context,
    String characterId,
    String name,
    bool isEnabled,
  ) {
    return GestureDetector(
      onTap: isEnabled
          ? () {
              print('Interpreter seçildi: $name ($characterId)');
              _showAdDialog(context, characterId);
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/characters/$characterId.jpg'),
                fit: BoxFit.cover,
                colorFilter: isEnabled
                    ? null
                    : ColorFilter.mode(
                        Colors.black.withOpacity(0.5),
                        BlendMode.darken,
                      ),
              ),
              border: Border.all(
                color: isEnabled
                    ? Colors.purpleAccent.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.nunito(
              color: isEnabled
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdDialog(BuildContext context, String characterId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AdDialog(
          characterName: characterId,
          onContinue: (String _) {
            // DÜZELTME:
            // Burada artık prompt birleştirmiyoruz.
            // Sadece saf ID'yi (örn: 'freud') parent'a yolluyoruz.

            print(
              'AdMob: Dialog kapandı, Seçilen ID gönderiliyor: $characterId',
            );
            widget.onSend(characterId);
          },
          onCancel: () {
            print('AdMob: Kullanıcı vazgeçti');
          },
        );
      },
    );
  }
}
