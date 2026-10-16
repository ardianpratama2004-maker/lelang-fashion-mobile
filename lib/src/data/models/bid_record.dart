import '../../core/utils/date_parser.dart';

class BidRecord {
  const BidRecord({
    required this.id,
    required this.amount,
    this.createdAt,
    this.userId,
    this.userName,
    this.productTitle,
  });

  final int id;
  final int amount;
  final int? userId;
  final DateTime? createdAt;
  final String? userName;
  final String? productTitle;

  factory BidRecord.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final product = json['auction_product'];
    return BidRecord(
      id: json['id'] as int,
      amount: json['amount'] as int,
      createdAt: parseDate(json['created_at']),
      userId: user is Map<String, dynamic> ? user['id'] as int? : null,
      userName: user is Map<String, dynamic> ? user['name'] as String? : null,
      productTitle: product is Map<String, dynamic>
          ? product['title'] as String?
          : null,
    );
  }
}
