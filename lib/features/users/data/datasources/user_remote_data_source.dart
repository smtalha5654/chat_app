import 'package:chat_app/core/constants/firestore_collections.dart';
import 'package:chat_app/core/error/exceptions.dart';
import 'package:chat_app/core/network/with_timeout.dart';
import 'package:chat_app/features/users/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class UserRemoteDataSource {
  Future<void> ensureUser({
    required String uid,
    required String email,
    required String displayName,
  });

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  });

  Stream<List<UserModel>> watchUsers();

  Future<List<UserModel>> fetchUsers();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _users {
    return firestore.collection(FirestoreCollections.users);
  }

  @override
  Future<void> ensureUser({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      await withTimeout(
        _users.doc(uid).set({
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
    } on RequestTimeoutException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _fromFirebase(e, 'Could not save your profile');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    try {
      await withTimeout(
        _users.doc(uid).set({
          'displayName': displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
    } on RequestTimeoutException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _fromFirebase(e, 'Could not update your profile');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<UserModel>> watchUsers() {
    return _users.snapshots().map((snapshot) {
      return snapshot.docs.map(UserModel.fromFirestore).toList();
    });
  }

  @override
  Future<List<UserModel>> fetchUsers() async {
    try {
      final snapshot = await withTimeout(
        _users.get(const GetOptions(source: Source.server)),
      );
      return snapshot.docs.map(UserModel.fromFirestore).toList();
    } on RequestTimeoutException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _fromFirebase(e, 'Could not load users');
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(e.toString());
    }
  }

  Never _fromFirebase(FirebaseException e, String fallback) {
    if (e.code == 'unavailable') {
      throw const NetworkException();
    }
    if (e.code == 'permission-denied') {
      throw ServerException('$fallback. Check Firestore rules.');
    }
    if (e.code == 'not-found') {
      throw const ServerException(
        'Firestore database not found. Use the (default) database.',
      );
    }
    final message = e.message;
    if (message == null || message.isEmpty) {
      throw ServerException('$fallback (${e.code}).');
    }
    throw ServerException('$fallback (${e.code}): $message');
  }
}
