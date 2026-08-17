import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class EditMessage implements UseCase<void, EditMessageParams> {
  EditMessage(this.repository);

  final ChatRepository repository;

  @override
  Future<Either<Failure, void>> call(EditMessageParams params) {
    return repository.editMessage(
      chatId: params.chatId,
      messageId: params.messageId,
      text: params.text,
    );
  }
}

class EditMessageParams extends Equatable {
  const EditMessageParams({
    required this.chatId,
    required this.messageId,
    required this.text,
  });

  final String chatId;
  final String messageId;
  final String text;

  @override
  List<Object?> get props => [chatId, messageId, text];
}
