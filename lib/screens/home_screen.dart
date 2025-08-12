import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneiro/screens/settings_screen.dart';
import 'package:oneiro/services/chat_api.dart';

import 'package:shimmer/shimmer.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoading = true;
  final List<Map<String, dynamic>> _dreamCards = [];

  bool _isLoading = false;
  bool _showInput = true; // İlk açılışta input görünür
  double _lastScrollPosition = 0;

  // Düzenleme için
  int? _editingIndex;
  final Map<int, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  // Scroll yönüne göre input alanını göster/gizle
  void _scrollListener() {
    // Düzenleme sırasında da kaydırma açık kalacak (kullanıcının isteği)
    final current = _scrollController.offset;
    final scrollingDown = current > _lastScrollPosition;

    if (scrollingDown && _showInput) {
      setState(() => _showInput = false);
    } else if (!scrollingDown && !_showInput) {
      setState(() => _showInput = true);
    }

    _lastScrollPosition = current;
  }

  // Yeni rüya prompt gönderme
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
      _showInput = false; // Gönderince input bar kapansın, + butonu gelsin
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
        _isLoading = false;
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

  // Kart içi düzenlemeyi başlat
  void _startCardEdit(int index) {
    setState(() {
      _editingIndex = index;
      _editControllers[index] =
          TextEditingController(text: _dreamCards[index]['content'] ?? '');
      _editControllers[index]!.selection = TextSelection.fromPosition(
        TextPosition(offset: _editControllers[index]!.text.length),
      );
    });
  }

  // Kart içi düzenlemeyi kaydet -> hem rüya güncellenir hem yorum yeniden alınır/güncellenir
  Future<void> _saveCardEdit(int index) async {
    final controller = _editControllers[index];
    if (controller == null) return;
    final newText = controller.text.trim();
    if (newText.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      _isLoading = true;
      // Önce rüya içeriğini güncelle
      _dreamCards[index]['content'] = newText;
    });

    _scrollToBottom();

    try {
      // Yeni yorum için ChatApi çağrısı
      final ChatResponse result = await ChatApi.sendPrompt(newText);

      setState(() {
        // Eğer index+1'de yorum varsa güncelle, yoksa ekle
        if (index + 1 < _dreamCards.length &&
            _dreamCards[index + 1]['type'] == 'interpretation') {
          _dreamCards[index + 1] = {
            'type': 'interpretation',
            'content': result.reply,
            'timestamp': DateTime.now(),
          };
        } else {
          _dreamCards.insert(index + 1, {
            'type': 'interpretation',
            'content': result.reply,
            'timestamp': DateTime.now(),
          });
        }

        // Düzenleme bitti, controller'ı temizle
        _editingIndex = null;
        controller.dispose();
        _editControllers.remove(index);
      });

      // Firestore log kaydı (güncellenmiş rüya için de log alıyoruz)
      if (user != null) {
        await FirebaseFirestore.instance.collection('user_logs').add({
          'userId': user.uid,
          'email': user.email,
          'prompt': newText,
          'response': result.reply,
          'timestamp': FieldValue.serverTimestamp(),
          'prompt_tokens': result.promptTokens,
          'response_tokens': result.responseTokens
        });
      }
    } catch (e) {
      // Hata durumunda kullanıcıya hata kartı göster
      setState(() {
        _dreamCards.add({
          'type': 'error',
          'content': 'Güncelleme sırasında hata: $e',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  // Kart içi düzenlemeyi iptal et
  void _cancelCardEdit(int index) {
    final controller = _editControllers[index];
    if (controller != null) {
      controller.dispose();
      _editControllers.remove(index);
    }
    setState(() => _editingIndex = null);
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

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _editControllers.values) {
      c.dispose();
    }
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Rüya kartı (düzenleme destekli)
  Widget _buildDreamCard(String content, int index) {
    final isEditing = _editingIndex == index;
    final editController = _editControllers[index];

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
                  color: Colors.blueAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.nightlight_round,
                    color: Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rüya analizi tamamlandı',
                  style: GoogleFonts.nunito(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              // Düzenle butonu (kart içi düzenleme başlat)
              if (!isEditing)
                IconButton(
                  icon:
                      const Icon(Icons.edit, color: Colors.white70, size: 20),
                  onPressed: () => _startCardEdit(index),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Eğer düzenleme modundaysa kart içi TextField göster
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
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _saveCardEdit(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A3BED),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kaydet'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _isLoading ? null : () => _cancelCardEdit(index),
                      child: const Text('İptal',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ],
            )
          else
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

  // Yorum kartı (aynı kaldı)
  Widget _buildInterpretationCard(String content) => _buildCard(
        title: 'Onerio Yorumu',
        iconAsset: 'assets/images/icon.png',
        iconColor: Colors.purpleAccent,
        gradient: const [Color(0xFF2A1B4D), Color(0xFF3D2A6F)],
        content: content,
      );

  // Genel kart oluşturucu (yorumlar ve hatalar için)
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

  // Floating input (orijinal görünümü korundu)
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

  // Gönder butonu (orijinal)
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

  // + butonu
  Widget _buildPlusButton() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF6A3BED),
      onPressed: () {
        setState(() {
          _showInput = true;
        });
      },
      child: const Icon(Icons.add, size: 28, color: Colors.white),
    );
  }

  // AppBar
  AppBar _buildAppBar() {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    automaticallyImplyLeading: false, // geri butonu istemiyorsan false
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
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



  @override
  Widget build(BuildContext context) {
    // Scroll her zaman açık (kullanıcının isteği)
    final listPhysics = const BouncingScrollPhysics();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: _buildAppBar(),
body: ListView.builder(
  controller: _scrollController,
  physics: listPhysics,
  itemCount: _dreamCards.length + (_isLoading ? 1 : 0),
  itemBuilder: (context, index) {
    // Eğer yükleme devam ediyorsa ve son eklenen kart yorum değilse shimmer göster
    if (_isLoading && index == _dreamCards.length) {
      return _buildShimmerCard();
    }

    // Normal kart gösterimi
    if (index < _dreamCards.length) {
      final card = _dreamCards[index];
      if (card['type'] == 'dream') {
        return _buildDreamCard(card['content'], index);
      } else if (card['type'] == 'interpretation') {
        return _buildInterpretationCard(card['content']);
      }
    }

    // Default hata kartı
    return _buildCard(
      title: 'Hata',
      icon: Icons.error_outline,
      iconColor: Colors.redAccent,
      gradient: const [Color(0xFF2D1B1B), Color(0xFF4A2A2A)],
      content: 'Beklenmeyen bir hata oluştu',
    );
  },
),

      // Floating action: eğer düzenleme yapılıyorsa gizle, değilse input veya + butonu göster
      floatingActionButton: _editingIndex != null
          ? null
          : (_showInput ? _buildFloatingInput() : _buildPlusButton()),
      floatingActionButtonLocation: _showInput
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
Widget _buildShimmerCard() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // yorum kartı ile aynı
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent, // yorum kartındaki arka plan rengi neyse onu kullan
    ),
    child: Shimmer.fromColors(
      baseColor: Colors.blueGrey[900]!,
      highlightColor: Colors.blueGrey[700]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueGrey[900]!.withOpacity(0.8), // yorum kartının iç rengi
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık placeholder
            Container(
              height: 20,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            // İçerik satırları placeholder
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}


