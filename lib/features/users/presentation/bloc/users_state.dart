import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:equatable/equatable.dart';

sealed class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {
  const UsersInitial();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersDisconnected extends UsersState {
  const UsersDisconnected();
}

class UsersFailure extends UsersState {
  const UsersFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class UsersLoaded extends UsersState {
  const UsersLoaded({
    required this.users,
    required this.currentUserId,
    this.previews = const {},
    this.searchQuery = '',
    this.isOffline = false,
    this.isRefreshing = false,
    this.refreshError,
  });

  final List<UserEntity> users;
  final String currentUserId;
  final Map<String, ChatPreviewEntity> previews;
  final String searchQuery;
  final bool isOffline;
  final bool isRefreshing;
  final String? refreshError;

  ChatPreviewEntity? previewFor(String userId) => previews[userId];

  List<UserEntity> get filtered {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return users;
    }
    return users.where((user) {
      return user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  UsersLoaded copyWith({
    List<UserEntity>? users,
    String? currentUserId,
    Map<String, ChatPreviewEntity>? previews,
    String? searchQuery,
    bool? isOffline,
    bool? isRefreshing,
    String? refreshError,
    bool clearRefreshError = false,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      currentUserId: currentUserId ?? this.currentUserId,
      previews: previews ?? this.previews,
      searchQuery: searchQuery ?? this.searchQuery,
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: clearRefreshError
          ? null
          : (refreshError ?? this.refreshError),
    );
  }

  @override
  List<Object?> get props => [
    users,
    currentUserId,
    previews,
    searchQuery,
    isOffline,
    isRefreshing,
    refreshError,
  ];
}
