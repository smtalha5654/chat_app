import 'package:chat_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatApp());

    expect(find.text('Chat App'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
