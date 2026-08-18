import 'package:chat_app/core/router/app_routes.dart';
import 'package:chat_app/core/widgets/app_text_field.dart';
import 'package:chat_app/core/widgets/app_snack_bar.dart';
import 'package:chat_app/core/widgets/chat_app_bar.dart';
import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/core/widgets/empty_view.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/core/widgets/loading_view.dart';
import 'package:chat_app/core/widgets/no_internet_view.dart';
import 'package:chat_app/core/widgets/offline_banner.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/chat/presentation/pages/chat_page_args.dart';
import 'package:chat_app/features/users/presentation/bloc/users_bloc.dart';
import 'package:chat_app/features/users/presentation/bloc/users_event.dart';
import 'package:chat_app/features/users/presentation/bloc/users_state.dart';
import 'package:chat_app/features/users/presentation/widgets/user_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onLogout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        title: 'Chats',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _onLogout,
          ),
        ],
      ),
      body: BlocConsumer<UsersBloc, UsersState>(
        listenWhen: (previous, current) {
          return current is UsersLoaded &&
              current.refreshError != null &&
              (previous is! UsersLoaded ||
                  previous.refreshError != current.refreshError);
        },
        listener: (context, state) {
          if (state is UsersLoaded && state.refreshError != null) {
            showAppSnackBar(context, state.refreshError!);
          }
        },
        builder: (context, state) {
          if (state is UsersLoading || state is UsersInitial) {
            return const LoadingView();
          }
          if (state is UsersDisconnected) {
            return NoInternetView(
              onRetry: () {
                context.read<UsersBloc>().add(const UsersRefreshed());
              },
            );
          }
          if (state is UsersFailure) {
            return ErrorView(
              message: state.message,
              onRetry: () {
                context.read<UsersBloc>().add(const UsersRefreshed());
              },
            );
          }
          if (state is UsersLoaded) {
            return Column(
              children: [
                if (state.isOffline)
                  OfflineBanner(
                    message: 'You are offline. Showing saved users.',
                    onRetry: () {
                      context.read<UsersBloc>().add(const UsersRefreshed());
                    },
                  ),
                _SearchField(
                  controller: _searchController,
                  onChanged: (query) {
                    context.read<UsersBloc>().add(UsersSearchChanged(query));
                  },
                ),
                Expanded(child: _UsersBody(state: state)),
              ],
            );
          }
          return const LoadingView();
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(12);
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFECEEEE);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Theme(
        data: theme.copyWith(
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: fill,
            hintStyle: TextStyle(color: theme.hintColor, fontSize: 15),
            prefixIconColor: theme.hintColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
        child: AppTextField(
          controller: controller,
          hint: 'Search',
          prefixIcon: const Icon(Icons.search, size: 22),
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _UsersBody extends StatelessWidget {
  const _UsersBody({required this.state});

  final UsersLoaded state;

  @override
  Widget build(BuildContext context) {
    final users = state.filtered;
    if (users.isEmpty) {
      return EmptyView(
        icon: Icons.people_outline,
        message: state.searchQuery.trim().isEmpty
            ? 'No other users yet'
            : 'No users match your search',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<UsersBloc>();
        bloc.add(const UsersRefreshed());
        await bloc.stream.firstWhere((next) {
          if (next is UsersLoaded) {
            return !next.isRefreshing;
          }
          return next is UsersDisconnected || next is UsersFailure;
        });
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return UserTile(
            user: user,
            currentUserId: state.currentUserId,
            preview: state.previewFor(user.id),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.chat,
                arguments: ChatPageArgs(
                  peerName: user.displayName,
                  peerId: user.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
