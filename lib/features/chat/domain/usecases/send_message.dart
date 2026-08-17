import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class SendMessage implements UseCase<void, SendMessageParams> {
  SendMessage(this.repository);

  final ChatRepository repository;

  @override
  Future<Either<Failure, void>> call(SendMessageParams params) {
    return repository.sendMessage(
      chatId: params.chatId,
      senderId: params.senderId,
      receiverId: params.receiverId,
      text: params.text,
    );
  }
}

class SendMessageParams extends Equatable {
  const SendMessageParams({
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
  });

  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;

  @override
  List<Object?> get props => [chatId, senderId, receiverId, text];
}
