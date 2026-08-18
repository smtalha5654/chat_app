import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';

class WatchMessages {
  WatchMessages(this.repository);

  final ChatRepository repository;

  Stream<List<MessageEntity>> call(String chatId) {
    return repository.watchMessages(chatId);
  }
}
