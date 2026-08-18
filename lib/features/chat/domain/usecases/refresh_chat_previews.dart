import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';

class RefreshChatPreviews {
  RefreshChatPreviews(this.repository);

  final ChatRepository repository;

  Future<Either<Failure, List<ChatPreviewEntity>>> call(String userId) {
    return repository.refreshChatPreviews(userId);
  }
}
