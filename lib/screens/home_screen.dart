import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneiro/routes.dart';
import 'package:oneiro/screens/history_screen.dart';

import 'package:oneiro/services/chat_api.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _dreamCards = [];

  bool _isLoading = false;
  bool _showInput = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  // Scroll yönüne göre input alanını göster/gizle
  void _scrollListener() {
    final current = _scrollController.offset;
    final scrollingDown = current > _lastScrollPosition;

    if (scrollingDown != !_showInput) {
      setState(() => _showInput = !scrollingDown);
    }

    _lastScrollPosition = current;
  }

  // Prompt gönderme
  Future<void> _sendPrompt() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _dreamCards.add({
        'type': 'dream',
        'content': prompt,
        'timestamp': DateTime.now(),
      });
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final ChatResponse result = await ChatApi.sendPrompt(prompt);

      setState(() {
        _dreamCards.add({
          'type': 'interpretation',
          'content': result.reply,
          'timestamp': DateTime.now(),
        });
      });

      // Firestore log kaydı
      await FirebaseFirestore.instance.collection('user_logs').add({
        'userId': user.uid,
        'email': user.email,
        'prompt': prompt,
        'response': result.reply,
        'timestamp': FieldValue.serverTimestamp(),
        'prompt_tokens': result.promptTokens,
        'response_tokens': result.responseTokens
      });
    } catch (e) {
      setState(() {
        _dreamCards.add({
          'type': 'error',
          'content': 'Yorum alınırken bir hata oluştu: $e',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  // Scroll'u en alta kaydır
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Çıkış yap
  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    _dreamCards.clear();
    _showInput = true;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Rüya kartı
  Widget _buildDreamCard(String content) => _buildCard(
        title: 'Rüya analizi tamamlandı',
        icon: Icons.nightlight_round,
        iconColor: Colors.blueAccent,
        gradient: const [Color(0xFF1E1E2D), Color(0xFF2D2D42)],
        content: content,
      );

  // Yorum kartı
  Widget _buildInterpretationCard(String content) => _buildCard(
        title: 'Onerio Yorumu',
        iconAsset: 'assets/images/icon.png',
        iconColor: Colors.purpleAccent,
        gradient: const [Color(0xFF2A1B4D), Color(0xFF3D2A6F)],
        content: content,
      );

  // Kart oluşturucu
  Widget _buildCard({
    required String title,
    IconData? icon,
    String? iconAsset,
    required Color iconColor,
    required List<Color> gradient,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.25),
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
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: icon != null
                    ? Icon(icon, color: iconColor, size: 24)
                    : Image.asset(iconAsset!, height: 24, width: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.nunito(
                  color: iconColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: _buildAppBar(),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _dreamCards.length,
        itemBuilder: (context, index) {
          final card = _dreamCards[index];
          if (card['type'] == 'dream') {
            return _buildDreamCard(card['content']);
          } else if (card['type'] == 'interpretation') {
            return _buildInterpretationCard(card['content']);
          } else {
            return _buildCard(
              title: 'Hata',
              icon: Icons.error_outline,
              iconColor: Colors.redAccent,
              gradient: const [Color(0xFF2D1B1B), Color(0xFF4A2A2A)],
              content: card['content'],
            );
          }
        },
      ),
      floatingActionButton: _buildFloatingInput(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // AppBar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/icon.png', height: 36),
          const SizedBox(width: 12),
          Text(
            'Onerio',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings, color: Colors.white70),
          color: const Color(0xFF1A1A2A),
          onSelected: (value) {
            if (value == 'logout') {
              _signOut();
              }
            // Diğer sayfalar burada yönlendirilir.
            else if (value == 'history'){
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            }
          },
          itemBuilder: (context) => [
            _popupItem(Icons.color_lens, 'Tema', 'theme'),
            _popupItem(Icons.language, 'Dil', 'language'),
            _popupItem(Icons.history, 'Geçmiş', 'history'),
            const PopupMenuDivider(),
            _popupItem(Icons.logout, 'Çıkış Yap', 'logout',
                color: Colors.redAccent),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _popupItem(
      IconData icon, String text, String value,
      {Color color = Colors.white70}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // Floating input
  Widget _buildFloatingInput() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _showInput ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showInput ? 1 : 0,
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
                      controller: _controller,
                      maxLines: 3,
                      minLines: 1,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Dün gece rüyamda...',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _sendButton(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rüyanızı detaylı şekilde anlatın, Onerio yorumlasın',
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

  // Gönder butonu
  Widget _sendButton() {
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
          )
        ],
      ),
      child: IconButton(
        icon: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 28),
        onPressed: _isLoading ? null : _sendPrompt,
      ),
    );
  }
}
