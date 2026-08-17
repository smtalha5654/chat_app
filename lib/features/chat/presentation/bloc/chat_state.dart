import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:equatable/equatable.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatFailure extends ChatState {
  const ChatFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ChatLoaded extends ChatState {
  const ChatLoaded({
    required this.messages,
    required this.currentUserId,
    this.isSending = false,
    this.sendError,
  });

  final List<MessageEntity> messages;
  final String currentUserId;
  final bool isSending;
  final String? sendError;

  ChatLoaded copyWith({
    List<MessageEntity>? messages,
    String? currentUserId,
    bool? isSending,
    String? sendError,
    bool clearSendError = false,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentUserId: currentUserId ?? this.currentUserId,
      isSending: isSending ?? this.isSending,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
    );
  }

  @override
  List<Object?> get props => [messages, currentUserId, isSending, sendError];
}
