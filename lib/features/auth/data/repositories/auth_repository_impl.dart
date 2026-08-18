import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_app/features/auth/data/models/user_model.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remoteDataSource});

  final AuthRemoteDataSource remoteDataSource;

  @override
  Stream<UserEntity?> authStateChanges() {
    return remoteDataSource.watchUser().map((model) => model?.toEntity());
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) {
    return _guard(
      () => remoteDataSource.signIn(email: email, password: password),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String displayName,
    required String email,
    required String password,
  }) {
    return _guard(
      () => remoteDataSource.signUp(
        displayName: displayName,
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> updateDisplayName(String displayName) {
    return _guard(() => remoteDataSource.updateDisplayName(displayName));
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (error) {
      return Left(
        failureFromException(error) ??
            const AuthFailure('Could not log out. Please try again.'),
      );
    }
  }

  Future<Either<Failure, UserEntity>> _guard(
    Future<UserModel> Function() request,
  ) async {
    try {
      final model = await request();
      return Right(model.toEntity());
    } catch (error) {
      return Left(failureFromException(error) ?? const AuthFailure());
    }
  }
}
