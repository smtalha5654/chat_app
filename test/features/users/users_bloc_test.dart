import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/network/network_info.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/features/chat/domain/usecases/get_cached_chat_previews.dart';
import 'package:chat_app/features/chat/domain/usecases/refresh_chat_previews.dart';
import 'package:chat_app/features/chat/domain/usecases/watch_chat_previews.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';
import 'package:chat_app/features/users/domain/usecases/get_cached_users.dart';
import 'package:chat_app/features/users/domain/usecases/refresh_users.dart';
import 'package:chat_app/features/users/domain/usecases/watch_users.dart';
import 'package:chat_app/features/users/presentation/bloc/users_bloc.dart';
import 'package:chat_app/features/users/presentation/bloc/users_event.dart';
import 'package:chat_app/features/users/presentation/bloc/users_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const me = UserEntity(id: 'me', email: 'me@app.com', displayName: 'Me');
  const ali = UserEntity(id: 'ali', email: 'ali@app.com', displayName: 'Ali');
  const bob = UserEntity(id: 'bob', email: 'bob@app.com', displayName: 'Bob');

  UsersBloc buildBloc(List<UserEntity> cached) {
    final users = _FakeUserRepository(cached: cached);
    final chats = _FakeChatRepository();
    return UsersBloc(
      watchUsers: WatchUsers(users),
      refreshUsers: RefreshUsers(users),
      getCachedUsers: GetCachedUsers(users),
      watchChatPreviews: WatchChatPreviews(chats),
      refreshChatPreviews: RefreshChatPreviews(chats),
      getCachedChatPreviews: GetCachedChatPreviews(chats),
      networkInfo: _FakeNetworkInfo(),
    );
  }

  test('hides the signed in user from the cached list', () async {
    final bloc = buildBloc([me, ali, bob]);
    addTearDown(bloc.close);

    final loaded = bloc.stream.firstWhere((state) => state is UsersLoaded);
    bloc.add(const UsersStarted(currentUserId: 'me'));
    final state = await loaded.timeout(const Duration(seconds: 2));

    expect(state, isA<UsersLoaded>());
    expect(
      (state as UsersLoaded).users.map((user) => user.id),
      ['ali', 'bob'],
    );
  });

  test('filters the list by display name', () async {
    final bloc = buildBloc([me, ali, bob]);
    addTearDown(bloc.close);

    final loaded = bloc.stream.firstWhere((state) => state is UsersLoaded);
    bloc.add(const UsersStarted(currentUserId: 'me'));
    await loaded.timeout(const Duration(seconds: 2));

    final searched = bloc.stream.firstWhere((state) {
      return state is UsersLoaded && state.searchQuery == 'ali';
    });
    bloc.add(const UsersSearchChanged('ali'));
    await searched.timeout(const Duration(seconds: 2));

    final filtered = (bloc.state as UsersLoaded).filtered;
    expect(filtered.map((user) => user.id), ['ali']);
  });
}

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({required this.cached});

  final List<UserEntity> cached;

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
  Stream<List<UserEntity>> watchUsers() => const Stream.empty();

  @override
  Future<Either<Failure, List<UserEntity>>> refreshUsers() async {
    return Right(cached);
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getCachedUsers() async {
    return Right(cached);
  }

  @override
  Future<Either<Failure, void>> clearCache() async => const Right(null);
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
  Future<Either<Failure, void>> clearCache() async => const Right(null);
}
