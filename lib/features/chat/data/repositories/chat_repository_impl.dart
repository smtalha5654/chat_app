import 'package:chat_app/core/error/exceptions.dart';
import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required this.remoteDataSource});

  final ChatRemoteDataSource remoteDataSource;

  @override
  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return remoteDataSource.watchMessages(chatId).map((models) {
      return models.map((model) => model.toEntity()).toList();
    });
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
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(fallback));
    }
  }
}
