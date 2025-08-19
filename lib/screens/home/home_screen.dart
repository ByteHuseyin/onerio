import 'dart:io';
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
import 'package:oneiro/services/permission_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _currentConversation = [];
  final List<List<Map<String, dynamic>>> _chatHistory = [];

  bool _isLoading = false;
  bool _showInput = true;
  double _lastScrollPosition = 0;

  int? _editingIndex;
  final Map<int, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _askNotificationPermission();
    _scrollController.addListener(_scrollListener);
  }




  Future<void> _askNotificationPermission() async {
    final permissionService = PermissionService();
    final hasPermission =
    await permissionService.requestNotificationPermission();

    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim izni verilmedi, hatırlatmalar çalışmayabilir.'),
        ),
      );
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

  Future<void> _sendPrompt() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İnternet bağlantınızı kontrol edin.'),
            backgroundColor: Color(0xFFFFFFFF),
          ),
        );
      }
      return;
    }

    setState(() {
      if (_currentConversation.isNotEmpty) {
        _chatHistory.insert(0, List.from(_currentConversation));
      }
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
    } on SocketException catch (_) {
      setState(() {
        _currentConversation.removeLast();
        _currentConversation.add({
          'type': 'error',
          'content': 'İnternet bağlantınızı kontrol edin.',
          'timestamp': DateTime.now(),
        });
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
      _scrollToBottom();
    }
  }
  // UYGULAMADAN ÇIKIŞ ONAY DİYALOĞU METODU
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text(
          'Uygulamadan Çıkılsın mı?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Uygulamadan çıkmak istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }
  void _loadHistoryChat(int index) {
    setState(() {
      _currentConversation.clear();
      _currentConversation.addAll(List.from(_chatHistory[index]));
    });
    Navigator.pop(context);
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
    final currentText = _currentConversation[index]['content'];
    _editControllers[index] = TextEditingController(text: currentText);
    setState(() => _editingIndex = index);
  }

  Future<void> _saveCardEdit(int index) async {
    final controller = _editControllers[index];
    if (controller == null) return;
    final newText = controller.text.trim();
    if (newText.isEmpty) {
      _cancelCardEdit(index);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _cancelCardEdit(index);
      return;
    }

    setState(() {
      _isLoading = true;
      _currentConversation[index]['content'] = newText;
      _editingIndex = null;
    });

    _scrollToBottom();

    try {
      _currentConversation.insert(index + 1, {
        'type': 'loading',
        'content': '',
      });
      final ChatResponse result = await ChatApi.sendPrompt(newText);

      setState(() {
        // Yükleme efekti kartını listeden kaldırır ve yorumu ekler.
        _currentConversation.removeAt(index + 1);

        if (index + 1 < _currentConversation.length &&
            _currentConversation[index + 1]['type'] == 'interpretation') {
          _currentConversation[index + 1] = {
            'type': 'interpretation',
            'content': result.reply,
            'timestamp': DateTime.now(),
          };
        } else {
          _currentConversation.insert(index + 1, {
            'type': 'interpretation',
            'content': result.reply,
            'timestamp': DateTime.now(),
          });
        }
      });

      controller.dispose();
      _editControllers.remove(index);

      await FirebaseFirestore.instance.collection('user_logs').add({
        'userId': user.uid,
        'email': user.email,
        'prompt': newText,
        'response': result.reply,
        'timestamp': FieldValue.serverTimestamp(),
        'prompt_tokens': result.promptTokens,
        'response_tokens': result.responseTokens,
      });
    } catch (e) {
      if (index + 1 < _currentConversation.length &&
          _currentConversation[index + 1]['type'] == 'loading') {
        _currentConversation.removeAt(index + 1);
      }
      setState(() {
        _currentConversation.insert(index + 1, {
          'type': 'error',
          'content': 'Güncelleme sırasında hata: $e',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
      // Yalnızca hata durumunda dispose ve remove çağrısı
      // try bloğunda zaten yapıldığı için burayı siliyoruz.
    }
  }

  void _cancelCardEdit(int index) {
    final controller = _editControllers[index];
    if (controller != null) {
      controller.dispose();
      _editControllers.remove(index);
    }
    setState(() {
      _editingIndex = null;
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
    for (final c in _editControllers.values) {
      c.dispose();
    }
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold'ı PopScope ile sarıyoruz
    return PopScope(
      canPop: false, // Varsayılan geri gitme eylemini engeller
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();

        if (shouldPop) {
          if (Navigator.of(context).canPop()) {
            SystemNavigator.pop();
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: HomeAppBar(
          onSettingsPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          // onHistoryPressed: _showHistoryDrawer, // opsiyonel
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
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
                  return const ErrorCard(message: 'Beklenmeyen bir hata oluştu');
                },
              ),
            ),
            if (_editingIndex == null)
              Align(
                alignment:
                _showInput ? Alignment.bottomCenter : Alignment.bottomRight,
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
      ),
    );
  }
}