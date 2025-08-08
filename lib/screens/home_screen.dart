import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oneiro/services/chat_api.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _isScrollingDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final currentPosition = _scrollController.offset;
    
    setState(() {
      _isScrollingDown = currentPosition > _lastScrollPosition;
      _lastScrollPosition = currentPosition;
      
      // Show input when scrolling up, hide when scrolling down
      if (_isScrollingDown && _showInput) {
        _showInput = false;
      } else if (!_isScrollingDown && !_showInput) {
        _showInput = true;
      }
    });
  }

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

      // Firestore token logging
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
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

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

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    setState(() {
      _dreamCards.clear();
      _showInput = true;
    });

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

  Widget _buildDreamCard(String content) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.nightlight_round, 
                    color: Colors.blueAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rüya analizi tamamlandı',
                  style: GoogleFonts.nunito(
                    color: Colors.blueAccent,
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
      ),
    );
  }

  Widget _buildInterpretationCard(String content) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
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
                  child: Image.asset('assets/images/icon.png', height: 24, width: 24),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF0F0F1A),
    appBar: AppBar(
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
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70),
          onPressed: _signOut,
          tooltip: 'Çıkış Yap',
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              itemCount: _dreamCards.length,
              itemBuilder: (context, index) {
                final card = _dreamCards[index];
                if (card['type'] == 'interpretation') {
                  return _buildInterpretationCard(card['content']);
                }
                // Diğer kartlar (dream vs hata) için boş bırak
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    ), // SafeArea kapanışı
  // Scaffold kapanışı




      // Modern floating input that appears/disappears based on scroll
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF9D50BB),
                            Color(0xFF6A3BED),
                          ],
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
                            : const Icon(Icons.send_rounded, 
                                color: Colors.white, size: 28),
                        onPressed: _isLoading ? null : _sendPrompt,
                      ),
                    ),
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}