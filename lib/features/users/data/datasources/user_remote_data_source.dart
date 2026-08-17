import 'package:chat_app/core/constants/firestore_collections.dart';
import 'package:chat_app/core/error/exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class UserRemoteDataSource {
  Future<void> ensureUser({
    required String uid,
    required String email,
    required String displayName,
  });
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl({required this.firestore});

  final FirebaseFirestore firestore;

  static const _timeout = Duration(seconds: 15);

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
      await _users
          .doc(uid)
          .set({
            'uid': uid,
            'email': email,
            'displayName': displayName,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(
            _timeout,
            onTimeout: () {
              throw const NetworkException(
                'Request timed out. Please try again.',
              );
            },
          );
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const NetworkException();
      }
      throw ServerException(_mapError(e.code, e.message));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  String _mapError(String code, String? message) {
    switch (code) {
      case 'permission-denied':
        return 'Could not save your profile. Check Firestore rules.';
      case 'not-found':
        return 'Firestore database not found. Use the (default) database.';
      default:
        return message == null || message.isEmpty
            ? 'Could not save your profile ($code).'
            : 'Could not save your profile ($code): $message';
    }
  }
}
