import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:equatable/equatable.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileIdle extends ProfileState {
  const ProfileIdle();
}

class ProfileSaving extends ProfileState {
  const ProfileSaving();
}

class ProfileSuccess extends ProfileState {
  const ProfileSuccess(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message, {this.user});

  final String message;
  final UserEntity? user;

  @override
  List<Object?> get props => [message, user];
}
