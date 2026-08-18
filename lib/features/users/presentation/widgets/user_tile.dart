import 'package:chat_app/core/utils/date_format.dart';
import 'package:chat_app/core/widgets/user_avatar.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.currentUserId,
    required this.onTap,
    this.preview,
  });

  final UserEntity user;
  final String currentUserId;
  final ChatPreviewEntity? preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = preview?.lastMessageTime;
    return ListTile(
      leading: UserAvatar(name: user.displayName),
      title: Text(user.displayName),
      subtitle: Text(
        _subtitle(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: time == null
          ? null
          : Text(
              formatMessageTime(time),
              style: Theme.of(context).textTheme.bodySmall,
            ),
      onTap: onTap,
    );
  }

  String _subtitle() {
    final preview = this.preview;
    if (preview == null || !preview.hasPreview) {
      return user.email;
    }
    if (preview.lastMessageSenderId == currentUserId) {
      return 'You: ${preview.lastMessage}';
    }
    return preview.lastMessage;
  }
}
