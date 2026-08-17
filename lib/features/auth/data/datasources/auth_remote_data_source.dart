import 'package:chat_app/core/error/exceptions.dart';
import 'package:chat_app/features/auth/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> watchUser();

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  final FirebaseAuth firebaseAuth;

  static const _timeout = Duration(seconds: 15);

  @override
  Stream<UserModel?> watchUser() {
    return firebaseAuth.authStateChanges().map((user) {
      if (user == null) {
        return null;
      }
      return UserModel.fromFirebaseUser(user);
    });
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            _timeout,
            onTimeout: () {
              throw const NetworkException(
                'Request timed out. Please try again.',
              );
            },
          );
      final user = credential.user;
      if (user == null) {
        throw const AuthException();
      }
      return UserModel.fromFirebaseUser(user);
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (_) {
      throw const AuthException();
    }
  }

  @override
  Future<UserModel> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            _timeout,
            onTimeout: () {
              throw const NetworkException(
                'Request timed out. Please try again.',
              );
            },
          );
      final user = credential.user;
      if (user == null) {
        throw const AuthException();
      }
      await user.updateDisplayName(displayName).timeout(
        _timeout,
        onTimeout: () {
          throw const NetworkException('Request timed out. Please try again.');
        },
      );
      await user.reload();
      final refreshed = firebaseAuth.currentUser ?? user;
      return UserModel.fromFirebaseUser(refreshed);
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (_) {
      throw const AuthException();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut().timeout(
        _timeout,
        onTimeout: () {
          throw const NetworkException('Request timed out. Please try again.');
        },
      );
    } on NetworkException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (_) {
      throw const AuthException('Could not log out. Please try again.');
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
