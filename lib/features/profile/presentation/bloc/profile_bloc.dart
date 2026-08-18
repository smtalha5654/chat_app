import 'package:chat_app/core/network/network_info.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/auth/domain/usecases/update_auth_display_name.dart';
import 'package:chat_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:chat_app/features/profile/presentation/bloc/profile_state.dart';
import 'package:chat_app/features/users/domain/usecases/update_user_display_name.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required UpdateAuthDisplayName updateAuthDisplayName,
    required UpdateUserDisplayName updateUserDisplayName,
    required NetworkInfo networkInfo,
  }) : _updateAuthDisplayName = updateAuthDisplayName,
       _updateUserDisplayName = updateUserDisplayName,
       _networkInfo = networkInfo,
       super(const ProfileIdle()) {
    on<ProfileSaveRequested>(_onSaveRequested);
  }

  final UpdateAuthDisplayName _updateAuthDisplayName;
  final UpdateUserDisplayName _updateUserDisplayName;
  final NetworkInfo _networkInfo;

  Future<void> _onSaveRequested(
    ProfileSaveRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final name = event.displayName.trim();
    if (name.isEmpty) {
      return;
    }
    emit(const ProfileSaving());
    if (!await _networkInfo.isConnected) {
      emit(const ProfileFailure('No internet connection.'));
      return;
    }

    final authResult = await _updateAuthDisplayName(name);
    UserEntity? updatedUser;
    final authError = authResult.fold((failure) => failure.message, (user) {
      updatedUser = user;
      return null;
    });
    final user = updatedUser;
    if (authError != null || user == null) {
      emit(ProfileFailure(authError ?? 'Could not update your name.'));
      return;
    }

    final storeResult = await _updateUserDisplayName(
      UpdateUserDisplayNameParams(uid: event.uid, displayName: name),
    );
    storeResult.fold(
      (failure) => emit(ProfileFailure(failure.message, user: user)),
      (_) => emit(ProfileSuccess(user)),
    );
  }
}
