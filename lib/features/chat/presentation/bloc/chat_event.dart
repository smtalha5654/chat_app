import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:equatable/equatable.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  const ChatStarted({
    required this.chatId,
    required this.currentUserId,
    required this.peerId,
  });

  final String chatId;
  final String currentUserId;
  final String peerId;

  @override
  List<Object?> get props => [chatId, currentUserId, peerId];
}

class ChatMessageSent extends ChatEvent {
  const ChatMessageSent(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

class ChatMessagesUpdated extends ChatEvent {
  const ChatMessagesUpdated(this.messages);

  final List<MessageEntity> messages;

  @override
  List<Object?> get props => [messages];
}

class ChatWatchFailed extends ChatEvent {
  const ChatWatchFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ChatRetried extends ChatEvent {
  const ChatRetried();
}
