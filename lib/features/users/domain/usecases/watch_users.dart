import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';

class WatchUsers {
  WatchUsers(this.repository);

  final UserRepository repository;

  Stream<List<UserEntity>> call() {
    return repository.watchUsers();
  }
}
