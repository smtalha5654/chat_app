import 'package:chat_app/core/utils/chat_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a stable chat id regardless of argument order', () {
    expect(chatIdFor('b', 'a'), 'a_b');
    expect(chatIdFor('a', 'b'), 'a_b');
  });
}
