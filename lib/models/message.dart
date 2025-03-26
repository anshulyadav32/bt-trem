import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isCommand;
  final MessageStatus status;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isCommand = false,
    this.status = MessageStatus.sent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isCommand: json['isCommand'] as bool? ?? false,
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isCommand': isCommand,
      'status': status.toString(),
    };
  }
}

enum MessageStatus {
  sent,
  delivered,
  read,
  failed
}
