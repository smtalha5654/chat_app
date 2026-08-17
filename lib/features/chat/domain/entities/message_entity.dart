import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  const MessageEntity({
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

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    text,
    timestamp,
    isEdited,
  ];
}
