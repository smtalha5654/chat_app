import 'package:chat_app/core/router/app_routes.dart';
import 'package:chat_app/features/auth/presentation/pages/login_page.dart';
import 'package:chat_app/features/auth/presentation/pages/register_page.dart';
import 'package:chat_app/features/chat/presentation/pages/chat_page.dart';
import 'package:chat_app/features/chat/presentation/pages/chat_page_args.dart';
import 'package:chat_app/features/profile/presentation/pages/profile_page.dart';
import 'package:chat_app/features/users/presentation/pages/user_list_page.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case AppRoutes.users:
        return MaterialPageRoute(builder: (_) => const UserListPage());
      case AppRoutes.chat:
        final args = settings.arguments;
        final peerName = args is ChatPageArgs ? args.peerName : 'Chat';
        return MaterialPageRoute(builder: (_) => ChatPage(peerName: peerName));
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
