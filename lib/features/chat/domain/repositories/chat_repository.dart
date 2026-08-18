import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ChatRepository {
  Stream<List<MessageEntity>> watchMessages(String chatId);

  Stream<List<ChatPreviewEntity>> watchChatPreviews(String userId);

  Future<Either<Failure, List<ChatPreviewEntity>>> refreshChatPreviews(
    String userId,
  );

  Future<Either<Failure, List<ChatPreviewEntity>>> getCachedChatPreviews(
    String userId,
  );

  Future<Either<Failure, void>> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  });

  Future<Either<Failure, void>> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  });

  Future<Either<Failure, void>> deleteMessage({
    required String chatId,
    required String messageId,
  });
}
