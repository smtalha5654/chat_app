import 'package:chat_app/features/chat/domain/entities/message_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isEdited = false,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isEdited;

  factory MessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawTimestamp = data['timestamp'];
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: rawTimestamp is Timestamp
          ? rawTimestamp.toDate()
          : DateTime.now(),
      isEdited: data['isEdited'] as bool? ?? false,
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: timestamp,
      isEdited: isEdited,
    );
  }
}
