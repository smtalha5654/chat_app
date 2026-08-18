import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/network/network_info.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:chat_app/features/auth/domain/usecases/clear_local_cache.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_in.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_out.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_up.dart';
import 'package:chat_app/features/auth/domain/usecases/watch_auth.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';
import 'package:chat_app/features/users/domain/usecases/ensure_user_profile.dart';
import 'package:chat_app/main.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login screen on launch', (WidgetTester tester) async {
    final authRepository = _FakeAuthRepository();
    final authBloc = AuthBloc(
      signIn: SignIn(authRepository),
      signUp: SignUp(authRepository),
      signOut: SignOut(authRepository),
      watchAuth: WatchAuth(authRepository),
      ensureUserProfile: EnsureUserProfile(_FakeUserRepository()),
      clearLocalCache: ClearLocalCache(
        userRepository: _FakeUserRepository(),
        chatRepository: _FakeChatRepository(),
      ),
      networkInfo: _FakeNetworkInfo(),
    )..add(const AuthStarted());

    await tester.pumpWidget(ChatApp(authBloc: authBloc));
    await tester.pump();

    expect(find.text('Chat App'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
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

  @override
  Future<Either<Failure, UserEntity>> updateDisplayName(
    String displayName,
  ) async {
    return const Left(AuthFailure());
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<Either<Failure, void>> ensureUser(UserEntity user) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    return const Right(null);
  }

  @override
  Stream<List<UserEntity>> watchUsers() {
    return const Stream.empty();
  }

  @override
  Future<Either<Failure, List<UserEntity>>> refreshUsers() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getCachedUsers() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    return const Right(null);
  }
}

class _FakeChatRepository implements ChatRepository {
  @override
  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return const Stream.empty();
  }

  @override
  Stream<List<ChatPreviewEntity>> watchChatPreviews(String userId) {
    return const Stream.empty();
  }

  @override
  Future<Either<Failure, List<ChatPreviewEntity>>> refreshChatPreviews(
    String userId,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<ChatPreviewEntity>>> getCachedChatPreviews(
    String userId,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    return const Right(null);
  }
}
