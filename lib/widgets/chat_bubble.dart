import 'package:flutter/material.dart';

class ChatBubble extends StatefulWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: widget.isUser ? const Color(0xFF7B5CFF) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _expanded ? widget.text : (widget.text.length > 100 ? '${widget.text.substring(0, 100)}...' : widget.text),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
