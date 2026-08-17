import 'package:chat_app/core/constants/firestore_collections.dart';
import 'package:chat_app/core/error/exceptions.dart';
import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageModel>> watchMessages(String chatId);

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl({required this.firestore});

  final FirebaseFirestore firestore;

  static const _timeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _chats {
    return firestore.collection(FirestoreCollections.chats);
  }

  CollectionReference<Map<String, dynamic>> _messages(String chatId) {
    return _chats.doc(chatId).collection(FirestoreCollections.messages);
  }

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _messages(chatId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(MessageModel.fromFirestore).toList());
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final chatRef = _chats.doc(chatId);
      final messageRef = _messages(chatId).doc();
      final batch = firestore.batch();
      batch.set(messageRef, {
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isEdited': false,
      });
      batch.set(chatRef, {
        'participants': [senderId, receiverId],
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit().timeout(
        _timeout,
        onTimeout: () {
          throw const NetworkException('Request timed out. Please try again.');
        },
      );
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _fromFirebase(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Never _fromFirebase(FirebaseException e) {
    if (e.code == 'unavailable') {
      throw const NetworkException();
    }
    if (e.code == 'permission-denied') {
      throw const ServerException(
        'Could not send message. Check Firestore rules.',
      );
    }
    final message = e.message;
    if (message == null || message.isEmpty) {
      throw ServerException('Could not send message (${e.code}).');
    }
    throw ServerException('Could not send message (${e.code}): $message');
  }
}
