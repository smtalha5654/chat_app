import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
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

class UsersLoaded extends UsersState {
  const UsersLoaded({
    required this.users,
    this.searchQuery = '',
    this.isOffline = false,
    this.isRefreshing = false,
  });

  final List<UserEntity> users;
  final String searchQuery;
  final bool isOffline;
  final bool isRefreshing;

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
    String? searchQuery,
    bool? isOffline,
    bool? isRefreshing,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [users, searchQuery, isOffline, isRefreshing];
}
