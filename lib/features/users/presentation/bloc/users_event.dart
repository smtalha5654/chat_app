import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:equatable/equatable.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

class UsersStarted extends UsersEvent {
  const UsersStarted({required this.currentUserId});

  final String currentUserId;

  @override
  List<Object?> get props => [currentUserId];
}

class UsersRefreshed extends UsersEvent {
  const UsersRefreshed();
}

class UsersSearchChanged extends UsersEvent {
  const UsersSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class UsersUpdated extends UsersEvent {
  const UsersUpdated(this.users);

  final List<UserEntity> users;

  @override
  List<Object?> get props => [users];
}

class UsersWatchFailed extends UsersEvent {
  const UsersWatchFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class UsersConnectionChanged extends UsersEvent {
  const UsersConnectionChanged(this.isConnected);

  final bool isConnected;

  @override
  List<Object?> get props => [isConnected];
}
