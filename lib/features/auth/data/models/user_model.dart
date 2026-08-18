import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  factory UserModel.fromFirebaseUser(
    User user, {
    String? fallbackDisplayName,
  }) {
    final email = user.email ?? '';
    final name = user.displayName?.trim() ?? '';
    final fallback = fallbackDisplayName?.trim() ?? '';
    return UserModel(
      id: user.uid,
      email: email,
      displayName: name.isNotEmpty ? name : fallback,
    );
  }

  UserEntity toEntity() {
    return UserEntity(id: id, email: email, displayName: displayName);
  }
}
