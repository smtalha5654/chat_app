import 'package:chat_app/core/router/app_routes.dart';
import 'package:chat_app/core/widgets/chat_app_bar.dart';
import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/core/widgets/user_avatar.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/chat/presentation/pages/chat_page_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  static const _placeholderUsers = [
    (name: 'Alex Morgan', preview: 'Hey, are you around?'),
    (name: 'Sam Lee', preview: 'Talk later.'),
  ];

  Future<void> _onLogout(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        title: 'Chats',
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _onLogout(context),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _placeholderUsers.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _placeholderUsers[index];
          return ListTile(
            leading: UserAvatar(name: user.name),
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
