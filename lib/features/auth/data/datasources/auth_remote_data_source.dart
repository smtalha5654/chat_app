import 'package:chat_app/core/error/exceptions.dart';
import 'package:chat_app/core/network/with_timeout.dart';
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

  Future<UserModel> updateDisplayName(String displayName);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  final FirebaseAuth firebaseAuth;

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
      final credential = await withTimeout(
        firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException();
      }
      return UserModel.fromFirebaseUser(user);
    } on RequestTimeoutException {
      rethrow;
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
      final credential = await withTimeout(
        firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException();
      }
      await withTimeout(user.updateDisplayName(displayName));
      await withTimeout(user.reload());
      final refreshed = firebaseAuth.currentUser ?? user;
      return UserModel.fromFirebaseUser(refreshed);
    } on RequestTimeoutException {
      rethrow;
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
  Future<UserModel> updateDisplayName(String displayName) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('You are not signed in.');
      }
      await withTimeout(user.updateDisplayName(displayName));
      await withTimeout(user.reload());
      final refreshed = firebaseAuth.currentUser ?? user;
      return UserModel.fromFirebaseUser(refreshed);
    } on RequestTimeoutException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (_) {
      throw const AuthException('Could not update your name. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await withTimeout(firebaseAuth.signOut());
    } on RequestTimeoutException {
      rethrow;
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
