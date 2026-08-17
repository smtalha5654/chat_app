import 'package:chat_app/core/router/app_router.dart';
import 'package:chat_app/core/router/app_routes.dart';
import 'package:chat_app/core/theme/app_theme.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key, this.authBloc});

  final AuthBloc? authBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => authBloc ?? createAuthBloc(),
      child: const _AuthScope(),
    );
  }
}

class _AuthScope extends StatelessWidget {
  const _AuthScope();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        if (current is AuthLoading) {
          return false;
        }
        return _sessionKey(previous) != _sessionKey(current);
      },
      builder: (context, state) {
        return MaterialApp(
          key: ValueKey(_sessionKey(state)),
          title: 'Chat App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          initialRoute: _initialRoute(state),
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }

  String _sessionKey(AuthState state) {
    if (state is AuthInitial) {
      return 'boot';
    }
    if (state is Authenticated) {
      return 'in';
    }
    return 'out';
  }

  String _initialRoute(AuthState state) {
    if (state is AuthInitial) {
      return AppRoutes.bootstrap;
    }
    if (state is Authenticated) {
      return AppRoutes.users;
    }
    return AppRoutes.login;
  }
}
