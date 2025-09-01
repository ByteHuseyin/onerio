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
import 'package:oneiro/l10n/app_localizations.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // Yalnızca aktif konuşmayı tutan liste
  final List<Map<String, dynamic>> _currentConversation = [];
  // Geçmiş konuşmaları tutan liste
  final List<List<Map<String, dynamic>>> _chatHistory = [];

  bool _isLoading = false;
  bool _showInput = true;
  double _lastScrollPosition = 0;

  int? _editingIndex;
  final Map<int, TextEditingController> _editControllers = {};
  
  // Rastgele rüya cümleleri
  List<String> _getDreamQuotes(BuildContext context) {
    return [
      AppLocalizations.of(context)!.dreamQuote1,
      AppLocalizations.of(context)!.dreamQuote2,
      AppLocalizations.of(context)!.dreamQuote3,
      AppLocalizations.of(context)!.dreamQuote4,
      AppLocalizations.of(context)!.dreamQuote5,
      AppLocalizations.of(context)!.dreamQuote6,
    ];
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Uygulama açıldığında input'a odaklan ve klavyeyi aç
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // İlk kez çağrıldığında rastgele rüya cümlesi ekle
    if (_currentConversation.isEmpty) {
      _addRandomDreamQuote();
    }
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
  
  void _addRandomDreamQuote() {
    final random = Random();
    final dreamQuotes = _getDreamQuotes(context);
    final randomQuote = dreamQuotes[random.nextInt(dreamQuotes.length)];
    
    setState(() {
      _currentConversation.add({
        'type': 'dream',
        'content': randomQuote,
        'timestamp': DateTime.now(),
        'isQuote': true, // Bu bir alıntı olduğunu belirtmek için
      });
    });
  }

  Future<void> _sendPrompt(String character) async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() {
      // Önceki konuşmayı geçmişe kaydet
      if (_currentConversation.isNotEmpty) {
        _chatHistory.insert(0, List.from(_currentConversation));
      }
      // Yeni rüya için listeyi temizle (alıntı kartı da dahil)
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
      final ChatResponse result = await ChatApi.sendPrompt(prompt, character);

      setState(() {
        // Shimmer'ı kaldır ve yorum kartını ekle
        _currentConversation.removeLast();
        _currentConversation.add({
          'type': 'interpretation',
          'content': result.reply,
          'character': character,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });

      await FirebaseFirestore.instance.collection('user_logs').add({
        'userId': user.uid,
        'email': user.email,
        'prompt': prompt,
        'response': result.reply,
        'character': character,
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
    setState(() {
      _editingIndex = index;
      _editControllers[index] =
          TextEditingController(text: _currentConversation[index]['content']);
    });
  }

  Future<void> _saveCardEdit(int index) async {
    final newText = _editControllers[index]?.text.trim() ?? '';
    if (newText.isEmpty) {
      _cancelCardEdit(index);
      return;
    }

    setState(() {
      _currentConversation[index]['content'] = newText;
      _editingIndex = null;
      _editControllers[index]?.dispose();
      _editControllers.remove(index);
    });
  }

  void _cancelCardEdit(int index) {
    setState(() {
      _editingIndex = null;
      _editControllers[index]?.dispose();
      _editControllers.remove(index);
    });
  }

  void _editWithFloatingInput(String content) {
    setState(() {
      _controller.text = content;
      _showInput = true;
    });
    _scrollToBottom();
    
    // Düzenleme modunda da input'a odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
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
    _focusNode.dispose();
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
                    onEditWithFloatingInput: _editWithFloatingInput,
                    isQuote: card['isQuote'] ?? false,
                  );
                } else if (card['type'] == 'interpretation') {
                  return InterpretationCard(
                    content: card['content'],
                    character: card['character'],
                  );
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
                        focusNode: _focusNode,
                      )
                    : PlusButton(
                        onPressed: () {
                          setState(() => _showInput = true);
                          _scrollToBottom();
                          
                          // Plus button tıklandığında da input'a odaklan
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _focusNode.requestFocus();
                            }
                          });
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}