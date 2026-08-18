import 'package:chat_app/core/network/network_info.dart';
import 'package:chat_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_in.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_out.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_up.dart';
import 'package:chat_app/features/auth/domain/usecases/update_auth_display_name.dart';
import 'package:chat_app/features/auth/domain/usecases/watch_auth.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:chat_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/features/chat/domain/usecases/delete_message.dart';
import 'package:chat_app/features/chat/domain/usecases/edit_message.dart';
import 'package:chat_app/features/chat/domain/usecases/get_cached_chat_previews.dart';
import 'package:chat_app/features/chat/domain/usecases/refresh_chat_previews.dart';
import 'package:chat_app/features/chat/domain/usecases/send_message.dart';
import 'package:chat_app/features/chat/domain/usecases/watch_chat_previews.dart';
import 'package:chat_app/features/chat/domain/usecases/watch_messages.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:chat_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chat_app/features/users/data/datasources/user_local_data_source.dart';
import 'package:chat_app/features/users/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/features/users/data/repositories/user_repository_impl.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';
import 'package:chat_app/features/users/domain/usecases/ensure_user_profile.dart';
import 'package:chat_app/features/users/domain/usecases/get_cached_users.dart';
import 'package:chat_app/features/users/domain/usecases/refresh_users.dart';
import 'package:chat_app/features/users/domain/usecases/update_user_display_name.dart';
import 'package:chat_app/features/users/domain/usecases/watch_users.dart';
import 'package:chat_app/features/users/presentation/bloc/users_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> initDependencies() async {
  await Hive.initFlutter();
  await Hive.openBox(UserLocalDataSourceImpl.boxName);
  await Hive.openBox(ChatLocalDataSourceImpl.boxName);
}

UserRepository createUserRepository() {
  return UserRepositoryImpl(
    remoteDataSource: UserRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    ),
    localDataSource: UserLocalDataSourceImpl(
      box: Hive.box(UserLocalDataSourceImpl.boxName),
    ),
  );
}

AuthRepository createAuthRepository() {
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(
      firebaseAuth: FirebaseAuth.instance,
    ),
  );
}

AuthBloc createAuthBloc() {
  final authRepository = createAuthRepository();
  final userRepository = createUserRepository();
  return AuthBloc(
    signIn: SignIn(authRepository),
    signUp: SignUp(authRepository),
    signOut: SignOut(authRepository),
    watchAuth: WatchAuth(authRepository),
    ensureUserProfile: EnsureUserProfile(userRepository),
  )..add(const AuthStarted());
}

ChatRepository createChatRepository() {
  return ChatRepositoryImpl(
    remoteDataSource: ChatRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    ),
    localDataSource: ChatLocalDataSourceImpl(
      box: Hive.box(ChatLocalDataSourceImpl.boxName),
    ),
  );
}

UsersBloc createUsersBloc() {
  final userRepository = createUserRepository();
  final chatRepository = createChatRepository();
  final networkInfo = NetworkInfoImpl(connectivity: Connectivity());
  return UsersBloc(
    watchUsers: WatchUsers(userRepository),
    refreshUsers: RefreshUsers(userRepository),
    getCachedUsers: GetCachedUsers(userRepository),
    watchChatPreviews: WatchChatPreviews(chatRepository),
    refreshChatPreviews: RefreshChatPreviews(chatRepository),
    getCachedChatPreviews: GetCachedChatPreviews(chatRepository),
    networkInfo: networkInfo,
  );
}

ChatBloc createChatBloc() {
  final repository = createChatRepository();
  return ChatBloc(
    watchMessages: WatchMessages(repository),
    sendMessage: SendMessage(repository),
    editMessage: EditMessage(repository),
    deleteMessage: DeleteMessage(repository),
  );
}

ProfileBloc createProfileBloc() {
  return ProfileBloc(
    updateAuthDisplayName: UpdateAuthDisplayName(createAuthRepository()),
    updateUserDisplayName: UpdateUserDisplayName(createUserRepository()),
  );
}
