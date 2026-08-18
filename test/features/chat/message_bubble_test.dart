import 'package:chat_app/core/theme/app_theme.dart';
import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:chat_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final message = MessageEntity(
    id: 'm1',
    senderId: 'me',
    receiverId: 'you',
    text: 'Hello there',
    timestamp: DateTime(2026, 1, 1, 14, 30),
  );

  testWidgets('aligns own messages to the right', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MessageBubble(message: message, isMine: true),
        ),
      ),
    );

    final align = tester.widget<Align>(find.byType(Align).first);
    expect(align.alignment, Alignment.centerRight);
    expect(find.text('Hello there'), findsOneWidget);
  });

  testWidgets('aligns received messages to the left', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MessageBubble(message: message, isMine: false),
        ),
      ),
    );

    final align = tester.widget<Align>(find.byType(Align).first);
    expect(align.alignment, Alignment.centerLeft);
  });

  testWidgets('shows an edited label when the message was changed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MessageBubble(
            message: MessageEntity(
              id: 'm1',
              senderId: 'me',
              receiverId: 'you',
              text: 'Hello there',
              timestamp: DateTime(2026, 1, 1, 14, 30),
              isEdited: true,
            ),
            isMine: true,
          ),
        ),
      ),
    );

    expect(find.textContaining('edited'), findsOneWidget);
  });
}
