import 'package:chat_app/core/widgets/app_button.dart';
import 'package:chat_app/core/widgets/app_snack_bar.dart';
import 'package:chat_app/core/widgets/chat_app_bar.dart';
import 'package:chat_app/core/widgets/empty_view.dart';
import 'package:chat_app/core/widgets/loading_view.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:chat_app/features/chat/presentation/bloc/chat_state.dart';
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load messages',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Retry',
                      onPressed: () {
                        context.read<ChatBloc>().add(const ChatRetried());
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ChatLoaded) {
            return Column(
              children: [
                Expanded(child: _MessageList(state: state)),
                MessageInput(
                  controller: _messageController,
                  isSending: state.isSending,
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
  const _MessageList({required this.state});

  final ChatLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.messages.isEmpty) {
      return const EmptyView(
        message: 'No messages yet. Say hello.',
      );
    }

    final items = state.messages.reversed.toList();
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final message = items[index];
        return MessageBubble(
          message: message,
          isMine: message.senderId == state.currentUserId,
        );
      },
    );
  }
}
