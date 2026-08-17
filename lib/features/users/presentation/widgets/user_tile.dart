import 'package:chat_app/core/widgets/user_avatar.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  final UserEntity user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(name: user.displayName),
      title: Text(user.displayName),
      subtitle: Text(
        user.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
