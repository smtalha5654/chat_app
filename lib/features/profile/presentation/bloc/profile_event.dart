import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileSaveRequested extends ProfileEvent {
  const ProfileSaveRequested({
    required this.uid,
    required this.displayName,
  });

  final String uid;
  final String displayName;

  @override
  List<Object?> get props => [uid, displayName];
}
