import 'package:equatable/equatable.dart';

class ChatPreviewEntity extends Equatable {
  const ChatPreviewEntity({
    required this.chatId,
    required this.peerId,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageTime,
  });

  final String chatId;
  final String peerId;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageTime;

  bool get hasPreview => lastMessage.trim().isNotEmpty;

  @override
  List<Object?> get props => [
    chatId,
    peerId,
    lastMessage,
    lastMessageSenderId,
    lastMessageTime,
  ];
}
