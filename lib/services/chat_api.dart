import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ChatResponse {
  final String reply;
  final int promptTokens;
  final int responseTokens;

  ChatResponse({
    required this.reply,
    required this.promptTokens,
    required this.responseTokens,
  });
}

class ChatApi {
  static const String _cloudFunctionUrl =
      'https://europe-west1-onerioapp.cloudfunctions.net/chatWithOpenAI';

  static Future<ChatResponse> sendPrompt(String prompt, String character) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış.');

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse(_cloudFunctionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'prompt': prompt,
        'character': character,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['reply']?.toString().trim() ?? '';
      final usage = data['usage'];

      // Token hesaplama: usage varsa onu kullan, yoksa tahmin et
      final promptTokens = usage?['prompt_tokens'] ?? _estimateTokens(prompt);
      final responseTokens = usage?['completion_tokens'] ?? _estimateTokens(reply);

      return ChatResponse(
        reply: reply,
        promptTokens: promptTokens,
        responseTokens: responseTokens,
      );
    } else {
      throw Exception('API Hatası: ${response.body}');
    }
  }

  // Ortalama 1 token ≈ 4 karakter
  static int _estimateTokens(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return (cleaned.length / 4).ceil();
  }
}
