import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';

class WatchChatPreviews {
  WatchChatPreviews(this.repository);

  final ChatRepository repository;

  Stream<List<ChatPreviewEntity>> call(String userId) {
    return repository.watchChatPreviews(userId);
  }
}
