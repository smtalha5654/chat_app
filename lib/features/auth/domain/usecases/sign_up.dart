import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class SignUp implements UseCase<UserEntity, SignUpParams> {
  SignUp(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) {
    return repository.signUp(
      displayName: params.displayName,
      email: params.email,
      password: params.password,
    );
  }
}

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.displayName,
    required this.email,
    required this.password,
  });

  final String displayName;
  final String email;
  final String password;

  @override
  List<Object?> get props => [displayName, email, password];
}
