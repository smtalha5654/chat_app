import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ChatRepository {
  Stream<List<MessageEntity>> watchMessages(String chatId);

  Future<Either<Failure, void>> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  });
}
