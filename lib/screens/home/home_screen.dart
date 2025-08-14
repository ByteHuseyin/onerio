import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneiro/screens/settings_screen.dart';
import 'package:oneiro/services/chat_api.dart';
import 'package:oneiro/screens/home/home_app_bar.dart';
import 'package:oneiro/screens/home/dream_card.dart';
import 'package:oneiro/screens/home/interpretation_card.dart';
import 'package:oneiro/screens/home/error_card.dart';
import 'package:oneiro/screens/home/shimmer_card.dart';
import 'package:oneiro/screens/home/floating_input.dart';
import 'package:oneiro/screens/home/plus_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Yalnızca aktif konuşmayı tutan liste
  final List<Map<String, dynamic>> _currentConversation = [];
  // Geçmiş konuşmaları tutan liste
  final List<List<Map<String, dynamic>>> _chatHistory = [];

  bool _isLoading = false;
  bool _showInput = true;
  double _lastScrollPosition = 0;

  int? _editingIndex;
  final Map<int, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final current = _scrollController.offset;
    final scrollingDown = current > _lastScrollPosition;

    if (scrollingDown && _showInput) {
      setState(() => _showInput = false);
    } else if (!scrollingDown && !_showInput) {
      setState(() => _showInput = true);
    }

    _lastScrollPosition = current;
  }

  Future<void> _sendPrompt() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() {
      // Önceki konuşmayı geçmişe kaydet
      if (_currentConversation.isNotEmpty) {
        _chatHistory.insert(0, List.from(_currentConversation));
      }
      // Yeni rüya için listeyi temizle
      _currentConversation.clear();
      _isLoading = true;
      _currentConversation.add({
        'type': 'dream',
        'content': prompt,
        'timestamp': DateTime.now(),
      });
      _controller.clear();
      _showInput = false;
    });

    // Yükleme efekti için shimmer kartını ekle
    setState(() {
      _currentConversation.add({
        'type': 'loading',
        'content': '',
      });
    });

    _scrollToBottom();

    try {
      final ChatResponse result = await ChatApi.sendPrompt(prompt);

      setState(() {
        // Shimmer'ı kaldır ve yorum kartını ekle
        _currentConversation.removeLast();
        _currentConversation.add({
          'type': 'interpretation',
          'content': result.reply,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });

      await FirebaseFirestore.instance.collection('user_logs').add({
        'userId': user.uid,
        'email': user.email,
        'prompt': prompt,
        'response': result.reply,
        'timestamp': FieldValue.serverTimestamp(),
        'prompt_tokens': result.promptTokens,
        'response_tokens': result.responseTokens,
      });
    } catch (e) {
      setState(() {
        _currentConversation.removeLast();
        _currentConversation.add({
          'type': 'error',
          'content': 'Yorum alınırken bir hata oluştu: $e',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Bu metot, geçmiş konuşmaları tekrar ekrana getirir
  void _loadHistoryChat(int index) {
    setState(() {
      // Mevcut konuşmayı kaydetmeden geçmişten yükle
      _currentConversation.clear();
      _currentConversation.addAll(List.from(_chatHistory[index]));
    });
    Navigator.pop(context); // Menüyü kapat
  }

  void _showHistoryDrawer() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: const Color(0xFF0F0F1A),
          child: ListView.builder(
            itemCount: _chatHistory.length,
            itemBuilder: (context, index) {
              final firstPrompt = _chatHistory[index][0]['content'];
              return ListTile(
                title: Text(
                  firstPrompt,
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _loadHistoryChat(index),
              );
            },
          ),
        );
      },
    );
  }

  void _startCardEdit(int index) {
    // ... Düzenleme mantığı aynı
  }

  Future<void> _saveCardEdit(int index) async {
    // ... Düzenleme kaydetme mantığı aynı
  }

  void _cancelCardEdit(int index) {
    // ... Düzenleme iptal etme mantığı aynı
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: HomeAppBar(
        onSettingsPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
       // onHistoryPressed: _showHistoryDrawer,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              // ListView artık tersine çevrilmeyecek
              reverse: false,
              physics: const BouncingScrollPhysics(),
              itemCount: _currentConversation.length,
              itemBuilder: (context, index) {
                final card = _currentConversation[index];
                
                if (card['type'] == 'dream') {
                  return DreamCard(
                    content: card['content'],
                    index: index,
                    isEditing: _editingIndex == index,
                    editController: _editControllers[index],
                    isLoading: _isLoading,
                    onEdit: _startCardEdit,
                    onSave: _saveCardEdit,
                    onCancel: _cancelCardEdit,
                  );
                } else if (card['type'] == 'interpretation') {
                  return InterpretationCard(content: card['content']);
                } else if (card['type'] == 'loading') {
                  return const ShimmerCard();
                } else if (card['type'] == 'error') {
                  return ErrorCard(message: card['content']);
                }
      
                return ErrorCard(message: 'Beklenmeyen bir hata oluştu');
              },
            ),
          ),
          if (_editingIndex == null) 
            Align(
              alignment: _showInput ? Alignment.bottomCenter : Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _showInput
                    ? FloatingInput(
                        controller: _controller,
                        isLoading: _isLoading,
                        onSend: _sendPrompt,
                      )
                    : PlusButton(
                        onPressed: () {
                          setState(() => _showInput = true);
                          _scrollToBottom();
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}