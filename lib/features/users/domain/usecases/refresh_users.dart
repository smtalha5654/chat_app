import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class RefreshUsers implements UseCase<List<UserEntity>, NoParams> {
  RefreshUsers(this.repository);

  final UserRepository repository;

  @override
  Future<Either<Failure, List<UserEntity>>> call(NoParams params) {
    return repository.refreshUsers();
  }
}
