import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';

class WatchAuth {
  WatchAuth(this.repository);

  final AuthRepository repository;

  Stream<UserEntity?> call() {
    return repository.authStateChanges();
  }
}
