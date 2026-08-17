import 'package:chat_app/core/theme/app_colors.dart';
import 'package:chat_app/core/widgets/app_text_field.dart';
import 'package:chat_app/core/widgets/chat_app_bar.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.peerName});

  final String peerName;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ChatAppBar(title: widget.peerName),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _Bubble(
                  text: 'Hey, are you around?',
                  isMine: false,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _Bubble(
                  text: 'Yes, just got back.',
                  isMine: true,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _messageController,
                      hint: 'Message',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isMine,
    required this.isDark,
  });

  final String text;
  final bool isMine;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isMine
        ? AppColors.sentBubble
        : (isDark
              ? AppColors.receivedBubbleDark
              : AppColors.receivedBubbleLight);
    final fg = isMine ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: TextStyle(color: fg)),
      ),
    );
  }
}
