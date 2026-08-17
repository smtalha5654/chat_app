import 'package:chat_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_in.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_out.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_up.dart';
import 'package:chat_app/features/auth/domain/usecases/watch_auth.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initDependencies() async {}

AuthBloc createAuthBloc() {
  final repository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(
      firebaseAuth: FirebaseAuth.instance,
    ),
  );
  return AuthBloc(
    signIn: SignIn(repository),
    signUp: SignUp(repository),
    signOut: SignOut(repository),
    watchAuth: WatchAuth(repository),
  )..add(const AuthStarted());
}
