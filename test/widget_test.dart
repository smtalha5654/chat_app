import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_in.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_out.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_up.dart';
import 'package:chat_app/features/auth/domain/usecases/watch_auth.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/main.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login screen on launch', (WidgetTester tester) async {
    final repository = _FakeAuthRepository();
    final authBloc = AuthBloc(
      signIn: SignIn(repository),
      signUp: SignUp(repository),
      signOut: SignOut(repository),
      watchAuth: WatchAuth(repository),
    )..add(const AuthStarted());

    await tester.pumpWidget(ChatApp(authBloc: authBloc));
    await tester.pump();

    expect(find.text('Chat App'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<UserEntity?> authStateChanges() {
    return Stream<UserEntity?>.value(null);
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    return const Left(AuthFailure());
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    return const Left(AuthFailure());
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return const Right(null);
  }
}
