import 'package:chat_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty values', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), 'Enter a valid email');
      expect(Validators.email('name@'), 'Enter a valid email');
    });

    test('accepts a normal address', () {
      expect(Validators.email('ada@example.com'), isNull);
    });
  });

  group('Validators.displayName', () {
    test('rejects empty and short names', () {
      expect(Validators.displayName(null), 'Name is required');
      expect(Validators.displayName(' '), 'Name is required');
      expect(Validators.displayName('A'), 'Name must be at least 2 characters');
    });

    test('accepts a two character name', () {
      expect(Validators.displayName('Al'), isNull);
    });
  });

  group('Validators.password', () {
    test('enforces a minimum length', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password('12345'), 'Password must be at least 6 characters');
      expect(Validators.password('123456'), isNull);
    });
  });
}
