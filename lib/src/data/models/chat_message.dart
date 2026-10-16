import '../../core/utils/date_parser.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    this.senderRole,
    this.senderName,
    this.createdAt,
  });

  final int id;
  final int threadId;
  final int senderId;
  final String? senderRole;
  final String? senderName;
  final String body;
  final DateTime? createdAt;

  bool get fromAdmin => senderRole == 'admin';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      threadId: json['thread_id'] as int,
      senderId: json['sender_id'] as int,
      senderRole: json['sender_role'] as String?,
      senderName: json['sender_name'] as String?,
      body: json['body'] as String? ?? '',
      createdAt: parseDate(json['created_at']),
    );
  }
}
