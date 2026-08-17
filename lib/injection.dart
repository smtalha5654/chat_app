import 'package:chat_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_in.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_out.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_up.dart';
import 'package:chat_app/features/auth/domain/usecases/watch_auth.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/users/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/features/users/data/repositories/user_repository_impl.dart';
import 'package:chat_app/features/users/domain/usecases/ensure_user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initDependencies() async {}

AuthBloc createAuthBloc() {
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(
      firebaseAuth: FirebaseAuth.instance,
    ),
  );
  final userRepository = UserRepositoryImpl(
    remoteDataSource: UserRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    ),
  );
  return AuthBloc(
    signIn: SignIn(authRepository),
    signUp: SignUp(authRepository),
    signOut: SignOut(authRepository),
    watchAuth: WatchAuth(authRepository),
    ensureUserProfile: EnsureUserProfile(userRepository),
  )..add(const AuthStarted());
}
