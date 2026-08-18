import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:dartz/dartz.dart';

abstract class UserRepository {
  Future<Either<Failure, void>> ensureUser(UserEntity user);

  Future<Either<Failure, void>> updateDisplayName({
    required String uid,
    required String displayName,
  });

  Stream<List<UserEntity>> watchUsers();

  Future<Either<Failure, List<UserEntity>>> refreshUsers();

  Future<Either<Failure, List<UserEntity>>> getCachedUsers();
}
