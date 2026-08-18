import 'dart:async';

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
import 'package:chat_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';
import 'package:chat_app/features/users/domain/usecases/ensure_user_profile.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAuthRepository authRepository;
  late _FakeUserRepository userRepository;
  late AuthBloc bloc;

  setUp(() async {
    authRepository = _FakeAuthRepository();
    userRepository = _FakeUserRepository();
    bloc = AuthBloc(
      signIn: SignIn(authRepository),
      signUp: SignUp(authRepository),
      signOut: SignOut(authRepository),
      watchAuth: WatchAuth(authRepository),
      ensureUserProfile: EnsureUserProfile(userRepository),
      clearLocalCache: ClearLocalCache(
        userRepository: userRepository,
        chatRepository: _FakeChatRepository(),
      ),
      networkInfo: _FakeNetworkInfo(),
    )..add(const AuthStarted());
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    await bloc.close();
    await authRepository.close();
  });

  test('signup persists the typed display name, not the email prefix', () async {
    const created = UserEntity(
      id: 'u2',
      email: 'test2@yopmail.com',
      displayName: 'Test User 2',
    );

    final done = expectLater(
      bloc.stream,
      emitsThrough(const Authenticated(created)),
    );
    bloc.add(
      const AuthRegisterRequested(
        displayName: 'Test User 2',
        email: 'test2@yopmail.com',
        password: 'password',
      ),
    );
    await done;

    expect(userRepository.ensured, [created]);
    expect(
      userRepository.ensured.every((user) => user.displayName == 'Test User 2'),
      isTrue,
    );
  });

  test('late auth snapshot without a name does not overwrite display name', () async {
    const created = UserEntity(
      id: 'u2',
      email: 'test2@yopmail.com',
      displayName: 'Test User 2',
    );

    bloc.add(
      const AuthRegisterRequested(
        displayName: 'Test User 2',
        email: 'test2@yopmail.com',
        password: 'password',
      ),
    );
    await bloc.stream.firstWhere((state) => state is Authenticated);

    authRepository.emitUser(
      const UserEntity(
        id: 'u2',
        email: 'test2@yopmail.com',
        displayName: '',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, const Authenticated(created));
    expect(
      userRepository.ensured.every((user) => user.displayName == 'Test User 2'),
      isTrue,
    );
  });
}

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<UserEntity?>.broadcast();

  void emitUser(UserEntity? user) {
    _controller.add(user);
  }

  Future<void> close() => _controller.close();

  @override
  Stream<UserEntity?> authStateChanges() => _controller.stream;

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
    // Mimic Firebase authStateChanges firing before displayName is set.
    emitUser(UserEntity(id: 'u2', email: email, displayName: ''));
    await Future<void>.delayed(Duration.zero);
    return Right(
      UserEntity(id: 'u2', email: email, displayName: displayName),
    );
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
  final ensured = <UserEntity>[];

  @override
  Future<Either<Failure, void>> ensureUser(UserEntity user) async {
    ensured.add(user);
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
  Stream<List<UserEntity>> watchUsers() => const Stream.empty();

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
