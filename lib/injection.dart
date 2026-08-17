import 'package:chat_app/core/network/network_info.dart';
import 'package:chat_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_in.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_out.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_up.dart';
import 'package:chat_app/features/auth/domain/usecases/watch_auth.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/users/data/datasources/user_local_data_source.dart';
import 'package:chat_app/features/users/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/features/users/data/repositories/user_repository_impl.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';
import 'package:chat_app/features/users/domain/usecases/ensure_user_profile.dart';
import 'package:chat_app/features/users/domain/usecases/get_cached_users.dart';
import 'package:chat_app/features/users/domain/usecases/refresh_users.dart';
import 'package:chat_app/features/users/domain/usecases/watch_users.dart';
import 'package:chat_app/features/users/presentation/bloc/users_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> initDependencies() async {
  await Hive.initFlutter();
  await Hive.openBox(UserLocalDataSourceImpl.boxName);
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

AuthBloc createAuthBloc() {
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(
      firebaseAuth: FirebaseAuth.instance,
    ),
  );
  final userRepository = createUserRepository();
  return AuthBloc(
    signIn: SignIn(authRepository),
    signUp: SignUp(authRepository),
    signOut: SignOut(authRepository),
    watchAuth: WatchAuth(authRepository),
    ensureUserProfile: EnsureUserProfile(userRepository),
  )..add(const AuthStarted());
}

UsersBloc createUsersBloc() {
  final userRepository = createUserRepository();
  final networkInfo = NetworkInfoImpl(connectivity: Connectivity());
  return UsersBloc(
    watchUsers: WatchUsers(userRepository),
    refreshUsers: RefreshUsers(userRepository),
    getCachedUsers: GetCachedUsers(userRepository),
    networkInfo: networkInfo,
  );
}
