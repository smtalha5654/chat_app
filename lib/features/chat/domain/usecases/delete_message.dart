import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class DeleteMessage implements UseCase<void, DeleteMessageParams> {
  DeleteMessage(this.repository);

  final ChatRepository repository;

  @override
  Future<Either<Failure, void>> call(DeleteMessageParams params) {
    return repository.deleteMessage(
      chatId: params.chatId,
      messageId: params.messageId,
    );
  }
}

class DeleteMessageParams extends Equatable {
  const DeleteMessageParams({
    required this.chatId,
    required this.messageId,
  });

  final String chatId;
  final String messageId;

  @override
  List<Object?> get props => [chatId, messageId];
}
