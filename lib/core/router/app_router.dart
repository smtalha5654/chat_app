import 'package:chat_app/core/router/app_routes.dart';
import 'package:chat_app/core/utils/chat_id.dart';
import 'package:chat_app/core/widgets/loading_view.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:chat_app/features/auth/presentation/pages/login_page.dart';
import 'package:chat_app/features/auth/presentation/pages/register_page.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:chat_app/features/chat/presentation/pages/chat_page.dart';
import 'package:chat_app/features/chat/presentation/pages/chat_page_args.dart';
import 'package:chat_app/features/profile/presentation/pages/profile_page.dart';
import 'package:chat_app/features/users/presentation/bloc/users_event.dart';
import 'package:chat_app/features/users/presentation/pages/user_list_page.dart';
import 'package:chat_app/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.bootstrap:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: LoadingView()),
        );
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case AppRoutes.users:
        return MaterialPageRoute(
          builder: (context) {
            final authState = context.read<AuthBloc>().state;
            final currentUserId = authState is Authenticated
                ? authState.user.id
                : '';
            return BlocProvider(
              create: (_) =>
                  createUsersBloc()
                    ..add(UsersStarted(currentUserId: currentUserId)),
              child: const UserListPage(),
            );
          },
        );
      case AppRoutes.chat:
        final args = settings.arguments;
        final chatArgs = args is ChatPageArgs
            ? args
            : const ChatPageArgs(peerName: 'Chat');
        return MaterialPageRoute(
          builder: (context) {
            final authState = context.read<AuthBloc>().state;
            final currentUserId = authState is Authenticated
                ? authState.user.id
                : '';
            return BlocProvider(
              create: (_) => createChatBloc()
                ..add(
                  ChatStarted(
                    chatId: chatIdFor(currentUserId, chatArgs.peerId),
                    currentUserId: currentUserId,
                    peerId: chatArgs.peerId,
                  ),
                ),
              child: ChatPage(peerName: chatArgs.peerName),
            );
          },
        );
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
