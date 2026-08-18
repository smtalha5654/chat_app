import 'package:chat_app/core/widgets/app_snack_bar.dart';
import 'package:chat_app/core/widgets/chat_app_bar.dart';
import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/core/widgets/empty_view.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/core/widgets/loading_view.dart';
import 'package:chat_app/core/widgets/offline_banner.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_state.dart';
import 'package:chat_app/features/chat/presentation/widgets/edit_message_dialog.dart';
import 'package:chat_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:chat_app/features/chat/presentation/widgets/message_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.peerName});

  final String peerName;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _messageController.text;
    if (text.trim().isEmpty) {
      return;
    }
    context.read<ChatBloc>().add(ChatMessageSent(text));
    _messageController.clear();
  }

  Future<void> _onMessageLongPress(MessageEntity message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == 'edit') {
      final edited = await showEditMessageDialog(
        context,
        initialText: message.text,
      );
      if (!mounted || edited == null || edited.isEmpty || edited == message.text) {
        return;
      }
      context.read<ChatBloc>().add(
        ChatMessageEdited(messageId: message.id, text: edited),
      );
      return;
    }
    if (action == 'delete') {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Delete message',
        message: 'This message will be removed for everyone.',
        confirmLabel: 'Delete',
        isDestructive: true,
      );
      if (!confirmed || !mounted) {
        return;
      }
      context.read<ChatBloc>().add(ChatMessageDeleted(message.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(title: widget.peerName),
      body: BlocConsumer<ChatBloc, ChatState>(
        listenWhen: (previous, current) {
          return current is ChatLoaded &&
              current.sendError != null &&
              (previous is! ChatLoaded ||
                  previous.sendError != current.sendError);
        },
        listener: (context, state) {
          if (state is ChatLoaded && state.sendError != null) {
            showAppSnackBar(context, state.sendError!);
          }
        },
        builder: (context, state) {
          if (state is ChatLoading || state is ChatInitial) {
            return const LoadingView();
          }
          if (state is ChatFailure) {
            return ErrorView(
              message: state.message,
              onRetry: () {
                context.read<ChatBloc>().add(const ChatRetried());
              },
            );
          }
          if (state is ChatLoaded) {
            return Column(
              children: [
                if (state.isOffline)
                  OfflineBanner(
                    message: 'You are offline. New messages cannot be sent.',
                    onRetry: () {
                      context.read<ChatBloc>().add(const ChatRetried());
                    },
                  ),
                Expanded(
                  child: _MessageList(
                    state: state,
                    onOwnMessageLongPress: _onMessageLongPress,
                  ),
                ),
                MessageInput(
                  controller: _messageController,
                  isSending: state.isSending,
                  enabled: !state.isOffline,
                  onSend: _onSend,
                ),
              ],
            );
          }
          return const LoadingView();
        },
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.state,
    required this.onOwnMessageLongPress,
  });

  final ChatLoaded state;
  final ValueChanged<MessageEntity> onOwnMessageLongPress;

  @override
  Widget build(BuildContext context) {
    if (state.messages.isEmpty) {
      return const EmptyView(message: 'No messages yet. Say hello.');
    }

    final items = state.messages.reversed.toList();
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final message = items[index];
        final isMine = message.senderId == state.currentUserId;
        return MessageBubble(
          message: message,
          isMine: isMine,
          onLongPress: isMine ? () => onOwnMessageLongPress(message) : null,
        );
      },
    );
  }
}
