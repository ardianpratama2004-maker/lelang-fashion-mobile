import '../../core/utils/date_parser.dart';
import 'chat_message.dart';

class ChatThread {
  const ChatThread({
    required this.id,
    required this.status,
    required this.productId,
    required this.productTitle,
    required this.unread,
    this.productImageUrl,
    this.productStatus,
    this.userName,
    this.userEmail,
    this.latestMessage,
    this.lastMessageAt,
    this.closedAt,
    this.createdAt,
  });

  final int id;
  final String status;
  final int? productId;
  final String productTitle;
  final String? productImageUrl;
  final String? productStatus;
  final String? userName;
  final String? userEmail;
  final ChatMessage? latestMessage;
  final DateTime? lastMessageAt;
  final bool unread;
  final DateTime? closedAt;
  final DateTime? createdAt;

  bool get isOpen => status == 'open';

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? const {};
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final latest = json['latest_message'];

    return ChatThread(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'open',
      productId: product['id'] as int?,
      productTitle: product['title'] as String? ?? 'Produk lelang',
      productImageUrl: product['image_url'] as String?,
      productStatus: product['status'] as String?,
      userName: user['name'] as String?,
      userEmail: user['email'] as String?,
      latestMessage: latest is Map<String, dynamic>
          ? ChatMessage.fromJson(latest)
          : null,
      lastMessageAt: parseDate(json['last_message_at']),
      unread: json['unread'] as bool? ?? false,
      closedAt: parseDate(json['closed_at']),
      createdAt: parseDate(json['created_at']),
    );
  }
}
