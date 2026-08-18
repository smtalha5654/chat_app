import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:chat_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/features/chat/data/models/chat_preview_model.dart';
import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;

  @override
  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return remoteDataSource.watchMessages(chatId).map((models) {
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Stream<List<ChatPreviewEntity>> watchChatPreviews(String userId) {
    return remoteDataSource.watchChatPreviews(userId).asyncMap((models) async {
      await _cacheQuietly(userId, models);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<ChatPreviewEntity>>> refreshChatPreviews(
    String userId,
  ) async {
    try {
      final models = await remoteDataSource.fetchChatPreviews(userId);
      await _cacheQuietly(userId, models);
      return Right(models.map((model) => model.toEntity()).toList());
    } catch (error) {
      return Left(
        failureFromException(error) ??
            const ServerFailure('Could not load chats.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<ChatPreviewEntity>>> getCachedChatPreviews(
    String userId,
  ) async {
    try {
      final models = localDataSource.getCachedPreviews(userId);
      return Right(models.map((model) => model.toEntity()).toList());
    } catch (error) {
      return Left(failureFromException(error) ?? const CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) {
    return _run(
      () => remoteDataSource.sendMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
      ),
      'Could not send message.',
    );
  }

  @override
  Future<Either<Failure, void>> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) {
    return _run(
      () => remoteDataSource.editMessage(
        chatId: chatId,
        messageId: messageId,
        text: text,
      ),
      'Could not edit message.',
    );
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String chatId,
    required String messageId,
  }) {
    return _run(
      () => remoteDataSource.deleteMessage(
        chatId: chatId,
        messageId: messageId,
      ),
      'Could not delete message.',
    );
  }

  Future<Either<Failure, void>> _run(
    Future<void> Function() action,
    String fallback,
  ) async {
    try {
      await action();
      return const Right(null);
    } catch (error) {
      return Left(failureFromException(error) ?? ServerFailure(fallback));
    }
  }

  Future<void> _cacheQuietly(
    String userId,
    List<ChatPreviewModel> models,
  ) async {
    try {
      await localDataSource.cachePreviews(userId, models);
    } catch (_) {
      return;
    }
  }
}
