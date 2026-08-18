import 'package:chat_app/core/network/network_info.dart';
import 'package:chat_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:chat_app/features/auth/domain/usecases/clear_local_cache.dart';
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
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();
  final usersBox = await Hive.openBox(UserLocalDataSourceImpl.boxName);
  final previewsBox = await Hive.openBox(ChatLocalDataSourceImpl.boxName);

  sl
    ..registerLazySingleton(() => FirebaseAuth.instance)
    ..registerLazySingleton(() => FirebaseFirestore.instance)
    ..registerLazySingleton(Connectivity.new)
    ..registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(connectivity: sl()),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSourceImpl(firestore: sl()),
    )
    ..registerLazySingleton<UserLocalDataSource>(
      () => UserLocalDataSourceImpl(box: usersBox),
    )
    ..registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ),
    )
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(firestore: sl()),
    )
    ..registerLazySingleton<ChatLocalDataSource>(
      () => ChatLocalDataSourceImpl(box: previewsBox),
    )
    ..registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ),
    )
    ..registerLazySingleton(() => SignIn(sl()))
    ..registerLazySingleton(() => SignUp(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => WatchAuth(sl()))
    ..registerLazySingleton(() => UpdateAuthDisplayName(sl()))
    ..registerLazySingleton(() => EnsureUserProfile(sl()))
    ..registerLazySingleton(() => WatchUsers(sl()))
    ..registerLazySingleton(() => RefreshUsers(sl()))
    ..registerLazySingleton(() => GetCachedUsers(sl()))
    ..registerLazySingleton(() => UpdateUserDisplayName(sl()))
    ..registerLazySingleton(() => WatchMessages(sl()))
    ..registerLazySingleton(() => SendMessage(sl()))
    ..registerLazySingleton(() => EditMessage(sl()))
    ..registerLazySingleton(() => DeleteMessage(sl()))
    ..registerLazySingleton(() => WatchChatPreviews(sl()))
    ..registerLazySingleton(() => RefreshChatPreviews(sl()))
    ..registerLazySingleton(() => GetCachedChatPreviews(sl()))
    ..registerLazySingleton(
      () => ClearLocalCache(userRepository: sl(), chatRepository: sl()),
    )
    ..registerFactory(
      () => AuthBloc(
        signIn: sl(),
        signUp: sl(),
        signOut: sl(),
        watchAuth: sl(),
        ensureUserProfile: sl(),
        clearLocalCache: sl(),
        networkInfo: sl(),
      )..add(const AuthStarted()),
    )
    ..registerFactory(
      () => UsersBloc(
        watchUsers: sl(),
        refreshUsers: sl(),
        getCachedUsers: sl(),
        watchChatPreviews: sl(),
        refreshChatPreviews: sl(),
        getCachedChatPreviews: sl(),
        networkInfo: sl(),
      ),
    )
    ..registerFactory(
      () => ChatBloc(
        watchMessages: sl(),
        sendMessage: sl(),
        editMessage: sl(),
        deleteMessage: sl(),
        networkInfo: sl(),
      ),
    )
    ..registerFactory(
      () => ProfileBloc(
        updateAuthDisplayName: sl(),
        updateUserDisplayName: sl(),
        networkInfo: sl(),
      ),
    );
}

AuthBloc createAuthBloc() => sl<AuthBloc>();

UsersBloc createUsersBloc() => sl<UsersBloc>();

ChatBloc createChatBloc() => sl<ChatBloc>();

ProfileBloc createProfileBloc() => sl<ProfileBloc>();
