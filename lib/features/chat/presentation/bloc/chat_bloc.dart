import 'dart:async';

import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:chat_app/features/chat/domain/usecases/delete_message.dart';
import 'package:chat_app/features/chat/domain/usecases/edit_message.dart';
import 'package:chat_app/features/chat/domain/usecases/send_message.dart';
import 'package:chat_app/features/chat/domain/usecases/watch_messages.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required WatchMessages watchMessages,
    required SendMessage sendMessage,
    required EditMessage editMessage,
    required DeleteMessage deleteMessage,
  }) : _watchMessages = watchMessages,
       _sendMessage = sendMessage,
       _editMessage = editMessage,
       _deleteMessage = deleteMessage,
       super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessageEdited>(_onMessageEdited);
    on<ChatMessageDeleted>(_onMessageDeleted);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
    on<ChatWatchFailed>(_onWatchFailed);
    on<ChatRetried>(_onRetried);
  }

  final WatchMessages _watchMessages;
  final SendMessage _sendMessage;
  final EditMessage _editMessage;
  final DeleteMessage _deleteMessage;

  String _chatId = '';
  String _currentUserId = '';
  String _peerId = '';
  StreamSubscription<List<MessageEntity>>? _messagesSubscription;

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    _chatId = event.chatId;
    _currentUserId = event.currentUserId;
    _peerId = event.peerId;
    emit(const ChatLoading());
    await _listenToMessages();
  }

  Future<void> _onRetried(ChatRetried event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    await _listenToMessages();
  }

  Future<void> _listenToMessages() async {
    await _messagesSubscription?.cancel();
    _messagesSubscription = _watchMessages(_chatId).listen(
      (messages) => add(ChatMessagesUpdated(messages)),
      onError: (error) => add(ChatWatchFailed(error.toString())),
    );
  }

  bool _isOwnMessage(String messageId) {
    final current = state;
    if (current is! ChatLoaded) {
      return false;
    }
    return current.messages.any(
      (message) =>
          message.id == messageId && message.senderId == _currentUserId,
    );
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || _chatId.isEmpty) {
      return;
    }
    final current = state;
    if (current is ChatLoaded) {
      emit(current.copyWith(isSending: true, clearSendError: true));
    }
    final result = await _sendMessage(
      SendMessageParams(
        chatId: _chatId,
        senderId: _currentUserId,
        receiverId: _peerId,
        text: text,
      ),
    );
    _emitActionResult(emit, result);
  }

  Future<void> _onMessageEdited(
    ChatMessageEdited event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || !_isOwnMessage(event.messageId)) {
      return;
    }
    final result = await _editMessage(
      EditMessageParams(
        chatId: _chatId,
        messageId: event.messageId,
        text: text,
      ),
    );
    _emitActionResult(emit, result);
  }

  Future<void> _onMessageDeleted(
    ChatMessageDeleted event,
    Emitter<ChatState> emit,
  ) async {
    if (!_isOwnMessage(event.messageId)) {
      return;
    }
    final result = await _deleteMessage(
      DeleteMessageParams(chatId: _chatId, messageId: event.messageId),
    );
    _emitActionResult(emit, result);
  }

  void _emitActionResult(
    Emitter<ChatState> emit,
    Either<Failure, void> result,
  ) {
    result.fold(
      (failure) {
        final loaded = state;
        if (loaded is ChatLoaded) {
          emit(loaded.copyWith(isSending: false, sendError: failure.message));
        }
      },
      (_) {
        final loaded = state;
        if (loaded is ChatLoaded) {
          emit(loaded.copyWith(isSending: false, clearSendError: true));
        }
      },
    );
  }

  void _onMessagesUpdated(ChatMessagesUpdated event, Emitter<ChatState> emit) {
    final isSending = state is ChatLoaded && (state as ChatLoaded).isSending;
    emit(
      ChatLoaded(
        messages: event.messages,
        currentUserId: _currentUserId,
        isSending: isSending,
      ),
    );
  }

  void _onWatchFailed(ChatWatchFailed event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      return;
    }
    emit(ChatFailure(event.message));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
