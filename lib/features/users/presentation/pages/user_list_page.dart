import 'package:chat_app/core/router/app_routes.dart';
import 'package:chat_app/core/widgets/app_text_field.dart';
import 'package:chat_app/core/widgets/chat_app_bar.dart';
import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/core/widgets/empty_view.dart';
import 'package:chat_app/core/widgets/loading_view.dart';
import 'package:chat_app/core/widgets/no_internet_view.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/chat/presentation/pages/chat_page_args.dart';
import 'package:chat_app/features/users/presentation/bloc/users_bloc.dart';
import 'package:chat_app/features/users/presentation/bloc/users_event.dart';
import 'package:chat_app/features/users/presentation/bloc/users_state.dart';
import 'package:chat_app/features/users/presentation/widgets/offline_banner.dart';
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
      body: BlocBuilder<UsersBloc, UsersState>(
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
          if (state is UsersLoaded) {
            return Column(
              children: [
                if (state.isOffline)
                  OfflineBanner(
                    onRetry: () {
                      context.read<UsersBloc>().add(const UsersRefreshed());
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: AppTextField(
                    controller: _searchController,
                    hint: 'Search users',
                    prefixIcon: const Icon(Icons.search),
                    textInputAction: TextInputAction.search,
                    onChanged: (query) {
                      context.read<UsersBloc>().add(UsersSearchChanged(query));
                    },
                  ),
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
          return next is UsersDisconnected;
        });
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          return UserTile(
            user: user,
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
