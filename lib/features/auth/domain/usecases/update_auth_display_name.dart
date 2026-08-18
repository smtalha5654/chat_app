import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateAuthDisplayName implements UseCase<UserEntity, String> {
  UpdateAuthDisplayName(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, UserEntity>> call(String params) {
    return repository.updateDisplayName(params);
  }
}
