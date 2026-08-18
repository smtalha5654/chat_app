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

  static const _avatarColors = [
    Color(0xFF2E6F6A),
    Color(0xFF3D7A6F),
    Color(0xFF4A6E62),
    Color(0xFF3A6B80),
    Color(0xFF5C6B52),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final time = preview?.lastMessageTime;
    final hasPreview = preview != null && preview!.hasPreview;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE4E8E7),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                UserAvatar(
                  name: user.displayName,
                  radius: 22,
                  backgroundColor: _avatarColor(user.displayName),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (time != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              formatMessageTime(time),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasPreview
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.64,
                                )
                              : theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _avatarColor(String name) {
    final hash = name.hashCode.abs();
    return _avatarColors[hash % _avatarColors.length];
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
