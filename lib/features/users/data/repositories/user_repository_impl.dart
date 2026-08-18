import 'package:chat_app/core/error/exceptions.dart';
import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/users/data/datasources/user_local_data_source.dart';
import 'package:chat_app/features/users/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/features/users/data/models/user_model.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  @override
  Future<Either<Failure, void>> ensureUser(UserEntity user) async {
    try {
      await remoteDataSource.ensureUser(
        uid: user.id,
        email: user.email,
        displayName: user.displayName,
      );
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure('Could not save your profile.'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    try {
      await remoteDataSource.updateDisplayName(
        uid: uid,
        displayName: displayName,
      );
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure('Could not update your profile.'));
    }
  }

  @override
  Stream<List<UserEntity>> watchUsers() {
    return remoteDataSource.watchUsers().asyncMap((models) async {
      await _cacheQuietly(models);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<UserEntity>>> refreshUsers() async {
    try {
      final models = await remoteDataSource.fetchUsers();
      await _cacheQuietly(models);
      return Right(models.map((model) => model.toEntity()).toList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure('Could not load users.'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getCachedUsers() async {
    try {
      final models = localDataSource.getCachedUsers();
      return Right(models.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  Future<void> _cacheQuietly(List<UserModel> models) async {
    try {
      await localDataSource.cacheUsers(models);
    } catch (_) {
      return;
    }
  }
}
