import 'package:chat_app/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isSending = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: controller,
                hint: enabled ? 'Message' : 'Waiting for connection',
                enabled: enabled && !isSending,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLines: 4,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: !enabled || isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
