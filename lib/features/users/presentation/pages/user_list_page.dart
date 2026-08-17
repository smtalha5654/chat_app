import 'package:chat_app/core/router/app_routes.dart';
import 'package:chat_app/features/chat/presentation/pages/chat_page_args.dart';
import 'package:flutter/material.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  static const _placeholderUsers = [
    (name: 'Alex Morgan', preview: 'Hey, are you around?'),
    (name: 'Sam Lee', preview: 'Talk later.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _placeholderUsers.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _placeholderUsers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Text(user.name[0]),
            ),
            title: Text(user.name),
            subtitle: Text(
              user.preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.chat,
                arguments: ChatPageArgs(peerName: user.name),
              );
            },
          );
        },
      ),
    );
  }
}
