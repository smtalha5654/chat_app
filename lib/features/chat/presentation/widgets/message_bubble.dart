import 'package:chat_app/core/theme/app_colors.dart';
import 'package:chat_app/core/utils/date_format.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final MessageEntity message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isMine
        ? AppColors.sentBubble
        : (isDark
              ? AppColors.receivedBubbleDark
              : AppColors.receivedBubbleLight);
    final fg = isMine ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final timeColor = isMine
        ? Colors.white.withValues(alpha: 0.8)
        : Theme.of(context).hintColor;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text, style: TextStyle(color: fg)),
            const SizedBox(height: 4),
            Text(
              formatMessageTime(message.timestamp),
              style: TextStyle(color: timeColor, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
