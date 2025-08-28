import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneiro/l10n/app_localizations.dart';

class DreamCard extends StatelessWidget {
  final String content;
  final int index;
  final bool isEditing;
  final TextEditingController? editController;
  final bool isLoading;
  final Function(int) onEdit;
  final Function(int) onSave;
  final Function(int) onCancel;
  final Function(String) onEditWithFloatingInput;
  final bool isQuote;

  const DreamCard({
    super.key,
    required this.content,
    required this.index,
    required this.isEditing,
    this.editController,
    required this.isLoading,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onEditWithFloatingInput,
    this.isQuote = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E2D), Color(0xFF2D2D42)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.25),
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
                  color: isQuote 
                      ? Colors.purpleAccent.withOpacity(0.15)
                      : Colors.blueAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isQuote ? Icons.auto_awesome : Icons.nightlight_round,
                  color: isQuote ? Colors.purpleAccent : Colors.blueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
                             Expanded(
                 child: Text(
                   isQuote 
                       ? AppLocalizations.of(context)!.dreamInspiration 
                       : AppLocalizations.of(context)!.dreamAnalysisCompleted,
                   style: GoogleFonts.nunito(
                     color: isQuote ? Colors.purpleAccent : Colors.blueAccent,
                     fontWeight: FontWeight.w700,
                     fontSize: 18,
                   ),
                 ),
               ),
              if (!isEditing && !isQuote)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                  onPressed: () => onEditWithFloatingInput(content),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEditing)
            Column(
              children: [
                TextField(
                  controller: editController,
                  autofocus: true,
                  maxLines: 5,
                  minLines: 1,
                  style: GoogleFonts.nunito(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: isLoading ? null : () => onSave(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A3BED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(AppLocalizations.of(context)!.save),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: isLoading ? null : () => onCancel(index),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              content,
              style: GoogleFonts.nunito(
                color: isQuote ? Colors.white70 : Colors.white,
                fontSize: isQuote ? 16 : 17,
                height: 1.6,
                fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
              ),
            ),
        ],
      ),
    );
  }
}