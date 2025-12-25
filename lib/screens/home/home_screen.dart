import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  final List<Map<String, dynamic>> _currentConversation = [];
  final List<List<Map<String, dynamic>>> _chatHistory = [];

  bool _isLoading = false;
  bool _showInput = true;

  int? _editingIndex;
  final Map<int, TextEditingController> _editControllers = {};
  Locale? _previousLocale;

  List<String> _getDreamQuotes(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return [
      t.dreamQuote1,
      t.dreamQuote2,
      t.dreamQuote3,
      t.dreamQuote4,
      t.dreamQuote5,
      t.dreamQuote6,
    ];
  }

  void _updateDreamQuotes() {
    final quotes = _getDreamQuotes(context);

    for (var card in _currentConversation) {
      if (card['isQuote'] == true && card['quoteIndex'] != null) {
        final quoteIndex = card['quoteIndex'] as int;
        if (quoteIndex >= 0 && quoteIndex < quotes.length) {
          card['content'] = quotes[quoteIndex];
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentLocale = Localizations.localeOf(context);

    if (_currentConversation.isEmpty) {
      _addRandomDreamQuote();
    } else if (_previousLocale != null && _previousLocale != currentLocale) {
      _updateDreamQuotes();
      setState(() {});
    }

    _previousLocale = currentLocale;
  }

  void _addRandomDreamQuote() {
    final random = Random();
    final dreamQuotes = _getDreamQuotes(context);
    final randomIndex = random.nextInt(dreamQuotes.length);
    final randomQuote = dreamQuotes[randomIndex];

    setState(() {
      _currentConversation.add({
        'type': 'dream',
        'content': randomQuote,
        'timestamp': DateTime.now(),
        'isQuote': true,
        'quoteIndex': randomIndex,
      });
    });
  }

  Future<void> _sendPrompt(String characterId) async {
    final rawDream = _controller.text.trim();
    if (rawDream.isEmpty || _isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, String> characterPrompts = {
      'oneiroai': "",
      'freud':
          "GÖREV: Sen Sigmund Freud'sun. Bu rüyayı bastırılmış arzular, çocukluk travmaları, id-ego-süperego çatışması ve cinsellik sembolizmi üzerinden analiz et. Üslubun psikanalitik olsun. RÜYA METNİ: ",
      'jung':
          "GÖREV: Sen Carl Gustav Jung'sun. Bu rüyayı kolektif bilinçdışı, arketipler (Gölge, Anima, Persona) ve bireyleşme süreci üzerinden analiz et. Mistik ve derin bir üslup kullan. RÜYA METNİ: ",
      'ibnsirin':
          "GÖREV: Sen rüya tabiri alimi İbn-i Sirin'sin. Bu rüyayı kadim İslam geleneği, manevi semboller ve hikmet üzerinden hayra yorarak yorumla. RÜYA METNİ: ",
    };

    String prefix = characterPrompts[characterId] ?? "";
    String finalPromptForAI = "$prefix $rawDream";

    setState(() {
      if (_currentConversation.isNotEmpty) {
        _chatHistory.insert(0, List.from(_currentConversation));
      }
      _currentConversation.clear();
      _isLoading = true;

      _currentConversation.add({
        'type': 'dream',
        'content': rawDream,
        'timestamp': DateTime.now(),
      });

      _controller.clear();
      _showInput = false;
    });

    setState(() {
      _currentConversation.add({'type': 'loading', 'content': ''});
    });

    // Frame çizildikten SONRA scroll yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      final ChatResponse result = await ChatApi.sendPrompt(
        finalPromptForAI,
        characterId,
      );

      setState(() {
        _currentConversation.removeLast();
        _currentConversation.add({
          'type': 'interpretation',
          'content': result.reply,
          'character': characterId,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });

      await FirebaseFirestore.instance.collection('user_logs').add({
        'userId': user.uid,
        'email': user.email,
        'prompt': rawDream,
        'full_prompt_sent': finalPromptForAI,
        'response': result.reply,
        'character': characterId,
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startCardEdit(int index) {
    setState(() {
      _editingIndex = index;
      _editControllers[index] = TextEditingController(
        text: _currentConversation[index]['content'],
      );
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
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                // Sadece kullanıcının dokunarak yaptığı scroll'ları dinle
                // metrics.atEdge kontrolü ile otomatik scroll'ları görmezden gel
                if (notification.metrics.atEdge) return true;

                final direction = notification.direction;

                if (direction == ScrollDirection.reverse) {
                  if (_showInput) {
                    setState(() => _showInput = false);
                  }
                } else if (direction == ScrollDirection.forward) {
                  if (!_showInput) {
                    setState(() => _showInput = true);
                  }
                }
                return true;
              },
              child: ListView.builder(
                controller: _scrollController,
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
          ),
          if (_editingIndex == null)
            Align(
              alignment: _showInput
                  ? Alignment.bottomCenter
                  : Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                  child: _showInput
                      ? FloatingInput(
                          key: const ValueKey('input'),
                          controller: _controller,
                          isLoading: _isLoading,
                          onSend: _sendPrompt,
                          focusNode: _focusNode,
                        )
                      : PlusButton(
                          key: const ValueKey('button'),
                          onPressed: () {
                            setState(() => _showInput = true);
                            _scrollToBottom();

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _focusNode.requestFocus();
                              }
                            });
                          },
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
