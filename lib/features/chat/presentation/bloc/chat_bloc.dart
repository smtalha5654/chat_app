import 'dart:async';

import 'package:chat_app/core/constants/app_timeouts.dart';
import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/network/network_info.dart';
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
    required NetworkInfo networkInfo,
  }) : _watchMessages = watchMessages,
       _sendMessage = sendMessage,
       _editMessage = editMessage,
       _deleteMessage = deleteMessage,
       _networkInfo = networkInfo,
       super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessageEdited>(_onMessageEdited);
    on<ChatMessageDeleted>(_onMessageDeleted);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
    on<ChatWatchFailed>(_onWatchFailed);
    on<ChatFirstSnapshotTimedOut>(_onFirstSnapshotTimedOut);
    on<ChatConnectionChanged>(_onConnectionChanged);
    on<ChatRetried>(_onRetried);
  }

  final WatchMessages _watchMessages;
  final SendMessage _sendMessage;
  final EditMessage _editMessage;
  final DeleteMessage _deleteMessage;
  final NetworkInfo _networkInfo;

  String _chatId = '';
  String _currentUserId = '';
  String _peerId = '';
  bool _isOffline = false;
  StreamSubscription<List<MessageEntity>>? _messagesSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _firstSnapshotTimer;

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    _chatId = event.chatId;
    _currentUserId = event.currentUserId;
    _peerId = event.peerId;
    _isOffline = !await _networkInfo.isConnected;
    emit(const ChatLoading());
    await _listenToMessages();
    await _listenToConnectivity();
    _armFirstSnapshotTimer();
  }

  Future<void> _onRetried(ChatRetried event, Emitter<ChatState> emit) async {
    _isOffline = !await _networkInfo.isConnected;
    emit(const ChatLoading());
    await _listenToMessages();
    _armFirstSnapshotTimer();
  }

  Future<void> _listenToMessages() async {
    await _messagesSubscription?.cancel();
    _messagesSubscription = _watchMessages(_chatId).listen(
      (messages) => add(ChatMessagesUpdated(messages)),
      onError: (_) => add(
        ChatWatchFailed(
          _isOffline
              ? 'No internet connection.'
              : 'Could not load messages. Please try again.',
        ),
      ),
    );
  }

  Future<void> _listenToConnectivity() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen((
      connected,
    ) {
      add(ChatConnectionChanged(connected));
    });
  }

  void _armFirstSnapshotTimer() {
    _firstSnapshotTimer?.cancel();
    _firstSnapshotTimer = Timer(AppTimeouts.firstSnapshot, () {
      add(const ChatFirstSnapshotTimedOut());
    });
  }

  void _cancelFirstSnapshotTimer() {
    _firstSnapshotTimer?.cancel();
    _firstSnapshotTimer = null;
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

  Future<bool> _ensureOnline(Emitter<ChatState> emit) async {
    final online = await _networkInfo.isConnected;
    _isOffline = !online;
    if (online) {
      return true;
    }
    final current = state;
    if (current is ChatLoaded) {
      emit(
        current.copyWith(
          isSending: false,
          isOffline: true,
          sendError: 'No internet connection.',
        ),
      );
    }
    return false;
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || _chatId.isEmpty) {
      return;
    }
    if (!await _ensureOnline(emit)) {
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
    if (event.text.trim().isEmpty || !_isOwnMessage(event.messageId)) {
      return;
    }
    if (!await _ensureOnline(emit)) {
      return;
    }
    final result = await _editMessage(
      EditMessageParams(
        chatId: _chatId,
        messageId: event.messageId,
        text: event.text.trim(),
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
    if (!await _ensureOnline(emit)) {
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
    _cancelFirstSnapshotTimer();
    final isSending = state is ChatLoaded && (state as ChatLoaded).isSending;
    emit(
      ChatLoaded(
        messages: event.messages,
        currentUserId: _currentUserId,
        isSending: isSending,
        isOffline: _isOffline,
      ),
    );
  }

  void _onWatchFailed(ChatWatchFailed event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      return;
    }
    _cancelFirstSnapshotTimer();
    emit(ChatFailure(event.message));
  }

  Future<void> _onFirstSnapshotTimedOut(
    ChatFirstSnapshotTimedOut event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoading) {
      return;
    }
    _isOffline = !await _networkInfo.isConnected;
    emit(
      ChatFailure(
        _isOffline
            ? 'No internet connection.'
            : 'Request timed out. Please try again.',
      ),
    );
  }

  void _onConnectionChanged(
    ChatConnectionChanged event,
    Emitter<ChatState> emit,
  ) {
    _isOffline = !event.isConnected;
    if (event.isConnected) {
      if (state is ChatFailure) {
        add(const ChatRetried());
      } else if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isOffline: false));
      }
      return;
    }
    final current = state;
    if (current is ChatLoaded) {
      emit(current.copyWith(isOffline: true));
    }
  }

  @override
  Future<void> close() {
    _cancelFirstSnapshotTimer();
    _messagesSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
